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

#import "ObjFW_RT.h"
#import "private.h"

static struct objc_hashtable *categories = NULL;

static void
register_selectors(struct objc_abi_category *cat)
{
	for (struct objc_abi_method_list *ml = cat->instance_methods;
	    ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			objc_register_selector(
			    (struct objc_abi_selector *)&ml->methods[i]);

	for (struct objc_abi_method_list *ml = cat->class_methods;
	    ml != NULL; ml = ml->next)
		for (unsigned int i = 0; i < ml->count; i++)
			objc_register_selector(
			    (struct objc_abi_selector *)&ml->methods[i]);
}

static void
register_category(struct objc_abi_category *cat)
{
	struct objc_abi_category **cats;
	Class cls = objc_classname_to_class(cat->class_name, false);

	if (categories == NULL)
		categories = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);

	cats = (struct objc_abi_category **)objc_hashtable_get(categories,
	    cat->class_name);

	if (cats != NULL) {
		struct objc_abi_category **ncats;
		size_t i;

		for (i = 0; cats[i] != NULL; i++);

		if ((ncats = realloc(cats,
		    (i + 2) * sizeof(struct objc_abi_category *))) == NULL)
			OBJC_ERROR("Not enough memory for category %s of "
			    "class %s!", cat->category_name, cat->class_name);

		ncats[i] = cat;
		ncats[i + 1] = NULL;
		objc_hashtable_set(categories, cat->class_name, ncats);

		if (cls != Nil && cls->info & OBJC_CLASS_INFO_SETUP) {
			objc_update_dtable(cls);
			objc_update_dtable(cls->isa);
		}

		return;
	}

	if ((cats = malloc(2 * sizeof(struct objc_abi_category *))) == NULL)
		OBJC_ERROR("Not enough memory for category %s of class %s!\n",
		    cat->category_name, cat->class_name);

	cats[0] = cat;
	cats[1] = NULL;
	objc_hashtable_set(categories, cat->class_name, cats);

	if (cls != Nil && cls->info & OBJC_CLASS_INFO_SETUP) {
		objc_update_dtable(cls);
		objc_update_dtable(cls->isa);
	}
}

void
objc_register_all_categories(struct objc_abi_symtab *symtab)
{
	struct objc_abi_category **cats =
	    (struct objc_abi_category **)symtab->defs + symtab->cls_def_cnt;

	for (size_t i = 0; i < symtab->cat_def_cnt; i++) {
		register_selectors(cats[i]);
		register_category(cats[i]);
	}
}

struct objc_category **
objc_categories_for_class(Class cls)
{
	if (categories == NULL)
		return NULL;

	return (struct objc_category **)objc_hashtable_get(categories,
	    cls->name);
}

void
objc_unregister_all_categories(void)
{
	if (categories == NULL)
		return;

	for (uint32_t i = 0; i < categories->size; i++)
		if (categories->data[i] != NULL)
			free((void *)categories->data[i]->obj);

	objc_hashtable_free(categories);
	categories = NULL;
}
