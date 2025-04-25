/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "ObjFWRT.h"
#import "private.h"

static struct _objc_hashtable *classes = NULL;
static unsigned classesCount = 0;
static Class *loadQueue = NULL;
static size_t loadQueueCount = 0;
static struct _objc_dtable *emptyDTable = NULL;
static unsigned lookupsUntilFastPath = 128;
static struct _objc_sparsearray *fastPath = NULL;

static void
registerClass(Class class)
{
	if (classes == NULL)
		classes = _objc_hashtable_new(
		    _objc_string_hash, _objc_string_equal, 2);

	_objc_hashtable_set(classes, class->name, class);

	if (emptyDTable == NULL)
		emptyDTable = _objc_dtable_new();

	class->dTable = emptyDTable;
	class->isa->dTable = emptyDTable;

	if (strcmp(class->name, "Protocol") != 0)
		classesCount++;
}

void
class_registerAlias_np(Class class, const char *name)
{
	_objc_globalMutex_lock();

	if (classes != NULL)
		_objc_hashtable_set(classes, name,
		    (Class)((uintptr_t)class | 1));

	_objc_globalMutex_unlock();
}

static void
registerSelectors(Class class)
{
	struct _objc_method_list *iter;
	unsigned int i;

	for (iter = class->methodList; iter != NULL; iter = iter->next)
		for (i = 0; i < iter->count; i++)
			_objc_registerSelector(&iter->methods[i].selector);
}

Class
_objc_classnameToClass(const char *name, bool cache)
{
	Class class;

	if (classes == NULL)
		return Nil;

	/*
	 * Fast path
	 *
	 * Instead of looking up the string in a dictionary, which needs
	 * locking, we use a sparse array to look up the pointer. If
	 * _objc_classnameToClass() gets called a lot, it is most likely that
	 * the GCC ABI is used, which always calls into objc_lookup_class(), or
	 * that it is used in a loop by the user. In both cases, it is very
	 * likely that the same string pointer is passed again and again.
	 *
	 * This is not used before _objc_classnameToClass() has been called a
	 * certain amount of times, so that no memory is wasted if it is only
	 * used rarely, for example if the ObjFW ABI is used and the user does
	 * not call it in a loop.
	 *
	 * Runtime internal usage does not use the fast path and does not count
	 * as a call into _objc_classnameToClass(). The reason for this is that
	 * if the runtime calls into _objc_classnameToClass(), it already has
	 * the lock and thus the performance gain would be small, but it would
	 * waste memory.
	 */
	if (cache && fastPath != NULL) {
		class = _objc_sparsearray_get(fastPath, (uintptr_t)name);

		if (class != Nil)
			return class;
	}

	_objc_globalMutex_lock();

	class = (Class)((uintptr_t)_objc_hashtable_get(classes, name) & ~1);

	if (cache && fastPath == NULL && --lookupsUntilFastPath == 0)
		fastPath = _objc_sparsearray_new(sizeof(uintptr_t));

	if (cache && fastPath != NULL)
		_objc_sparsearray_set(fastPath, (uintptr_t)name, class);

	_objc_globalMutex_unlock();

	return class;
}

static void
callSelector(Class class, SEL selector)
{
	for (struct _objc_method_list *methodList = class->isa->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    selector))
				((void (*)(id, SEL))methodList->methods[i]
				    .implementation)(class, selector);
}

static bool
hasLoad(Class class)
{
	static SEL loadSel = NULL;

	if (loadSel == NULL)
		loadSel = sel_registerName("load");

	for (struct _objc_method_list *methodList = class->isa->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (size_t i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    loadSel))
				return true;

	return false;
}

static void
callLoad(Class class)
{
	static SEL loadSel = NULL;

	if (loadSel == NULL)
		loadSel = sel_registerName("load");

	if (class->info & _OBJC_CLASS_INFO_LOADED)
		return;

	if (class->superclass != Nil)
		callLoad(class->superclass);

	callSelector(class, loadSel);

	class->info |= _OBJC_CLASS_INFO_LOADED;
}

void
_objc_updateDTable(Class class)
{
	bool usesRuntimeRR = false, hasCustomRR = false;
	static SEL retainSel = NULL, retainCountSel = NULL, releaseSel = NULL;
	static SEL autoreleaseSel = NULL, usesRuntimeRRSel = NULL;
	unsigned long superclassInfo = 0;
	struct _objc_category **categories;

	if (retainSel == NULL || retainCountSel == NULL || releaseSel == NULL ||
	    autoreleaseSel == NULL || usesRuntimeRRSel == NULL) {
		retainSel = sel_registerName("retain");
		retainCountSel = sel_registerName("retainCount");
		releaseSel = sel_registerName("release");
		autoreleaseSel = sel_registerName("autorelease");
		usesRuntimeRRSel = sel_registerName("_usesRuntimeRR");

		if (retainSel == NULL || retainCountSel == NULL ||
		    releaseSel == NULL || autoreleaseSel == NULL ||
		    usesRuntimeRRSel == NULL)
			_OBJC_ERROR("Failed to register internal selectors");
	}

	if (!(class->info & _OBJC_CLASS_INFO_DTABLE))
		return;

	if (class->dTable == emptyDTable)
		class->dTable = _objc_dtable_new();

	if (class->superclass != Nil) {
		superclassInfo = class->superclass->info;
		_objc_dtable_copy(class->dTable, class->superclass->dTable);
	}

	for (struct _objc_method_list *methodList = class->methodList;
	    methodList != NULL; methodList = methodList->next) {
		for (unsigned int i = 0; i < methodList->count; i++) {
			SEL selector = (SEL)&methodList->methods[i].selector;

			_objc_dtable_set(class->dTable, (uint32_t)selector->UID,
			    methodList->methods[i].implementation);

			if (sel_isEqual(selector, retainSel) ||
			    sel_isEqual(selector, retainCountSel) ||
			    sel_isEqual(selector, releaseSel) ||
			    sel_isEqual(selector, autoreleaseSel))
				hasCustomRR = true;

			if (sel_isEqual(selector, usesRuntimeRRSel))
				usesRuntimeRR = true;
		}
	}

	if ((categories = _objc_categoriesForClass(class)) != NULL) {
		for (unsigned int i = 0; categories[i] != NULL; i++) {
			struct _objc_method_list *methodList =
			    (class->info & _OBJC_CLASS_INFO_CLASS
			    ? categories[i]->instanceMethods
			    : categories[i]->classMethods);

			for (; methodList != NULL;
			    methodList = methodList->next) {
				for (unsigned int j = 0;
				    j < methodList->count; j++) {
					SEL selector = (SEL)
					    &methodList->methods[j].selector;

					_objc_dtable_set(class->dTable,
					    (uint32_t)selector->UID,
					    methodList->methods[j]
					    .implementation);

					if (sel_isEqual(selector, retainSel) ||
					    sel_isEqual(selector,
					    retainCountSel) ||
					    sel_isEqual(selector, releaseSel) ||
					    sel_isEqual(selector,
					    autoreleaseSel))
						hasCustomRR = true;

					if (sel_isEqual(selector,
					    usesRuntimeRRSel))
						usesRuntimeRR = true;
				}
			}
		}
	}

	if (usesRuntimeRR ||
	    (!hasCustomRR && (superclassInfo & _OBJC_CLASS_INFO_RUNTIME_RR)))
		class->info |= _OBJC_CLASS_INFO_RUNTIME_RR;
	else
		class->info &= ~_OBJC_CLASS_INFO_RUNTIME_RR;

	if (class->subclassList != NULL)
		for (Class *iter = class->subclassList; *iter != NULL; iter++)
			_objc_updateDTable(*iter);
}

static void
addSubclass(Class class)
{
	size_t i;

	if (class->superclass->subclassList == NULL) {
		if ((class->superclass->subclassList =
		    malloc(2 * sizeof(Class))) == NULL)
			_OBJC_ERROR("Not enough memory for subclass list of "
			    "class %s!", class->superclass->name);

		class->superclass->subclassList[0] = class;
		class->superclass->subclassList[1] = Nil;

		return;
	}

	for (i = 0; class->superclass->subclassList[i] != Nil; i++);

	class->superclass->subclassList =
	    realloc(class->superclass->subclassList, (i + 2) * sizeof(Class));

	if (class->superclass->subclassList == NULL)
		_OBJC_ERROR("Not enough memory for subclass list of class %s\n",
		    class->superclass->name);

	class->superclass->subclassList[i] = class;
	class->superclass->subclassList[i + 1] = Nil;
}

static void
updateIvarOffsets(Class class)
{
	if (!(class->info & _OBJC_CLASS_INFO_NEW_ABI))
		return;

	if (class->instanceSize > 0)
		return;

	class->instanceSize = -class->instanceSize;

	if (class->superclass != Nil) {
		class->instanceSize += class->superclass->instanceSize;

		if (class->ivars != NULL) {
			for (unsigned int i = 0; i < class->ivars->count; i++) {
				class->ivars->ivars[i].offset +=
				    class->superclass->instanceSize;
				*class->ivarOffsets[i] =
				    class->ivars->ivars[i].offset;
			}
		}
	} else
		for (unsigned int i = 0; i < class->ivars->count; i++)
			*class->ivarOffsets[i] = class->ivars->ivars[i].offset;
}

static void
setUpClass(Class class)
{
	const char *superclassName;

	if (class->info & _OBJC_CLASS_INFO_SETUP)
		return;

	superclassName = (const char *)class->superclass;
	if (superclassName != NULL) {
		Class super = _objc_classnameToClass(superclassName, false);
		Class rootClass;

		if (super == Nil)
			return;

		setUpClass(super);

		if (!(super->info & _OBJC_CLASS_INFO_SETUP))
			return;

		/*
		 * GCC sets class->isa->isa to the name of the root class,
		 * while Clang just sets it to Nil. Therefore always calculate
		 * it.
		 */
		for (Class iter = super; iter != NULL; iter = iter->superclass)
			rootClass = iter;

		class->superclass = super;
		class->isa->isa = rootClass->isa;
		class->isa->superclass = super->isa;

		addSubclass(class);
		addSubclass(class->isa);
	} else {
		class->isa->isa = class->isa;
		class->isa->superclass = class;
	}

	updateIvarOffsets(class);

	class->info |= _OBJC_CLASS_INFO_SETUP;
	class->isa->info |= _OBJC_CLASS_INFO_SETUP;
}

static void
initializeClass(Class class)
{
	static SEL initializeSel = NULL;

	if (initializeSel == NULL)
		initializeSel = sel_registerName("initialize");

	if (class->info & _OBJC_CLASS_INFO_INITIALIZED)
		return;

	if (class->superclass)
		initializeClass(class->superclass);

	/*
	 * Avoid double-initialization: One of the superclasses' +[initialize]
	 * might have called this class and hence it already got initialized.
	 */
	if (class->info & _OBJC_CLASS_INFO_INITIALIZED)
		return;

	class->info |= _OBJC_CLASS_INFO_DTABLE;
	class->isa->info |= _OBJC_CLASS_INFO_DTABLE;

	_objc_updateDTable(class);
	_objc_updateDTable(class->isa);

	/*
	 * Set it first to prevent calling it recursively due to message sends
	 * in the initialize method
	 */
	class->info |= _OBJC_CLASS_INFO_INITIALIZED;
	class->isa->info |= _OBJC_CLASS_INFO_INITIALIZED;

	/*
	 * +[initialize] might get called from some +[load], before the
	 * constructors of this compilation module have been called, at which
	 * point the selector would not be properly initialized.
	 */
	if (class_respondsToSelector(object_getClass(class), initializeSel)) {
		void (*initialize)(id, SEL) = (void (*)(id, SEL))
		    objc_msg_lookup(class, initializeSel);

		initialize(class, initializeSel);
	}
}

void
_objc_initializeClass(Class class)
{
	if (class->info & _OBJC_CLASS_INFO_INITIALIZED)
		return;

	_objc_globalMutex_lock();

	/*
	 * It's possible that two threads try to initialize a class at the same
	 * time. Make sure that the thread which held the lock did not already
	 * initialize it.
	 */
	if (class->info & _OBJC_CLASS_INFO_INITIALIZED) {
		_objc_globalMutex_unlock();
		return;
	}

	setUpClass(class);

	if (!(class->info & _OBJC_CLASS_INFO_SETUP)) {
		_objc_globalMutex_unlock();
		return;
	}

	initializeClass(class);

	_objc_globalMutex_unlock();
}

static void
processLoadQueue(void)
{
	for (size_t i = 0; i < loadQueueCount; i++) {
		setUpClass(loadQueue[i]);

		if (loadQueue[i]->info & _OBJC_CLASS_INFO_SETUP) {
			callLoad(loadQueue[i]);

			if (--loadQueueCount == 0) {
				free(loadQueue);
				loadQueue = NULL;
				loadQueueCount = 0;
				break;
			}

			loadQueue[i] = loadQueue[loadQueueCount];

			loadQueue = realloc(loadQueue,
			    sizeof(Class) * loadQueueCount);

			if (loadQueue == NULL)
				_OBJC_ERROR("Not enough memory for load "
				    "queue!");
		}
	}
}

void
_objc_registerAllClasses(struct _objc_symtab *symtab)
{
	for (uint16_t i = 0; i < symtab->classDefsCount; i++) {
		Class class = (Class)symtab->defs[i];

		registerClass(class);
		registerSelectors(class);
		registerSelectors(class->isa);
	}

	for (uint16_t i = 0; i < symtab->classDefsCount; i++) {
		Class class = (Class)symtab->defs[i];

		if (hasLoad(class)) {
			setUpClass(class);

			if (class->info & _OBJC_CLASS_INFO_SETUP)
				callLoad(class);
			else {
				loadQueue = realloc(loadQueue,
				    sizeof(Class) * (loadQueueCount + 1));

				if (loadQueue == NULL)
					_OBJC_ERROR("Not enough memory for "
					    "load queue!");

				loadQueue[loadQueueCount++] = class;
			}
		} else
			class->info |= _OBJC_CLASS_INFO_LOADED;
	}

	processLoadQueue();
	_objc_processCategoriesLoadQueue();
}

Class
objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
{
	struct _objc_class *class, *metaclass;
	Class iter, rootclass = Nil;

	if ((class = calloc(1, sizeof(*class))) == NULL ||
	    (metaclass = calloc(1, sizeof(*class))) == NULL)
		_OBJC_ERROR("Not enough memory to allocate class pair for "
		    "class %s!", name);

	class->isa = metaclass;
	class->superclass = superclass;
	class->name = name;
	class->info = _OBJC_CLASS_INFO_CLASS;
	class->instanceSize = (superclass != Nil ?
	    superclass->instanceSize : 0);

	if (extraBytes > LONG_MAX ||
	    LONG_MAX - class->instanceSize < (long)extraBytes)
		_OBJC_ERROR("extraBytes too large!");

	class->instanceSize += (long)extraBytes;

	for (iter = superclass; iter != Nil; iter = iter->superclass)
		rootclass = iter;

	metaclass->isa = (rootclass != Nil ? rootclass->isa : class);
	metaclass->superclass = (superclass != Nil ? superclass->isa : Nil);
	metaclass->name = name;
	metaclass->info = _OBJC_CLASS_INFO_CLASS;
	metaclass->instanceSize = (superclass != Nil ?
	    superclass->isa->instanceSize : 0) + (long)extraBytes;

	return class;
}

void
objc_registerClassPair(Class class)
{
	_objc_globalMutex_lock();

	registerClass(class);

	if (class->superclass != Nil) {
		addSubclass(class);
		addSubclass(class->isa);
	}

	class->info |= _OBJC_CLASS_INFO_SETUP;
	class->isa->info |= _OBJC_CLASS_INFO_SETUP;

	if (hasLoad(class))
		callLoad(class);
	else
		class->info |= _OBJC_CLASS_INFO_LOADED;

	processLoadQueue();
	_objc_processCategoriesLoadQueue();

	_objc_globalMutex_unlock();
}

Class
objc_lookUpClass(const char *name)
{
	Class class;

	if ((class = _objc_classnameToClass(name, true)) == NULL)
		return Nil;

	if (class->info & _OBJC_CLASS_INFO_SETUP)
		return class;

	_objc_globalMutex_lock();

	setUpClass(class);

	_objc_globalMutex_unlock();

	if (!(class->info & _OBJC_CLASS_INFO_SETUP))
		return Nil;

	return class;
}

Class
objc_getClass(const char *name)
{
	return objc_lookUpClass(name);
}

Class
objc_getRequiredClass(const char *name)
{
	Class class;

	if ((class = objc_getClass(name)) == Nil)
		_OBJC_ERROR("Class %s not found!", name);

	return class;
}

Class
objc_lookup_class(const char *name)
{
	return objc_getClass(name);
}

Class
objc_get_class(const char *name)
{
	return objc_getRequiredClass(name);
}

unsigned int
objc_getClassList(Class *buffer, unsigned int count)
{
	unsigned int j;
	_objc_globalMutex_lock();

	if (buffer == NULL) {
		count = classesCount;

		_objc_globalMutex_unlock();

		return count;
	}

	if (classesCount < count)
		count = classesCount;

	j = 0;
	for (uint32_t i = 0; i < classes->size; i++) {
		void *class;

		if (j >= count) {
			_objc_globalMutex_unlock();
			return j;
		}

		if (classes->data[i] == NULL ||
		    classes->data[i] == &_objc_deletedBucket)
			continue;

		if (strcmp(classes->data[i]->key, "Protocol") == 0)
			continue;

		class = (Class)classes->data[i]->object;

		if (class == Nil || (uintptr_t)class & 1)
			continue;

		buffer[j++] = class;
	}

	_objc_globalMutex_unlock();

	return j;
}

Class *
objc_copyClassList(unsigned int *length)
{
	Class *ret;
	unsigned int count;

	_objc_globalMutex_lock();

	if ((ret = malloc((classesCount + 1) * sizeof(Class))) == NULL)
		_OBJC_ERROR("Failed to allocate memory for class list!");

	count = objc_getClassList(ret, classesCount);
	if (count != classesCount)
		_OBJC_ERROR("Fatal internal inconsistency!");

	ret[count] = Nil;

	if (length != NULL)
		*length = count;

	_objc_globalMutex_unlock();

	return ret;
}

bool
class_isMetaClass(Class class)
{
	if (class == Nil)
		return false;

	return (class->info & _OBJC_CLASS_INFO_METACLASS);
}

const char *
class_getName(Class class)
{
	if (class == Nil)
		return "";

	return class->name;
}

Class
class_getSuperclass(Class class)
{
	if (class == Nil)
		return Nil;

	return class->superclass;
}

unsigned long
class_getInstanceSize(Class class)
{
	if (class == Nil)
		return 0;

	return class->instanceSize;
}

IMP
class_getMethodImplementation(Class class, SEL selector)
{
	/*
	 * We use a dummy object here so that the normal lookup is used, even
	 * though we don't have an object. Doing so is safe, as objc_msg_lookup
	 * does not access the object, but only its class.
	 *
	 * Just looking it up in the dispatch table could result in returning
	 * NULL instead of the forwarding handler, it would also mean
	 * +[resolveClassMethod:] / +[resolveInstanceMethod:] would not be
	 * called.
	 */
	struct {
		Class isa;
	} dummy;

	if (class == Nil)
		return NULL;

	dummy.isa = class;
	return objc_msg_lookup((id)&dummy, selector);
}

IMP
class_getMethodImplementation_stret(Class class, SEL selector)
{
	/*
	 * Same as above, but use objc_msg_lookup_stret instead, so that the
	 * correct forwarding handler is returned.
	 */
	struct {
		Class isa;
	} dummy;

	if (class == Nil)
		return NULL;

	dummy.isa = class;
	return objc_msg_lookup_stret((id)&dummy, selector);
}

static struct _objc_method *
getMethod(Class class, SEL selector)
{
	struct _objc_category **categories;

	if ((categories = _objc_categoriesForClass(class)) != NULL) {
		for (; *categories != NULL; categories++) {
			struct _objc_method_list *methodList =
			    (class->info & _OBJC_CLASS_INFO_METACLASS
			    ? (*categories)->classMethods
			    : (*categories)->instanceMethods);

			for (; methodList != NULL;
			    methodList = methodList->next)
				for (unsigned int i = 0;
				    i < methodList->count; i++)
					if (sel_isEqual((SEL)
					    &methodList->methods[i].selector,
					    selector))
						return &methodList->methods[i];
		}
	}

	for (struct _objc_method_list *methodList = class->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    selector))
				return &methodList->methods[i];

	return NULL;
}

static void
addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	struct _objc_method_list *methodList;

	/* FIXME: We need a way to free this at objc_deinit() */
	if ((methodList = malloc(sizeof(*methodList))) == NULL)
		_OBJC_ERROR("Not enough memory to replace method!");

	methodList->next = class->methodList;
	methodList->count = 1;
	methodList->methods[0].selector.UID = selector->UID;
	methodList->methods[0].selector.typeEncoding = typeEncoding;
	methodList->methods[0].implementation = implementation;

	class->methodList = methodList;

	_objc_updateDTable(class);
}

Method
#if defined(__clang__) && __has_attribute(__optnone__) && \
    __clang_major__ == 3 && __clang_minor__ <= 7
/* Work around an ICE in Clang 3.7.0 on Windows/x86 */
__attribute__((__optnone__))
#endif
class_getInstanceMethod(Class class, SEL selector)
{
	Method method;
	Class superclass;

	if (class == Nil)
		return NULL;

	_objc_globalMutex_lock();

	if ((method = getMethod(class, selector)) != NULL) {
		_objc_globalMutex_unlock();
		return method;
	}

	superclass = class->superclass;

	_objc_globalMutex_unlock();

	if (superclass != Nil)
		return class_getInstanceMethod(superclass, selector);

	return NULL;
}

bool
class_addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	bool ret;

	_objc_globalMutex_lock();

	if (getMethod(class, selector) == NULL) {
		addMethod(class, selector, implementation, typeEncoding);
		ret = true;
	} else
		ret = false;

	_objc_globalMutex_unlock();

	return ret;
}

IMP
class_replaceMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	struct _objc_method *method;
	IMP oldImplementation;

	_objc_globalMutex_lock();

	if ((method = getMethod(class, selector)) != NULL) {
		oldImplementation = method->implementation;
		method->implementation = implementation;
		_objc_updateDTable(class);
	} else {
		oldImplementation = NULL;
		addMethod(class, selector, implementation, typeEncoding);
	}

	_objc_globalMutex_unlock();

	return oldImplementation;
}

Class
object_getClass(id object_)
{
	struct _objc_object *object;

	if (object_ == nil)
		return Nil;

	if (object_isTaggedPointer(object_))
		return _object_getTaggedPointerClass(object_);

	object = (struct _objc_object *)object_;

	return object->isa;
}

Class
object_setClass(id object_, Class class)
{
	struct _objc_object *object;
	Class old;

	if (object_ == nil)
		return Nil;

	object = (struct _objc_object *)object_;

	old = object->isa;
	object->isa = class;

	return old;
}

const char *
object_getClassName(id object)
{
	return class_getName(object_getClass(object));
}

static void
unregisterClass(Class class)
{
	if ((class->info & _OBJC_CLASS_INFO_SETUP) &&
	    class->superclass != Nil &&
	    class->superclass->subclassList != NULL) {
		size_t i = SIZE_MAX, count = 0;
		Class *tmp;

		for (tmp = class->superclass->subclassList;
		    *tmp != Nil; tmp++) {
			if (*tmp == class)
				i = count;

			count++;
		}

		if (count > 0 && i < SIZE_MAX) {
			tmp = class->superclass->subclassList;
			tmp[i] = tmp[count - 1];
			tmp[count - 1] = NULL;

			if ((tmp = realloc(class->superclass->subclassList,
			    count * sizeof(Class))) != NULL)
				class->superclass->subclassList = tmp;
		}
	}

	if (class->subclassList != NULL) {
		free(class->subclassList);
		class->subclassList = NULL;
	}

	if (class->dTable != NULL && class->dTable != emptyDTable)
		_objc_dtable_free(class->dTable);

	class->dTable = NULL;

	if ((class->info & _OBJC_CLASS_INFO_SETUP) && class->superclass != Nil)
		class->superclass = (Class)class->superclass->name;

	class->info &= ~_OBJC_CLASS_INFO_SETUP;
}

void
_objc_unregisterClass(Class class)
{
	static SEL unloadSel = NULL;

	_objc_globalMutex_lock();

	if (unloadSel == NULL)
		unloadSel = sel_registerName("unload");

	while (class->subclassList != NULL && class->subclassList[0] != Nil)
		_objc_unregisterClass(class->subclassList[0]);

	if (class->info & _OBJC_CLASS_INFO_LOADED)
		callSelector(class, unloadSel);

	_objc_hashtable_delete(classes, class->name);

	if (strcmp(class_getName(class), "Protocol") != 0)
		classesCount--;

	unregisterClass(class);
	unregisterClass(class->isa);

	_objc_globalMutex_unlock();
}

void
_objc_unregisterAllClasses(void)
{
	if (classes == NULL)
		return;

	for (uint32_t i = 0; i < classes->size; i++) {
		if (classes->data[i] != NULL &&
		    classes->data[i] != &_objc_deletedBucket) {
			void *class = (Class)classes->data[i]->object;

			if (class == Nil || (uintptr_t)class & 1)
				continue;

			_objc_unregisterClass(class);

			/*
			 * The table might have been resized, so go back to the
			 * start again.
			 *
			 * Due to the i++ in the for loop, we need to set it to
			 * UINT32_MAX so that it will get increased at the end
			 * of the loop and thus become 0.
			 */
			i = UINT32_MAX;
		}
	}

	if (classesCount != 0)
		_OBJC_ERROR("Fatal internal inconsistency!");

	if (emptyDTable != NULL) {
		_objc_dtable_free(emptyDTable);
		emptyDTable = NULL;
	}

	_objc_sparsearray_free(fastPath);
	fastPath = NULL;

	_objc_hashtable_free(classes);
	classes = NULL;
}
