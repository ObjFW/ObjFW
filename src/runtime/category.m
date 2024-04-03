/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_hashtable *categoriesMap = NULL;

static void
registerSelectors(struct objc_category *category)
{
	struct objc_method_list *iter;
	unsigned int i;

	for (iter = category->instanceMethods; iter != NULL; iter = iter->next)
		for (i = 0; i < iter->count; i++)
			objc_registerSelector(&iter->methods[i].selector);

	for (iter = category->classMethods; iter != NULL; iter = iter->next)
		for (i = 0; i < iter->count; i++)
			objc_registerSelector(&iter->methods[i].selector);
}

static void
registerCategory(struct objc_category *category)
{
	struct objc_category **categories;
	Class class = objc_classnameToClass(category->className, false);

	if (categoriesMap == NULL)
		categoriesMap = objc_hashtable_new(
		    objc_string_hash, objc_string_equal, 2);

	categories = (struct objc_category **)objc_hashtable_get(
	    categoriesMap, category->className);

	if (categories != NULL) {
		struct objc_category **newCategories;
		size_t i;

		for (i = 0; categories[i] != NULL; i++);

		if ((newCategories = realloc(categories,
		    (i + 2) * sizeof(*categories))) == NULL)
			OBJC_ERROR("Not enough memory for category %s of "
			    "class %s!", category->categoryName,
			    category->className);

		newCategories[i] = category;
		newCategories[i + 1] = NULL;
		objc_hashtable_set(categoriesMap, category->className,
		    newCategories);

		if (class != Nil && class->info & OBJC_CLASS_INFO_SETUP) {
			objc_updateDTable(class);
			objc_updateDTable(class->isa);
		}

		return;
	}

	if ((categories = malloc(2 * sizeof(*categories))) == NULL)
		OBJC_ERROR("Not enough memory for category %s of class %s!\n",
		    category->categoryName, category->className);

	categories[0] = category;
	categories[1] = NULL;
	objc_hashtable_set(categoriesMap, category->className, categories);

	if (class != Nil && class->info & OBJC_CLASS_INFO_SETUP) {
		objc_updateDTable(class);
		objc_updateDTable(class->isa);
	}
}

void
objc_registerAllCategories(struct objc_symtab *symtab)
{
	struct objc_category **categories =
	    (struct objc_category **)symtab->defs + symtab->classDefsCount;

	for (size_t i = 0; i < symtab->categoryDefsCount; i++) {
		registerSelectors(categories[i]);
		registerCategory(categories[i]);
	}
}

struct objc_category **
objc_categoriesForClass(Class class)
{
	if (categoriesMap == NULL)
		return NULL;

	return (struct objc_category **)objc_hashtable_get(categoriesMap,
	    class->name);
}

void
objc_unregisterAllCategories(void)
{
	if (categoriesMap == NULL)
		return;

	for (uint32_t i = 0; i < categoriesMap->size; i++)
		if (categoriesMap->data[i] != NULL)
			free((void *)categoriesMap->data[i]->object);

	objc_hashtable_free(categoriesMap);
	categoriesMap = NULL;
}
