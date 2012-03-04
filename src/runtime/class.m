/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <assert.h>

#import "runtime.h"
#import "runtime-private.h"

@protocol BasicClass
+ (void)load;
+ (void)initialize;
@end

static struct objc_hashtable *classes = NULL;

static void
register_class(Class cls)
{
	if (classes == NULL)
		classes = objc_hashtable_alloc(2);

	objc_hashtable_set(classes, cls->name, cls);
}

static void
register_selectors(struct objc_abi_class *cls)
{
	struct objc_abi_method_list *ml;
	unsigned int i;

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (i = 0; i < ml->count; i++)
			objc_register_selector(
			    (struct objc_abi_selector*)&ml->methods[i]);
}

static BOOL
has_load(struct objc_abi_class *cls)
{
	struct objc_abi_method_list *ml;
	unsigned int i;

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (i = 0; i < ml->count; i++)
			if (!strcmp(ml->methods[i].name, "load"))
				return YES;

	return NO;
}

void
objc_update_dtable(Class cls)
{
	struct objc_abi_method_list *ml;
	struct objc_abi_category **cats;
	struct objc_sparsearray *dtable;
	unsigned int i;

	if (cls->superclass != Nil)
		dtable = objc_sparsearray_copy(cls->superclass->dtable);
	else
		dtable = objc_sparsearray_new();

	for (ml = cls->methodlist; ml != NULL; ml = ml->next)
		for (i = 0; i < ml->count; i++)
			objc_sparsearray_set(dtable, (uint32_t)
			    (uintptr_t)ml->methods[i].name, ml->methods[i].imp);

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (i = 0; cats[i] != NULL; i++) {
			unsigned int j;

			ml = (cls->info & OBJC_CLASS_INFO_CLASS ?
			    cats[i]->instance_methods : cats[i]->class_methods);

			for (; ml != NULL; ml = ml->next)
				for (j = 0; j < ml->count; j++)
					objc_sparsearray_set(dtable, (uint32_t)
					    (uintptr_t)ml->methods[j].name,
					    ml->methods[j].imp);
		}
	}

	if (cls->dtable != NULL)
		objc_sparsearray_free_when_singlethreaded(cls->dtable);

	cls->dtable = dtable;

	if (cls->subclass_list != NULL)
		for (i = 0; cls->subclass_list[i] != NULL; i++)
			objc_update_dtable(cls->subclass_list[i]);
}

void
objc_register_all_classes(struct objc_abi_symtab *symtab)
{
	size_t i;

	for (i = 0; i < symtab->cls_def_cnt; i++)
		register_class((Class)symtab->defs[i]);

	for (i = 0; i < symtab->cls_def_cnt; i++) {
		struct objc_abi_class *cls;
		BOOL load;

		cls = (struct objc_abi_class*)symtab->defs[i];
		load = has_load(cls->metaclass);

		register_selectors(cls);
		register_selectors(cls->metaclass);

		if (load) {
			/* Sets up the dtable */
			assert(objc_get_class(cls->name) == (Class)cls);

			[(Class)cls load];
		}
	}
}

static void
add_subclass(Class cls)
{
	size_t i;

	if (cls->superclass->subclass_list == NULL) {
		if ((cls->superclass->subclass_list =
		    malloc(2 * sizeof(Class))) == NULL)
			ERROR("Not enough memory for subclass list of "
			    "class %s!", cls->superclass->name);

		cls->superclass->subclass_list[0] = cls;
		cls->superclass->subclass_list[1] = Nil;

		return;
	}

	for (i = 0; cls->superclass->subclass_list[i] != Nil; i++);

	cls->superclass->subclass_list =
	    realloc(cls->superclass->subclass_list, (i + 2) * sizeof(Class));

	if (cls->superclass->subclass_list == NULL)
		ERROR("Not enough memory for subclass list of class %s\n",
		    cls->superclass->name);

	cls->superclass->subclass_list[i] = cls;
	cls->superclass->subclass_list[i + 1] = Nil;
}

inline Class
objc_classname_to_class(const char *name)
{
	Class c;

	if (classes == NULL)
		return Nil;

	objc_global_mutex_lock();
	c = (Class)objc_hashtable_get(classes, name);
	objc_global_mutex_unlock();

	return c;
}

inline Class
objc_lookup_class(const char *name)
{
	Class cls = objc_classname_to_class(name);
	const char *superclass;

	if (cls == NULL)
		return Nil;

	if (cls->info & OBJC_CLASS_INFO_INITIALIZED)
		return cls;

	objc_global_mutex_lock();

	/*
	 * It's possible that two threads try to get a class at the same time.
	 * Make sure that the thread which held the lock did not already
	 * initialize it.
	 */
	if (cls->info & OBJC_CLASS_INFO_INITIALIZED) {
		objc_global_mutex_unlock();
		return cls;
	}

	if ((superclass = ((struct objc_abi_class*)cls)->superclass) != NULL) {
		if ((cls->superclass = objc_lookup_class(superclass)) == Nil)
			ERROR("Class %s not found, which is the superclass for "
			    "class %s!", superclass, cls->name);

		cls->isa->superclass = cls->superclass->isa;

		add_subclass(cls);
		add_subclass(cls->isa);
	} else if ((superclass = ((struct objc_abi_class*)cls->isa)->superclass)
	    != NULL) {
		if (strcmp(superclass, name))
			abort();

		cls->isa->superclass = cls;
	}

	objc_update_dtable(cls);
	objc_update_dtable(cls->isa);

	cls->info |= OBJC_CLASS_INFO_INITIALIZED;
	cls->isa->info |= OBJC_CLASS_INFO_INITIALIZED;

	if (class_respondsToSelector(cls->isa, @selector(initialize)))
		[cls initialize];

	objc_global_mutex_unlock();

	return cls;
}

Class
objc_get_class(const char *name)
{
	Class cls;

	if ((cls = objc_lookup_class(name)) == Nil)
		ERROR("Class %s not found!", name);

	return cls;
}

const char*
class_getName(Class cls)
{
	return cls->name;
}

Class
class_getSuperclass(Class cls)
{
	return cls->superclass;
}

BOOL
class_isKindOfClass(Class cls1, Class cls2)
{
	Class iter;

	for (iter = cls1; iter != Nil; iter = iter->superclass)
		if (iter == cls2)
			return YES;

	return NO;
}

unsigned long
class_getInstanceSize(Class cls)
{
	return cls->instance_size;
}

IMP
objc_get_class_method(Class cls, SEL sel)
{
	return objc_sparsearray_get(cls->isa->dtable, (uint32_t)sel->uid);
}

IMP
objc_get_instance_method(Class cls, SEL sel)
{
	return objc_sparsearray_get(cls->dtable, (uint32_t)sel->uid);
}

const char*
objc_get_type_encoding(Class cls, SEL sel)
{
	struct objc_abi_method_list *ml;
	struct objc_abi_category **cats;
	unsigned int i;

	objc_global_mutex_lock();

	for (ml = cls->isa->methodlist; ml != NULL; ml = ml->next) {
		for (i = 0; i < ml->count; i++) {
			if ((uintptr_t)ml->methods[i].name == sel->uid) {
				const char *ret = ml->methods[i].types;
				objc_global_mutex_unlock();
				return ret;
			}
		}
	}

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (; *cats != NULL; cats++) {
			for (ml = (*cats)->class_methods; ml != NULL;
			    ml = ml->next) {
				for (i = 0; i < ml->count; i++) {
					if ((uintptr_t)ml->methods[i].name ==
					    sel->uid) {
						const char *ret =
						    ml->methods[i].types;
						objc_global_mutex_unlock();
						return ret;
					}
				}
			}
		}
	}

	objc_global_mutex_unlock();

	return NULL;
}

IMP
objc_replace_class_method(Class cls, SEL sel, IMP newimp)
{
	struct objc_abi_method_list *ml;
	struct objc_abi_category **cats;
	unsigned int i;
	BOOL replaced = NO;
	IMP oldimp = NULL;

	objc_global_mutex_lock();

	for (ml = cls->isa->methodlist; ml != NULL; ml = ml->next) {
		for (i = 0; i < ml->count; i++) {
			if ((uintptr_t)ml->methods[i].name == sel->uid) {
				oldimp = ml->methods[i].imp;
				ml->methods[i].imp = newimp;
				replaced = YES;
				break;
			}
		}
	}

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (; *cats != NULL; cats++) {
			for (ml = (*cats)->class_methods; ml != NULL;
			    ml = ml->next) {
				for (i = 0; i < ml->count; i++) {
					if ((uintptr_t)ml->methods[i].name ==
					    sel->uid) {
						oldimp = ml->methods[i].imp;
						ml->methods[i].imp = newimp;
						replaced = YES;
						break;
					}
				}
			}
		}
	}

	if (!replaced) {
		/* FIXME: We need a way to free this at objc_exit() */
		if ((ml = malloc(sizeof(struct objc_abi_method_list))) == NULL)
			ERROR("Not enough memory to replace method!");

		ml->next = cls->isa->methodlist;
		ml->count = 1;
		ml->methods[0].name = (const char*)sel->uid;
		/* FIXME: We need to get the type from a superclass */
		ml->methods[0].types = sel->types;
		ml->methods[0].imp = newimp;

		cls->isa->methodlist = ml;
	}

	objc_update_dtable(cls->isa);

	objc_global_mutex_unlock();

	return oldimp;
}

IMP
objc_replace_instance_method(Class cls, SEL sel, IMP newimp)
{
	struct objc_abi_method_list *ml;
	struct objc_abi_category **cats;
	unsigned int i;
	BOOL replaced = NO;
	IMP oldimp = NULL;

	objc_global_mutex_lock();

	for (ml = cls->methodlist; ml != NULL; ml = ml->next) {
		for (i = 0; i < ml->count; i++) {
			if ((uintptr_t)ml->methods[i].name == sel->uid) {
				oldimp = ml->methods[i].imp;
				ml->methods[i].imp = newimp;
				replaced = YES;
				break;
			}
		}
	}

	if ((cats = objc_categories_for_class(cls)) != NULL) {
		for (; *cats != NULL; cats++) {
			for (ml = (*cats)->instance_methods; ml != NULL;
			    ml = ml->next) {
				for (i = 0; i < ml->count; i++) {
					if ((uintptr_t)ml->methods[i].name ==
					    sel->uid) {
						oldimp = ml->methods[i].imp;
						ml->methods[i].imp = newimp;
						replaced = YES;
						break;
					}
				}
			}
		}
	}

	if (!replaced) {
		/* FIXME: We need a way to free this at objc_exit() */
		if ((ml = malloc(sizeof(struct objc_abi_method_list))) == NULL)
			ERROR("Not enough memory to replace method!");

		ml->next = cls->methodlist;
		ml->count = 1;
		ml->methods[0].name = (const char*)sel->uid;
		/* FIXME: We need to get the type from a superclass */
		ml->methods[0].types = sel->types;
		ml->methods[0].imp = newimp;

		cls->methodlist = ml;
	}

	objc_update_dtable(cls);

	objc_global_mutex_unlock();

	return oldimp;
}

static void
free_class(Class rcls)
{
	struct objc_abi_class *cls = (struct objc_abi_class*)rcls;

	if (!(rcls->info & OBJC_CLASS_INFO_INITIALIZED))
		return;

	if (rcls->subclass_list != NULL) {
		free(rcls->subclass_list);
		rcls->subclass_list = NULL;
	}

	objc_sparsearray_free(rcls->dtable);
	rcls->dtable = NULL;

	if (rcls->superclass != Nil)
		cls->superclass = rcls->superclass->name;
}

void
objc_free_all_classes(void)
{
	uint32_t i;

	if (classes == NULL)
		return;

	for (i = 0; i <= classes->last_idx; i++) {
		if (classes->data[i] != NULL) {
			free_class((Class)classes->data[i]->obj);
			free_class(((Class)classes->data[i]->obj)->isa);
		}
	}

	objc_hashtable_free(classes);
	classes = NULL;
}
