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

#import "ObjFW_RT.h"
#import "private.h"

static struct objc_hashtable *classes = NULL;
static unsigned classesCount = 0;
static Class *loadQueue = NULL;
static size_t loadQueueCount = 0;
static struct objc_dtable *emptyDTable = NULL;
static unsigned lookupsUntilFastPath = 128;
static struct objc_sparsearray *fastPath = NULL;

static void
registerClass(struct objc_abi_class *cls)
{
	if (classes == NULL)
		classes = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);

	objc_hashtable_set(classes, cls->name, cls);

	if (emptyDTable == NULL)
		emptyDTable = objc_dtable_new();

	cls->DTable = emptyDTable;
	cls->metaclass->DTable = emptyDTable;

	if (strcmp(cls->name, "Protocol") != 0)
		classesCount++;
}

bool
class_registerAlias_np(Class cls, const char *name)
{
	objc_global_mutex_lock();

	if (classes == NULL) {
		objc_global_mutex_unlock();

		return NO;
	}

	objc_hashtable_set(classes, name, (Class)((uintptr_t)cls | 1));

	objc_global_mutex_unlock();

	return YES;
}

static void
registerSelectors(struct objc_abi_class *cls)
{
	struct objc_abi_method_list *methodList;

	for (methodList = cls->methodList; methodList != NULL;
	    methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_register_selector((struct objc_abi_selector *)
			    &methodList->methods[i]);
}

Class
objc_classname_to_class(const char *name, bool cache)
{
	Class cls;

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
		cls = objc_sparsearray_get(fastPath, (uintptr_t)name);

		if (cls != Nil)
			return cls;
	}

	objc_global_mutex_lock();

	cls = (Class)((uintptr_t)objc_hashtable_get(classes, name) & ~1);

	if (cache && fastPath == NULL && --lookupsUntilFastPath == 0)
		fastPath = objc_sparsearray_new(sizeof(uintptr_t));

	if (cache && fastPath != NULL)
		objc_sparsearray_set(fastPath, (uintptr_t)name, cls);

	objc_global_mutex_unlock();

	return cls;
}

static void
callMethod(Class cls, const char *method)
{
	SEL selector = sel_registerName(method);

	for (struct objc_method_list *methodList = cls->isa->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    selector))
				((void (*)(id, SEL))methodList->methods[i]
				    .implementation)(cls, selector);
}

static bool
hasLoad(Class cls)
{
	SEL selector = sel_registerName("load");

	for (struct objc_method_list *methodList = cls->isa->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (size_t i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    selector))
				return true;

	return false;
}

static void
callLoad(Class cls)
{
	if (cls->info & OBJC_CLASS_INFO_LOADED)
		return;

	if (cls->superclass != Nil)
		callLoad(cls->superclass);

	callMethod(cls, "load");

	cls->info |= OBJC_CLASS_INFO_LOADED;
}

void
objc_update_dtable(Class cls)
{
	struct objc_category **categories;

	if (!(cls->info & OBJC_CLASS_INFO_DTABLE))
		return;

	if (cls->DTable == emptyDTable)
		cls->DTable = objc_dtable_new();

	if (cls->superclass != Nil)
		objc_dtable_copy(cls->DTable, cls->superclass->DTable);

	for (struct objc_method_list *methodList = cls->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_dtable_set(cls->DTable,
			    (uint32_t)methodList->methods[i].selector.UID,
			    methodList->methods[i].implementation);

	if ((categories = objc_categories_for_class(cls)) != NULL) {
		for (unsigned int i = 0; categories[i] != NULL; i++) {
			struct objc_method_list *methodList =
			    (cls->info & OBJC_CLASS_INFO_CLASS
			    ? categories[i]->instanceMethods
			    : categories[i]->classMethods);

			for (; methodList != NULL;
			    methodList = methodList->next)
				for (unsigned int j = 0;
				    j < methodList->count; j++)
					objc_dtable_set(cls->DTable, (uint32_t)
					    methodList->methods[j].selector.UID,
					    methodList->methods[j]
					    .implementation);
		}
	}

	if (cls->subclassList != NULL)
		for (Class *iter = cls->subclassList; *iter != NULL; iter++)
			objc_update_dtable(*iter);
}

static void
addSubclass(Class cls)
{
	size_t i;

	if (cls->superclass->subclassList == NULL) {
		if ((cls->superclass->subclassList =
		    malloc(2 * sizeof(Class))) == NULL)
			OBJC_ERROR("Not enough memory for subclass list of "
			    "class %s!", cls->superclass->name);

		cls->superclass->subclassList[0] = cls;
		cls->superclass->subclassList[1] = Nil;

		return;
	}

	for (i = 0; cls->superclass->subclassList[i] != Nil; i++);

	cls->superclass->subclassList =
	    realloc(cls->superclass->subclassList, (i + 2) * sizeof(Class));

	if (cls->superclass->subclassList == NULL)
		OBJC_ERROR("Not enough memory for subclass list of class %s\n",
		    cls->superclass->name);

	cls->superclass->subclassList[i] = cls;
	cls->superclass->subclassList[i + 1] = Nil;
}


static void
updateIVarOffsets(Class cls)
{
	if (!(cls->info & OBJC_CLASS_INFO_NEW_ABI))
		return;

	if (cls->instanceSize > 0)
		return;

	cls->instanceSize = -cls->instanceSize;

	if (cls->superclass != Nil) {
		cls->instanceSize += cls->superclass->instanceSize;

		if (cls->iVars != NULL) {
			for (unsigned int i = 0; i < cls->iVars->count; i++) {
				cls->iVars->iVars[i].offset +=
				    cls->superclass->instanceSize;
				*cls->iVarOffsets[i] =
				    cls->iVars->iVars[i].offset;
			}
		}
	} else
		for (unsigned int i = 0; i < cls->iVars->count; i++)
			*cls->iVarOffsets[i] = cls->iVars->iVars[i].offset;
}

static void
setupClass(Class cls)
{
	const char *superclass;

	if (cls->info & OBJC_CLASS_INFO_SETUP)
		return;

	if ((superclass = ((struct objc_abi_class *)cls)->superclass) != NULL) {
		Class super = objc_classname_to_class(superclass, false);

		if (super == Nil)
			return;

		setupClass(super);

		if (!(super->info & OBJC_CLASS_INFO_SETUP))
			return;

		cls->superclass = super;
		cls->isa->superclass = super->isa;

		addSubclass(cls);
		addSubclass(cls->isa);
	} else
		cls->isa->superclass = cls;

	updateIVarOffsets(cls);

	cls->info |= OBJC_CLASS_INFO_SETUP;
	cls->isa->info |= OBJC_CLASS_INFO_SETUP;
}

static void
initializeClass(Class cls)
{
	if (cls->info & OBJC_CLASS_INFO_INITIALIZED)
		return;

	if (cls->superclass)
		initializeClass(cls->superclass);

	cls->info |= OBJC_CLASS_INFO_DTABLE;
	cls->isa->info |= OBJC_CLASS_INFO_DTABLE;

	objc_update_dtable(cls);
	objc_update_dtable(cls->isa);

	/*
	 * Set it first to prevent calling it recursively due to message sends
	 * in the initialize method
	 */
	cls->info |= OBJC_CLASS_INFO_INITIALIZED;
	cls->isa->info |= OBJC_CLASS_INFO_INITIALIZED;

	callMethod(cls, "initialize");
}

void
objc_initialize_class(Class cls)
{
	if (cls->info & OBJC_CLASS_INFO_INITIALIZED)
		return;

	objc_global_mutex_lock();

	/*
	 * It's possible that two threads try to initialize a class at the same
	 * time. Make sure that the thread which held the lock did not already
	 * initialize it.
	 */
	if (cls->info & OBJC_CLASS_INFO_INITIALIZED) {
		objc_global_mutex_unlock();
		return;
	}

	setupClass(cls);

	if (!(cls->info & OBJC_CLASS_INFO_SETUP)) {
		objc_global_mutex_unlock();
		return;
	}

	initializeClass(cls);

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
		struct objc_abi_class *cls =
		    (struct objc_abi_class *)symtab->defs[i];

		registerClass(cls);
		registerSelectors(cls);
		registerSelectors(cls->metaclass);
	}

	for (uint16_t i = 0; i < symtab->classDefsCount; i++) {
		Class cls = (Class)symtab->defs[i];

		if (hasLoad(cls)) {
			setupClass(cls);

			if (cls->info & OBJC_CLASS_INFO_SETUP)
				callLoad(cls);
			else {
				loadQueue = realloc(loadQueue,
				    sizeof(Class) * (loadQueueCount + 1));

				if (loadQueue == NULL)
					OBJC_ERROR("Not enough memory for load "
					    "queue!");

				loadQueue[loadQueueCount++] = cls;
			}
		} else
			cls->info |= OBJC_CLASS_INFO_LOADED;
	}

	processLoadQueue();
}

Class
objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
{
	struct objc_class *cls, *metaclass;
	Class iter, rootclass = Nil;

	if (extraBytes > LONG_MAX)
		OBJC_ERROR("extra_bytes out of range!")

	if ((cls = calloc(1, sizeof(*cls))) == NULL ||
	    (metaclass = calloc(1, sizeof(*cls))) == NULL)
		OBJC_ERROR("Not enough memory to allocate class pair for class "
		    "%s!", name)

	cls->isa = metaclass;
	cls->superclass = superclass;
	cls->name = name;
	cls->info = OBJC_CLASS_INFO_CLASS;
	cls->instanceSize = (superclass != Nil ?
	    superclass->instanceSize : 0) + (long)extraBytes;

	for (iter = superclass; iter != Nil; iter = iter->superclass)
		rootclass = iter;

	metaclass->isa = (rootclass != Nil ? rootclass->isa : cls);
	metaclass->superclass = (superclass != Nil ? superclass->isa : Nil);
	metaclass->name = name;
	metaclass->info = OBJC_CLASS_INFO_CLASS;
	metaclass->instanceSize = (superclass != Nil ?
	    superclass->isa->instanceSize : 0) + (long)extraBytes;

	return cls;
}

void
objc_registerClassPair(Class cls)
{
	objc_global_mutex_lock();

	registerClass((struct objc_abi_class *)cls);

	if (cls->superclass != Nil) {
		addSubclass(cls);
		addSubclass(cls->isa);
	}

	cls->info |= OBJC_CLASS_INFO_SETUP;
	cls->isa->info |= OBJC_CLASS_INFO_SETUP;

	if (hasLoad(cls))
		callLoad(cls);
	else
		cls->info |= OBJC_CLASS_INFO_LOADED;

	processLoadQueue();

	objc_global_mutex_unlock();
}

Class
objc_lookUpClass(const char *name)
{
	Class cls;

	if ((cls = objc_classname_to_class(name, true)) == NULL)
		return Nil;

	if (cls->info & OBJC_CLASS_INFO_SETUP)
		return cls;

	objc_global_mutex_lock();

	setupClass(cls);

	objc_global_mutex_unlock();

	if (!(cls->info & OBJC_CLASS_INFO_SETUP))
		return Nil;

	return cls;
}

Class
objc_getClass(const char *name)
{
	return objc_lookUpClass(name);
}

Class
objc_getRequiredClass(const char *name)
{
	Class cls;

	if ((cls = objc_getClass(name)) == Nil)
		OBJC_ERROR("Class %s not found!", name);

	return cls;
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
		void *cls;

		if (j >= count) {
			objc_global_mutex_unlock();
			return j;
		}

		if (classes->data[i] == NULL)
			continue;

		if (strcmp(classes->data[i]->key, "Protocol") == 0)
			continue;

		cls = (Class)classes->data[i]->object;

		if (cls == Nil || (uintptr_t)cls & 1)
			continue;

		buffer[j++] = cls;
	}

	objc_global_mutex_unlock();

	return j;
}

Class *
objc_copyClassList(unsigned int *len)
{
	Class *ret;
	unsigned int count;

	objc_global_mutex_lock();

	if ((ret = malloc((classesCount + 1) * sizeof(Class))) == NULL)
		OBJC_ERROR("Failed to allocate memory for class list!");

	count = objc_getClassList(ret, classesCount);
	OF_ENSURE(count == classesCount);

	ret[count] = Nil;

	if (len != NULL)
		*len = count;

	objc_global_mutex_unlock();

	return ret;
}

bool
class_isMetaClass(Class cls)
{
	if (cls == Nil)
		return false;

	return (cls->info & OBJC_CLASS_INFO_METACLASS);
}

const char *
class_getName(Class cls)
{
	if (cls == Nil)
		return "";

	return cls->name;
}

Class
class_getSuperclass(Class cls)
{
	if (cls == Nil)
		return Nil;

	return cls->superclass;
}

unsigned long
class_getInstanceSize(Class cls)
{
	if (cls == Nil)
		return 0;

	return cls->instanceSize;
}

IMP
class_getMethodImplementation(Class cls, SEL selector)
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

	if (cls == Nil)
		return NULL;

	dummy.isa = cls;
	return objc_msg_lookup((id)&dummy, selector);
}

IMP
class_getMethodImplementation_stret(Class cls, SEL selector)
{
	/*
	 * Same as above, but use objc_msg_lookup_stret instead, so that the
	 * correct forwarding handler is returned.
	 */
	struct {
		Class isa;
	} dummy;

	if (cls == Nil)
		return NULL;

	dummy.isa = cls;
	return objc_msg_lookup_stret((id)&dummy, selector);
}

static struct objc_method *
getMethod(Class cls, SEL selector)
{
	struct objc_category **categories;

	if ((categories = objc_categories_for_class(cls)) != NULL) {
		for (; *categories != NULL; categories++) {
			struct objc_method_list *methodList =
			    (cls->info & OBJC_CLASS_INFO_METACLASS
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

	for (struct objc_method_list *methodList = cls->methodList;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    selector))
				return &methodList->methods[i];

	return NULL;
}

static void
addMethod(Class cls, SEL selector, IMP implementation, const char *typeEncoding)
{
	struct objc_method_list *methodList;

	/* FIXME: We need a way to free this at objc_exit() */
	if ((methodList = malloc(sizeof(struct objc_method_list))) == NULL)
		OBJC_ERROR("Not enough memory to replace method!");

	methodList->next = cls->methodList;
	methodList->count = 1;
	methodList->methods[0].selector.UID = selector->UID;
	methodList->methods[0].selector.typeEncoding = typeEncoding;
	methodList->methods[0].implementation = implementation;

	cls->methodList = methodList;

	objc_update_dtable(cls);
}

const char *
class_getMethodTypeEncoding(Class cls, SEL selector)
{
	struct objc_method *method;

	if (cls == Nil)
		return NULL;

	objc_global_mutex_lock();

	if ((method = getMethod(cls, selector)) != NULL) {
		const char *ret = method->selector.typeEncoding;
		objc_global_mutex_unlock();
		return ret;
	}

	objc_global_mutex_unlock();

	if (cls->superclass != Nil)
		return class_getMethodTypeEncoding(cls->superclass, selector);

	return NULL;
}

bool
class_addMethod(Class cls, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	bool ret;

	objc_global_mutex_lock();

	if (getMethod(cls, selector) == NULL) {
		addMethod(cls, selector, implementation, typeEncoding);
		ret = true;
	} else
		ret = false;

	objc_global_mutex_unlock();

	return ret;
}

IMP
class_replaceMethod(Class cls, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	struct objc_method *method;
	IMP oldImplementation;

	objc_global_mutex_lock();

	if ((method = getMethod(cls, selector)) != NULL) {
		oldImplementation = method->implementation;
		method->implementation = implementation;
		objc_update_dtable(cls);
	} else {
		oldImplementation = NULL;
		addMethod(cls, selector, implementation, typeEncoding);
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
object_setClass(id object_, Class cls)
{
	struct objc_object *object;
	Class old;

	if (object_ == nil)
		return Nil;

	object = (struct objc_object *)object_;

	old = object->isa;
	object->isa = cls;

	return old;
}

const char *
object_getClassName(id obj)
{
	return class_getName(object_getClass(obj));
}

static void
unregisterClass(Class rcls)
{
	struct objc_abi_class *cls = (struct objc_abi_class *)rcls;

	if ((rcls->info & OBJC_CLASS_INFO_SETUP) && rcls->superclass != Nil &&
	    rcls->superclass->subclassList != NULL) {
		size_t i = SIZE_MAX, count = 0;
		Class *tmp;

		for (tmp = rcls->superclass->subclassList;
		    *tmp != Nil; tmp++) {
			if (*tmp == rcls)
				i = count;

			count++;
		}

		if (count > 0 && i < SIZE_MAX) {
			tmp = rcls->superclass->subclassList;
			tmp[i] = tmp[count - 1];
			tmp[count - 1] = NULL;

			if ((tmp = realloc(rcls->superclass->subclassList,
			    count * sizeof(Class))) != NULL)
				rcls->superclass->subclassList = tmp;
		}
	}

	if (rcls->subclassList != NULL) {
		free(rcls->subclassList);
		rcls->subclassList = NULL;
	}

	if (rcls->DTable != NULL && rcls->DTable != emptyDTable)
		objc_dtable_free(rcls->DTable);

	rcls->DTable = NULL;

	if ((rcls->info & OBJC_CLASS_INFO_SETUP) && rcls->superclass != Nil)
		cls->superclass = rcls->superclass->name;

	rcls->info &= ~OBJC_CLASS_INFO_SETUP;
}

void
objc_unregister_class(Class cls)
{
	while (cls->subclassList != NULL && cls->subclassList[0] != Nil)
		objc_unregister_class(cls->subclassList[0]);

	if (cls->info & OBJC_CLASS_INFO_LOADED)
		callMethod(cls, "unload");

	objc_hashtable_delete(classes, cls->name);

	if (strcmp(class_getName(cls), "Protocol") != 0)
		classesCount--;

	unregisterClass(cls);
	unregisterClass(cls->isa);
}

void
objc_unregister_all_classes(void)
{
	if (classes == NULL)
		return;

	for (uint32_t i = 0; i < classes->size; i++) {
		if (classes->data[i] != NULL &&
		    classes->data[i] != &objc_deleted_bucket) {
			void *cls = (Class)classes->data[i]->object;

			if (cls == Nil || (uintptr_t)cls & 1)
				continue;

			objc_unregister_class(cls);

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
