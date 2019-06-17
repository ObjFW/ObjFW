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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_hashtable *categoriesMap = NULL;

static void
registerSelectors(struct objc_abi_category *category)
{
	for (struct objc_abi_method_list *methodList =
	    category->instanceMethods; methodList != NULL;
	    methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_register_selector((struct objc_abi_selector *)
			    &methodList->methods[i]);

	for (struct objc_abi_method_list *methodList = category->classMethods;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			objc_register_selector((struct objc_abi_selector *)
			    &methodList->methods[i]);
}

static void
registerCategory(struct objc_abi_category *category)
{
	struct objc_abi_category **categories;
	Class class = objc_classname_to_class(category->className, false);

	if (categoriesMap == NULL)
		categoriesMap = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);

	categories = (struct objc_abi_category **)objc_hashtable_get(
	    categoriesMap, category->className);

	if (categories != NULL) {
		struct objc_abi_category **newCategories;
		size_t i;

		for (i = 0; categories[i] != NULL; i++);

		if ((newCategories = realloc(categories,
		    (i + 2) * sizeof(struct objc_abi_category *))) == NULL)
			OBJC_ERROR("Not enough memory for category %s of "
			    "class %s!", category->categoryName,
			    category->className);

		newCategories[i] = category;
		newCategories[i + 1] = NULL;
		objc_hashtable_set(categoriesMap, category->className,
		    newCategories);

		if (class != Nil && class->info & OBJC_CLASS_INFO_SETUP) {
			objc_update_dtable(class);
			objc_update_dtable(class->isa);
		}

		return;
	}

	if ((categories = malloc(
	    2 * sizeof(struct objc_abi_category *))) == NULL)
		OBJC_ERROR("Not enough memory for category %s of class %s!\n",
		    category->categoryName, category->className);

	categories[0] = category;
	categories[1] = NULL;
	objc_hashtable_set(categoriesMap, category->className, categories);

	if (class != Nil && class->info & OBJC_CLASS_INFO_SETUP) {
		objc_update_dtable(class);
		objc_update_dtable(class->isa);
	}
}

void
objc_register_all_categories(struct objc_abi_symtab *symtab)
{
	struct objc_abi_category **categories =
	    (struct objc_abi_category **)symtab->defs + symtab->classDefsCount;

	for (size_t i = 0; i < symtab->categoryDefsCount; i++) {
		registerSelectors(categories[i]);
		registerCategory(categories[i]);
	}
}

struct objc_category **
objc_categories_for_class(Class class)
{
	if (categoriesMap == NULL)
		return NULL;

	return (struct objc_category **)objc_hashtable_get(categoriesMap,
	    class->name);
}

void
objc_unregister_all_categories(void)
{
	if (categoriesMap == NULL)
		return;

	for (uint32_t i = 0; i < categoriesMap->size; i++)
		if (categoriesMap->data[i] != NULL)
			free((void *)categoriesMap->data[i]->object);

	objc_hashtable_free(categoriesMap);
	categoriesMap = NULL;
}
