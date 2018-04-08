/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <assert.h>

#import "ObjFW_RT.h"
#import "private.h"

static struct objc_hashtable *classes = NULL;
static unsigned classes_cnt = 0;
static Class *load_queue = NULL;
static size_t load_queue_cnt = 0;
static struct objc_dtable *empty_dtable = NULL;
static unsigned lookups_till_fast_path = 128;
static struct objc_sparsearray *fast_path = NULL;

static void
register_class(struct objc_abi_class *cls)
{
	if (classes == NULL)
		classes = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);

	objc_hashtable_set(classes, cls->name, cls);

	if (empty_dtable == NULL)
		empty_dtable = objc_dtable_new();

	cls->dtable = empty_dtable;
	cls->metaclass->dtable = empty_dtable;

	if (strcmp(cls->name, "Protocol") != 0)
		classes_cnt++;
}

BOOL
class_registerAlias_np(Class cls, const char *name)
{
	if (classes == NULL)
		return NO;

	objc_hashtable_set(classes, name, (Class)((uintptr_t)cls | 1));

	return YES;
}

static void
register_selectors(struct objc_abi_class *cls)
{
	struct objc_abi_method_list *ml;

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			objc_register_selector(
			    (struct objc_abi_selector *)&ml->methods[i]);
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
	if (cache && fast_path != NULL) {
		cls = objc_sparsearray_get(fast_path, (uintptr_t)name);

		if (cls != Nil)
			return cls;
	}

	objc_global_mutex_lock();

	cls = (Class)((uintptr_t)objc_hashtable_get(classes, name) & ~1);

	if (cache && fast_path == NULL && --lookups_till_fast_path == 0)
		fast_path = objc_sparsearray_new(sizeof(uintptr_t));

	if (cache && fast_path != NULL)
		objc_sparsearray_set(fast_path, (uintptr_t)name, cls);

	objc_global_mutex_unlock();

	return cls;
}

static void
call_method(Class cls, const char *method)
{
	SEL selector = sel_registerName(method);

	for (struct objc_method_list *ml = cls->isa->methodlist;
	    ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			if (sel_isEqual((SEL)&ml->methods[i].sel, selector))
				((void (*)(id, SEL))ml->methods[i].imp)(cls,
				    selector);
}

static bool
has_load(Class cls)
{
	SEL selector = sel_registerName("load");

	for (struct objc_method_list *ml = cls->isa->methodlist;
	    ml != NULL; ml = ml->next)
		for (size_t i = 0; i < ml->count; i++)
			if (sel_isEqual((SEL)&ml->methods[i].sel, selector))
				return true;

	return false;
}

static void
call_load(Class cls)
{
	if (cls->info & OBJC_CLASS_INFO_LOADED)
		return;

	if (cls->superclass != Nil)
		call_load(cls->superclass);

	call_method(cls, "load");

	cls->info |= OBJC_CLASS_INFO_LOADED;
}

void
objc_update_dtable(Class cls)
{
	struct objc_method_list *ml;
	struct objc_category **cats;

	if (!(cls->info & OBJC_CLASS_INFO_DTABLE))
		return;

	if (cls->dtable == empty_dtable)
		cls->dtable = objc_dtable_new();

	if (cls->superclass != Nil)
		objc_dtable_copy(cls->dtable, cls->superclass->dtable);

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			objc_dtable_set(cls->dtable,
			    (uint32_t)ml->methods[i].sel.uid,
			    ml->methods[i].imp);

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (unsigned int i = 0; cats[i] != NULL; i++) {
			ml = (cls->info & OBJC_CLASS_INFO_CLASS ?
			    cats[i]->instance_methods : cats[i]->class_methods);

			for (; ml != NULL; ml = ml->next)
				for (unsigned int j = 0; j < ml->count; j++)
					objc_dtable_set(cls->dtable,
					    (uint32_t)ml->methods[j].sel.uid,
					    ml->methods[j].imp);
		}
	}

	if (cls->subclass_list != NULL)
		for (Class *iter = cls->subclass_list; *iter != NULL; iter++)
			objc_update_dtable(*iter);
}

static void
add_subclass(Class cls)
{
	size_t i;

	if (cls->superclass->subclass_list == NULL) {
		if ((cls->superclass->subclass_list =
		    malloc(2 * sizeof(Class))) == NULL)
			OBJC_ERROR("Not enough memory for subclass list of "
			    "class %s!", cls->superclass->name);

		cls->superclass->subclass_list[0] = cls;
		cls->superclass->subclass_list[1] = Nil;

		return;
	}

	for (i = 0; cls->superclass->subclass_list[i] != Nil; i++);

	cls->superclass->subclass_list =
	    realloc(cls->superclass->subclass_list, (i + 2) * sizeof(Class));

	if (cls->superclass->subclass_list == NULL)
		OBJC_ERROR("Not enough memory for subclass list of class %s\n",
		    cls->superclass->name);

	cls->superclass->subclass_list[i] = cls;
	cls->superclass->subclass_list[i + 1] = Nil;
}


static void
update_ivar_offsets(Class cls)
{
	if (!(cls->info & OBJC_CLASS_INFO_NEW_ABI))
		return;

	if (cls->instance_size > 0)
		return;

	cls->instance_size = -cls->instance_size;

	if (cls->superclass != Nil) {
		cls->instance_size += cls->superclass->instance_size;

		if (cls->ivars != NULL) {
			for (unsigned int i = 0; i < cls->ivars->count; i++) {
				cls->ivars->ivars[i].offset +=
				    cls->superclass->instance_size;
				*cls->ivar_offsets[i] =
				    cls->ivars->ivars[i].offset;
			}
		}
	} else
		for (unsigned int i = 0; i < cls->ivars->count; i++)
			*cls->ivar_offsets[i] = cls->ivars->ivars[i].offset;
}

static void
setup_class(Class cls)
{
	const char *superclass;

	if (cls->info & OBJC_CLASS_INFO_SETUP)
		return;

	if ((superclass = ((struct objc_abi_class *)cls)->superclass) != NULL) {
		Class super = objc_classname_to_class(superclass, false);

		if (super == Nil)
			return;

		setup_class(super);

		if (!(super->info & OBJC_CLASS_INFO_SETUP))
			return;

		cls->superclass = super;
		cls->isa->superclass = super->isa;

		add_subclass(cls);
		add_subclass(cls->isa);
	} else
		cls->isa->superclass = cls;

	update_ivar_offsets(cls);

	cls->info |= OBJC_CLASS_INFO_SETUP;
	cls->isa->info |= OBJC_CLASS_INFO_SETUP;
}

static void
initialize_class(Class cls)
{
	if (cls->info & OBJC_CLASS_INFO_INITIALIZED)
		return;

	if (cls->superclass)
		initialize_class(cls->superclass);

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

	call_method(cls, "initialize");
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

	setup_class(cls);

	if (!(cls->info & OBJC_CLASS_INFO_SETUP)) {
		objc_global_mutex_unlock();
		return;
	}

	initialize_class(cls);

	objc_global_mutex_unlock();
}

static void
process_load_queue()
{
	for (size_t i = 0; i < load_queue_cnt; i++) {
		setup_class(load_queue[i]);

		if (load_queue[i]->info & OBJC_CLASS_INFO_SETUP) {
			call_load(load_queue[i]);

			load_queue_cnt--;

			if (load_queue_cnt == 0) {
				free(load_queue);
				load_queue = NULL;
				continue;
			}

			load_queue[i] = load_queue[load_queue_cnt];

			load_queue = realloc(load_queue,
			    sizeof(Class) * load_queue_cnt);

			if (load_queue == NULL)
				OBJC_ERROR("Not enough memory for load queue!");
		}
	}
}

void
objc_register_all_classes(struct objc_abi_symtab *symtab)
{
	for (uint16_t i = 0; i < symtab->cls_def_cnt; i++) {
		struct objc_abi_class *cls =
		    (struct objc_abi_class *)symtab->defs[i];

		register_class(cls);
		register_selectors(cls);
		register_selectors(cls->metaclass);
	}

	for (uint16_t i = 0; i < symtab->cls_def_cnt; i++) {
		Class cls = (Class)symtab->defs[i];

		if (has_load(cls)) {
			setup_class(cls);

			if (cls->info & OBJC_CLASS_INFO_SETUP)
				call_load(cls);
			else {
				load_queue = realloc(load_queue,
				    sizeof(Class) * (load_queue_cnt + 1));

				if (load_queue == NULL)
					OBJC_ERROR("Not enough memory for load "
					    "queue!");

				load_queue[load_queue_cnt++] = cls;
			}
		} else
			cls->info |= OBJC_CLASS_INFO_LOADED;
	}

	process_load_queue();
}

Class
objc_allocateClassPair(Class superclass, const char *name, size_t extra_bytes)
{
	struct objc_class *cls, *metaclass;
	Class iter, rootclass = Nil;

	if (extra_bytes > LONG_MAX)
		OBJC_ERROR("extra_bytes out of range!")

	if ((cls = calloc(1, sizeof(*cls))) == NULL ||
	    (metaclass = calloc(1, sizeof(*cls))) == NULL)
		OBJC_ERROR("Not enough memory to allocate class pair for class "
		    "%s!", name)

	cls->isa = metaclass;
	cls->superclass = superclass;
	cls->name = name;
	cls->info = OBJC_CLASS_INFO_CLASS;
	cls->instance_size = (superclass != Nil ?
	    superclass->instance_size : 0) + (long)extra_bytes;

	for (iter = superclass; iter != Nil; iter = iter->superclass)
		rootclass = iter;

	metaclass->isa = (rootclass != Nil ? rootclass->isa : cls);
	metaclass->superclass = (superclass != Nil ? superclass->isa : Nil);
	metaclass->name = name;
	metaclass->info = OBJC_CLASS_INFO_CLASS;
	metaclass->instance_size = (superclass != Nil ?
	    superclass->isa->instance_size : 0) + (long)extra_bytes;

	return cls;
}

void
objc_registerClassPair(Class cls)
{
	objc_global_mutex_lock();

	register_class((struct objc_abi_class *)cls);

	if (cls->superclass != Nil) {
		add_subclass(cls);
		add_subclass(cls->isa);
	}

	cls->info |= OBJC_CLASS_INFO_SETUP;
	cls->isa->info |= OBJC_CLASS_INFO_SETUP;

	if (has_load(cls))
		call_load(cls);
	else
		cls->info |= OBJC_CLASS_INFO_LOADED;

	process_load_queue();

	objc_global_mutex_unlock();
}

id
objc_lookUpClass(const char *name)
{
	Class cls;

	if ((cls = objc_classname_to_class(name, true)) == NULL)
		return Nil;

	if (cls->info & OBJC_CLASS_INFO_SETUP)
		return cls;

	objc_global_mutex_lock();

	setup_class(cls);

	objc_global_mutex_unlock();

	if (!(cls->info & OBJC_CLASS_INFO_SETUP))
		return Nil;

	return cls;
}

id
objc_getClass(const char *name)
{
	return objc_lookUpClass(name);
}

id
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
objc_getClassList(Class *buf, unsigned int count)
{
	unsigned int j;
	objc_global_mutex_lock();

	if (buf == NULL)
		return classes_cnt;

	if (classes_cnt < count)
		count = classes_cnt;

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

		cls = (Class)classes->data[i]->obj;

		if (cls == Nil || (uintptr_t)cls & 1)
			continue;

		buf[j++] = cls;
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

	if ((ret = malloc((classes_cnt + 1) * sizeof(Class))) == NULL)
		OBJC_ERROR("Failed to allocate memory for class list!");

	count = objc_getClassList(ret, classes_cnt);
	assert(count == classes_cnt);

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

	return cls->instance_size;
}

IMP
class_getMethodImplementation(Class cls, SEL sel)
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
	return objc_msg_lookup((id)&dummy, sel);
}

IMP
class_getMethodImplementation_stret(Class cls, SEL sel)
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
	return objc_msg_lookup_stret((id)&dummy, sel);
}

static struct objc_method *
get_method(Class cls, SEL sel)
{
	struct objc_method_list *ml;
	struct objc_category **cats;

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (; *cats != NULL; cats++) {
			if (cls->info & OBJC_CLASS_INFO_METACLASS)
				ml = (*cats)->class_methods;
			else
				ml = (*cats)->instance_methods;

			for (; ml != NULL; ml = ml->next)
				for (unsigned int i = 0; i < ml->count; i++)
					if (sel_isEqual(
					    (SEL)&ml->methods[i].sel, sel))
						return &ml->methods[i];
		}
	}

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			if (sel_isEqual((SEL)&ml->methods[i].sel, sel))
				return &ml->methods[i];

	return NULL;
}

static void
add_method(Class cls, SEL sel, IMP imp, const char *types)
{
	struct objc_method_list *ml;

	/* FIXME: We need a way to free this at objc_exit() */
	if ((ml = malloc(sizeof(struct objc_method_list))) == NULL)
		OBJC_ERROR("Not enough memory to replace method!");

	ml->next = cls->methodlist;
	ml->count = 1;
	ml->methods[0].sel.uid = sel->uid;
	ml->methods[0].sel.types = types;
	ml->methods[0].imp = imp;

	cls->methodlist = ml;

	objc_update_dtable(cls);
}

const char *
class_getMethodTypeEncoding(Class cls, SEL sel)
{
	struct objc_method *method;

	if (cls == Nil)
		return NULL;

	objc_global_mutex_lock();

	if ((method = get_method(cls, sel)) != NULL) {
		const char *ret = method->sel.types;
		objc_global_mutex_unlock();
		return ret;
	}

	objc_global_mutex_unlock();

	if (cls->superclass != Nil)
		return class_getMethodTypeEncoding(cls->superclass, sel);

	return NULL;
}

bool
class_addMethod(Class cls, SEL sel, IMP imp, const char *types)
{
	bool ret;

	objc_global_mutex_lock();

	if (get_method(cls, sel) == NULL) {
		add_method(cls, sel, imp, types);
		ret = true;
	} else
		ret = false;

	objc_global_mutex_unlock();

	return ret;
}

IMP
class_replaceMethod(Class cls, SEL sel, IMP newimp, const char *types)
{
	struct objc_method *method;
	IMP oldimp;

	objc_global_mutex_lock();

	if ((method = get_method(cls, sel)) != NULL) {
		oldimp = method->imp;
		method->imp = newimp;
		objc_update_dtable(cls);
	} else {
		oldimp = NULL;
		add_method(cls, sel, newimp, types);
	}

	objc_global_mutex_unlock();

	return oldimp;
}

Class
object_getClass(id obj_)
{
	struct objc_object *obj;

	if (obj_ == nil)
		return Nil;

	obj = (struct objc_object *)obj_;

	return obj->isa;
}

Class
object_setClass(id obj_, Class cls)
{
	struct objc_object *obj;
	Class old;

	if (obj_ == nil)
		return Nil;

	obj = (struct objc_object *)obj_;

	old = obj->isa;
	obj->isa = cls;

	return old;
}

const char *
object_getClassName(id obj)
{
	return class_getName(object_getClass(obj));
}

static void
unregister_class(Class rcls)
{
	struct objc_abi_class *cls = (struct objc_abi_class *)rcls;

	if ((rcls->info & OBJC_CLASS_INFO_SETUP) &&
	    rcls->superclass != Nil &&
	    rcls->superclass->subclass_list != NULL) {
		size_t i = SIZE_MAX, count = 0;
		Class *tmp;

		for (tmp = rcls->superclass->subclass_list;
		    *tmp != Nil; tmp++) {
			if (*tmp == rcls)
				i = count;

			count++;
		}

		if (count > 0 && i < SIZE_MAX) {
			tmp = rcls->superclass->subclass_list;
			tmp[i] = tmp[count - 1];
			tmp[count - 1] = NULL;

			if ((tmp = realloc(rcls->superclass->subclass_list,
			    count * sizeof(Class))) != NULL)
				rcls->superclass->subclass_list = tmp;
		}
	}

	if (rcls->subclass_list != NULL) {
		free(rcls->subclass_list);
		rcls->subclass_list = NULL;
	}

	if (rcls->dtable != NULL && rcls->dtable != empty_dtable)
		objc_dtable_free(rcls->dtable);

	rcls->dtable = NULL;

	if ((rcls->info & OBJC_CLASS_INFO_SETUP) && rcls->superclass != Nil)
		cls->superclass = rcls->superclass->name;

	rcls->info &= ~OBJC_CLASS_INFO_SETUP;
}

void
objc_unregister_class(Class cls)
{
	while (cls->subclass_list != NULL && cls->subclass_list[0] != Nil)
		objc_unregister_class(cls->subclass_list[0]);

	if (cls->info & OBJC_CLASS_INFO_LOADED)
		call_method(cls, "unload");

	objc_hashtable_delete(classes, cls->name);

	if (strcmp(class_getName(cls), "Protocol") != 0)
		classes_cnt--;

	unregister_class(cls);
	unregister_class(cls->isa);
}

void
objc_unregister_all_classes(void)
{
	if (classes == NULL)
		return;

	for (uint32_t i = 0; i < classes->size; i++) {
		if (classes->data[i] != NULL &&
		    classes->data[i] != &objc_deleted_bucket) {
			void *cls = (Class)classes->data[i]->obj;

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

	assert(classes_cnt == 0);

	if (empty_dtable != NULL) {
		objc_dtable_free(empty_dtable);
		empty_dtable = NULL;
	}

	objc_sparsearray_free(fast_path);
	fast_path = NULL;

	objc_hashtable_free(classes);
	classes = NULL;
}
