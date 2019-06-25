/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "ObjFWRT.h"
#import "private.h"

static struct objc_hashtable *classes = NULL;
static unsigned classesCount = 0;
static Class *loadQueue = NULL;
static size_t loadQueueCount = 0;
static struct objc_dtable *emptyDTable = NULL;
static unsigned lookupsUntilFastPath = 128;
static struct objc_sparsearray *fastPath = NULL;

static void
registerClass(struct objc_abi_class *rawClass)
{
	if (classes == NULL)
		classes = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);

	objc_hashtable_set(classes, rawClass->name, rawClass);

	if (emptyDTable == NULL)
		emptyDTable = objc_dtable_new();

	rawClass->DTable = emptyDTable;
	rawClass->metaclass->DTable = emptyDTable;

	if (strcmp(rawClass->name, "Protocol") != 0)
		classesCount++;
}

bool
class_registerAlias_np(Class class, const char *name)
{
	objc_global_mutex_lock();

	if (classes == NULL) {
		objc_global_mutex_unlock();

		return NO;
	}

	objc_hashtable_set(classes, name, (Class)((uintptr_t)class | 1));

	objc_global_mutex_unlock();

	return YES;
}

static void
registerSelectors(struct objc_abi_class *rawClass)
{
	struct objc_abi_method_list *methodList;

	for (methodList = rawClass->methodList; methodList != NULL;
	    methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_register_selector((struct objc_abi_selector *)
			    &methodList->methods[i]);
}

Class
objc_classname_to_class(const char *name, bool cache)
{
	Class class;

	if (classes == NULL)
		return Nil;

	/*
	 * Fast path
	 *
	 * Instead of looking up the string in a dictionary, which needs
	 * locking, we use a sparse array to look up the pointer. If
	 * objc_classname_to_class() gets called a lot, it is most likely that
	 * the GCC ABI is used, which always calls into objc_lookup_class(), or
	 * that it is used in a loop by the user. In both cases, it is very
	 * likely that the same string pointer is passed again and again.
	 *
	 * This is not used before objc_classname_to_class() has been called a
	 * certain amount of times, so that no memory is wasted if it is only
	 * used rarely, for example if the ObjFW ABI is used and the user does
	 * not call it in a loop.
	 *
	 * Runtime internal usage does not use the fast path and does not count
	 * as a call into objc_classname_to_class(). The reason for this is
	 * that if the runtime calls into objc_classname_to_class(), it already
	 * has the lock and thus the performance gain would be small, but it
	 * would waste memory.
	 */
	if (cache && fastPath != NULL) {
		class = objc_sparsearray_get(fastPath, (uintptr_t)name);

		if (class != Nil)
			return class;
	}

	objc_global_mutex_lock();

	class = (Class)((uintptr_t)objc_hashtable_get(classes, name) & ~1);

	if (cache && fastPath == NULL && --lookupsUntilFastPath == 0)
		fastPath = objc_sparsearray_new(sizeof(uintptr_t));

	if (cache && fastPath != NULL)
		objc_sparsearray_set(fastPath, (uintptr_t)name, class);

	objc_global_mutex_unlock();

	return class;
}

static void
callSelector(Class class, SEL selector)
{
	for (struct objc_method_list *methodList = class->isa->methodList;
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

	for (struct objc_method_list *methodList = class->isa->methodList;
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

	if (class->info & OBJC_CLASS_INFO_LOADED)
		return;

	if (class->superclass != Nil)
		callLoad(class->superclass);

	callSelector(class, loadSel);

	class->info |= OBJC_CLASS_INFO_LOADED;
}

void
objc_update_dtable(Class class)
{
	struct objc_category **categories;

	if (!(class->info & OBJC_CLASS_INFO_DTABLE))
		return;

	if (class->DTable == emptyDTable)
		class->DTable = objc_dtable_new();

	if (class->superclass != Nil)
		objc_dtable_copy(class->DTable, class->superclass->DTable);

	for (struct objc_method_list *methodList = class->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_dtable_set(class->DTable,
			    (uint32_t)methodList->methods[i].selector.UID,
			    methodList->methods[i].implementation);

	if ((categories = objc_categories_for_class(class)) != NULL) {
		for (unsigned int i = 0; categories[i] != NULL; i++) {
			struct objc_method_list *methodList =
			    (class->info & OBJC_CLASS_INFO_CLASS
			    ? categories[i]->instanceMethods
			    : categories[i]->classMethods);

			for (; methodList != NULL;
			    methodList = methodList->next)
				for (unsigned int j = 0;
				    j < methodList->count; j++)
					objc_dtable_set(class->DTable,
					    (uint32_t)methodList->methods[j]
					    .selector.UID,
					    methodList->methods[j]
					    .implementation);
		}
	}

	if (class->subclassList != NULL)
		for (Class *iter = class->subclassList; *iter != NULL; iter++)
			objc_update_dtable(*iter);
}

static void
addSubclass(Class class)
{
	size_t i;

	if (class->superclass->subclassList == NULL) {
		if ((class->superclass->subclassList =
		    malloc(2 * sizeof(Class))) == NULL)
			OBJC_ERROR("Not enough memory for subclass list of "
			    "class %s!", class->superclass->name);

		class->superclass->subclassList[0] = class;
		class->superclass->subclassList[1] = Nil;

		return;
	}

	for (i = 0; class->superclass->subclassList[i] != Nil; i++);

	class->superclass->subclassList =
	    realloc(class->superclass->subclassList, (i + 2) * sizeof(Class));

	if (class->superclass->subclassList == NULL)
		OBJC_ERROR("Not enough memory for subclass list of class %s\n",
		    class->superclass->name);

	class->superclass->subclassList[i] = class;
	class->superclass->subclassList[i + 1] = Nil;
}


static void
updateIVarOffsets(Class class)
{
	if (!(class->info & OBJC_CLASS_INFO_NEW_ABI))
		return;

	if (class->instanceSize > 0)
		return;

	class->instanceSize = -class->instanceSize;

	if (class->superclass != Nil) {
		class->instanceSize += class->superclass->instanceSize;

		if (class->iVars != NULL) {
			for (unsigned int i = 0; i < class->iVars->count; i++) {
				class->iVars->iVars[i].offset +=
				    class->superclass->instanceSize;
				*class->iVarOffsets[i] =
				    class->iVars->iVars[i].offset;
			}
		}
	} else
		for (unsigned int i = 0; i < class->iVars->count; i++)
			*class->iVarOffsets[i] = class->iVars->iVars[i].offset;
}

static void
setupClass(Class class)
{
	const char *superclassName;

	if (class->info & OBJC_CLASS_INFO_SETUP)
		return;

	superclassName = ((struct objc_abi_class *)class)->superclass;
	if (superclassName != NULL) {
		Class super = objc_classname_to_class(superclassName, false);

		if (super == Nil)
			return;

		setupClass(super);

		if (!(super->info & OBJC_CLASS_INFO_SETUP))
			return;

		class->superclass = super;
		class->isa->superclass = super->isa;

		addSubclass(class);
		addSubclass(class->isa);
	} else
		class->isa->superclass = class;

	updateIVarOffsets(class);

	class->info |= OBJC_CLASS_INFO_SETUP;
	class->isa->info |= OBJC_CLASS_INFO_SETUP;
}

static void
initializeClass(Class class)
{
	static SEL initializeSel = NULL;

	if (initializeSel == NULL)
		initializeSel = sel_registerName("initialize");

	if (class->info & OBJC_CLASS_INFO_INITIALIZED)
		return;

	if (class->superclass)
		initializeClass(class->superclass);

	class->info |= OBJC_CLASS_INFO_DTABLE;
	class->isa->info |= OBJC_CLASS_INFO_DTABLE;

	objc_update_dtable(class);
	objc_update_dtable(class->isa);

	/*
	 * Set it first to prevent calling it recursively due to message sends
	 * in the initialize method
	 */
	class->info |= OBJC_CLASS_INFO_INITIALIZED;
	class->isa->info |= OBJC_CLASS_INFO_INITIALIZED;

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
objc_initialize_class(Class class)
{
	if (class->info & OBJC_CLASS_INFO_INITIALIZED)
		return;

	objc_global_mutex_lock();

	/*
	 * It's possible that two threads try to initialize a class at the same
	 * time. Make sure that the thread which held the lock did not already
	 * initialize it.
	 */
	if (class->info & OBJC_CLASS_INFO_INITIALIZED) {
		objc_global_mutex_unlock();
		return;
	}

	setupClass(class);

	if (!(class->info & OBJC_CLASS_INFO_SETUP)) {
		objc_global_mutex_unlock();
		return;
	}

	initializeClass(class);

	objc_global_mutex_unlock();
}

static void
processLoadQueue()
{
	for (size_t i = 0; i < loadQueueCount; i++) {
		setupClass(loadQueue[i]);

		if (loadQueue[i]->info & OBJC_CLASS_INFO_SETUP) {
			callLoad(loadQueue[i]);

			loadQueueCount--;

			if (loadQueueCount == 0) {
				free(loadQueue);
				loadQueue = NULL;
				continue;
			}

			loadQueue[i] = loadQueue[loadQueueCount];

			loadQueue = realloc(loadQueue,
			    sizeof(Class) * loadQueueCount);

			if (loadQueue == NULL)
				OBJC_ERROR("Not enough memory for load queue!");
		}
	}
}

void
objc_register_all_classes(struct objc_abi_symtab *symtab)
{
	for (uint16_t i = 0; i < symtab->classDefsCount; i++) {
		struct objc_abi_class *rawClass =
		    (struct objc_abi_class *)symtab->defs[i];

		registerClass(rawClass);
		registerSelectors(rawClass);
		registerSelectors(rawClass->metaclass);
	}

	for (uint16_t i = 0; i < symtab->classDefsCount; i++) {
		Class class = (Class)symtab->defs[i];

		if (hasLoad(class)) {
			setupClass(class);

			if (class->info & OBJC_CLASS_INFO_SETUP)
				callLoad(class);
			else {
				loadQueue = realloc(loadQueue,
				    sizeof(Class) * (loadQueueCount + 1));

				if (loadQueue == NULL)
					OBJC_ERROR("Not enough memory for load "
					    "queue!");

				loadQueue[loadQueueCount++] = class;
			}
		} else
			class->info |= OBJC_CLASS_INFO_LOADED;
	}

	processLoadQueue();
}

Class
objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
{
	struct objc_class *class, *metaclass;
	Class iter, rootclass = Nil;

	if (extraBytes > LONG_MAX)
		OBJC_ERROR("extra_bytes out of range!")

	if ((class = calloc(1, sizeof(*class))) == NULL ||
	    (metaclass = calloc(1, sizeof(*class))) == NULL)
		OBJC_ERROR("Not enough memory to allocate class pair for class "
		    "%s!", name)

	class->isa = metaclass;
	class->superclass = superclass;
	class->name = name;
	class->info = OBJC_CLASS_INFO_CLASS;
	class->instanceSize = (superclass != Nil ?
	    superclass->instanceSize : 0) + (long)extraBytes;

	for (iter = superclass; iter != Nil; iter = iter->superclass)
		rootclass = iter;

	metaclass->isa = (rootclass != Nil ? rootclass->isa : class);
	metaclass->superclass = (superclass != Nil ? superclass->isa : Nil);
	metaclass->name = name;
	metaclass->info = OBJC_CLASS_INFO_CLASS;
	metaclass->instanceSize = (superclass != Nil ?
	    superclass->isa->instanceSize : 0) + (long)extraBytes;

	return class;
}

void
objc_registerClassPair(Class class)
{
	objc_global_mutex_lock();

	registerClass((struct objc_abi_class *)class);

	if (class->superclass != Nil) {
		addSubclass(class);
		addSubclass(class->isa);
	}

	class->info |= OBJC_CLASS_INFO_SETUP;
	class->isa->info |= OBJC_CLASS_INFO_SETUP;

	if (hasLoad(class))
		callLoad(class);
	else
		class->info |= OBJC_CLASS_INFO_LOADED;

	processLoadQueue();

	objc_global_mutex_unlock();
}

Class
objc_lookUpClass(const char *name)
{
	Class class;

	if ((class = objc_classname_to_class(name, true)) == NULL)
		return Nil;

	if (class->info & OBJC_CLASS_INFO_SETUP)
		return class;

	objc_global_mutex_lock();

	setupClass(class);

	objc_global_mutex_unlock();

	if (!(class->info & OBJC_CLASS_INFO_SETUP))
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
		OBJC_ERROR("Class %s not found!", name);

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
	objc_global_mutex_lock();

	if (buffer == NULL)
		return classesCount;

	if (classesCount < count)
		count = classesCount;

	j = 0;
	for (uint32_t i = 0; i < classes->size; i++) {
		void *class;

		if (j >= count) {
			objc_global_mutex_unlock();
			return j;
		}

		if (classes->data[i] == NULL)
			continue;

		if (strcmp(classes->data[i]->key, "Protocol") == 0)
			continue;

		class = (Class)classes->data[i]->object;

		if (class == Nil || (uintptr_t)class & 1)
			continue;

		buffer[j++] = class;
	}

	objc_global_mutex_unlock();

	return j;
}

Class *
objc_copyClassList(unsigned int *length)
{
	Class *ret;
	unsigned int count;

	objc_global_mutex_lock();

	if ((ret = malloc((classesCount + 1) * sizeof(Class))) == NULL)
		OBJC_ERROR("Failed to allocate memory for class list!");

	count = objc_getClassList(ret, classesCount);
	OF_ENSURE(count == classesCount);

	ret[count] = Nil;

	if (length != NULL)
		*length = count;

	objc_global_mutex_unlock();

	return ret;
}

bool
class_isMetaClass(Class class)
{
	if (class == Nil)
		return false;

	return (class->info & OBJC_CLASS_INFO_METACLASS);
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

static struct objc_method *
getMethod(Class class, SEL selector)
{
	struct objc_category **categories;

	if ((categories = objc_categories_for_class(class)) != NULL) {
		for (; *categories != NULL; categories++) {
			struct objc_method_list *methodList =
			    (class->info & OBJC_CLASS_INFO_METACLASS
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

	for (struct objc_method_list *methodList = class->methodList;
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
	struct objc_method_list *methodList;

	/* FIXME: We need a way to free this at objc_exit() */
	if ((methodList = malloc(sizeof(*methodList))) == NULL)
		OBJC_ERROR("Not enough memory to replace method!");

	methodList->next = class->methodList;
	methodList->count = 1;
	methodList->methods[0].selector.UID = selector->UID;
	methodList->methods[0].selector.typeEncoding = typeEncoding;
	methodList->methods[0].implementation = implementation;

	class->methodList = methodList;

	objc_update_dtable(class);
}

const char *
class_getMethodTypeEncoding(Class class, SEL selector)
{
	struct objc_method *method;

	if (class == Nil)
		return NULL;

	objc_global_mutex_lock();

	if ((method = getMethod(class, selector)) != NULL) {
		const char *ret = method->selector.typeEncoding;
		objc_global_mutex_unlock();
		return ret;
	}

	objc_global_mutex_unlock();

	if (class->superclass != Nil)
		return class_getMethodTypeEncoding(class->superclass, selector);

	return NULL;
}

bool
class_addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	bool ret;

	objc_global_mutex_lock();

	if (getMethod(class, selector) == NULL) {
		addMethod(class, selector, implementation, typeEncoding);
		ret = true;
	} else
		ret = false;

	objc_global_mutex_unlock();

	return ret;
}

IMP
class_replaceMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	struct objc_method *method;
	IMP oldImplementation;

	objc_global_mutex_lock();

	if ((method = getMethod(class, selector)) != NULL) {
		oldImplementation = method->implementation;
		method->implementation = implementation;
		objc_update_dtable(class);
	} else {
		oldImplementation = NULL;
		addMethod(class, selector, implementation, typeEncoding);
	}

	objc_global_mutex_unlock();

	return oldImplementation;
}

Class
object_getClass(id object_)
{
	struct objc_object *object;

	if (object_ == nil)
		return Nil;

	object = (struct objc_object *)object_;

	return object->isa;
}

Class
object_setClass(id object_, Class class)
{
	struct objc_object *object;
	Class old;

	if (object_ == nil)
		return Nil;

	object = (struct objc_object *)object_;

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
	struct objc_abi_class *rawClass = (struct objc_abi_class *)class;

	if ((class->info & OBJC_CLASS_INFO_SETUP) && class->superclass != Nil &&
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

	if (class->DTable != NULL && class->DTable != emptyDTable)
		objc_dtable_free(class->DTable);

	class->DTable = NULL;

	if ((class->info & OBJC_CLASS_INFO_SETUP) && class->superclass != Nil)
		rawClass->superclass = class->superclass->name;

	class->info &= ~OBJC_CLASS_INFO_SETUP;
}

void
objc_unregister_class(Class class)
{
	static SEL unloadSel = NULL;

	if (unloadSel == NULL)
		unloadSel = sel_registerName("unload");

	while (class->subclassList != NULL && class->subclassList[0] != Nil)
		objc_unregister_class(class->subclassList[0]);

	if (class->info & OBJC_CLASS_INFO_LOADED)
		callSelector(class, unloadSel);

	objc_hashtable_delete(classes, class->name);

	if (strcmp(class_getName(class), "Protocol") != 0)
		classesCount--;

	unregisterClass(class);
	unregisterClass(class->isa);
}

void
objc_unregister_all_classes(void)
{
	if (classes == NULL)
		return;

	for (uint32_t i = 0; i < classes->size; i++) {
		if (classes->data[i] != NULL &&
		    classes->data[i] != &objc_deleted_bucket) {
			void *class = (Class)classes->data[i]->object;

			if (class == Nil || (uintptr_t)class & 1)
				continue;

			objc_unregister_class(class);

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

	OF_ENSURE(classesCount == 0);

	if (emptyDTable != NULL) {
		objc_dtable_free(emptyDTable);
		emptyDTable = NULL;
	}

	objc_sparsearray_free(fastPath);
	fastPath = NULL;

	objc_hashtable_free(classes);
	classes = NULL;
}
