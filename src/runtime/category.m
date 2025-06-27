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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_hashtable *categoriesMap = NULL;
static struct objc_category **loadQueue = NULL;
static size_t loadQueueCount = 0;

static void
registerSelectors(struct objc_category *category)
{
	struct objc_method_list *iter;
	unsigned int i;

	for (iter = category->instanceMethods; iter != NULL; iter = iter->next)
		for (i = 0; i < iter->count; i++)
			_objc_registerSelector(&iter->methods[i].selector);

	for (iter = category->classMethods; iter != NULL; iter = iter->next)
		for (i = 0; i < iter->count; i++)
			_objc_registerSelector(&iter->methods[i].selector);
}

static bool
hasLoad(struct objc_category *category)
{
	static SEL loadSel = NULL;

	if (loadSel == NULL)
		loadSel = sel_registerName("load");

	for (struct objc_method_list *methodList = category->classMethods;
	    methodList != NULL; methodList = methodList->next)
		for (unsigned int i = 0; i < methodList->count; i++)
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    loadSel))
				return true;

	return false;
}

static void
callLoad(Class class, struct objc_category *category)
{
	static SEL loadSel = NULL;

	if (loadSel == NULL)
		loadSel = sel_registerName("load");

	for (struct objc_method_list *methodList = category->classMethods;
	    methodList != NULL; methodList = methodList->next) {
		for (unsigned int i = 0; i < methodList->count; i++) {
			if (sel_isEqual((SEL)&methodList->methods[i].selector,
			    loadSel)) {
				void (*load)(id, SEL) = (void (*)(id, SEL))
				    methodList->methods[i].implementation;

				load(class, loadSel);
			}
		}
	}
}

void
_objc_processCategoriesLoadQueue(void)
{
	for (size_t i = 0; i < loadQueueCount; i++) {
		Class class = objc_lookUpClass(loadQueue[i]->className);

		if (class != Nil && class->info & _OBJC_CLASS_INFO_LOADED) {
			callLoad(class, loadQueue[i]);

			if (--loadQueueCount == 0) {
				free(loadQueue);
				loadQueue = NULL;
				loadQueueCount = 0;
				break;
			}

			loadQueue[i] = loadQueue[loadQueueCount];

			loadQueue = realloc(loadQueue,
			    sizeof(struct objc_category *) * loadQueueCount);

			if (loadQueue == NULL)
				_OBJC_ERROR("Not enough memory for load "
				    "queue!");
		}
	}
}

static void
registerCategory(struct objc_category *category)
{
	size_t numCategories = 0;
	struct objc_category **categories;
	Class class = _objc_classnameToClass(category->className, false);

	if (categoriesMap == NULL)
		categoriesMap = _objc_hashtable_new(
		    _objc_string_hash, _objc_string_equal, 2);

	categories = (struct objc_category **)_objc_hashtable_get(
	    categoriesMap, category->className);

	if (categories != NULL)
		for (; categories[numCategories] != NULL; numCategories++);
	else {
		if ((categories = malloc(sizeof(*categories))) == NULL)
			_OBJC_ERROR("Not enough memory for category %s of "
			    "class %s!\n",
			    category->categoryName, category->className);

		categories[0] = NULL;
	}

	if ((categories = realloc(categories,
	    (numCategories + 2) * sizeof(*categories))) == NULL)
		_OBJC_ERROR("Not enough memory for category %s of class %s!",
		    category->categoryName, category->className);

	categories[numCategories] = category;
	categories[numCategories + 1] = NULL;
	_objc_hashtable_set(categoriesMap, category->className, categories);

	if (class != Nil && class->info & _OBJC_CLASS_INFO_SETUP) {
		_objc_updateDTable(class);
		_objc_updateDTable(class->isa);
	}

	if (hasLoad(category)) {
		/*
		 * objc_classnameToClass does not set up the class, but
		 * objc_lookUpClass tries to set it up and only returns it if
		 * it could be set up.
		 */
		class = objc_lookUpClass(category->className);

		if (class != Nil && class->info & _OBJC_CLASS_INFO_LOADED)
			callLoad(class, category);
		else {
			loadQueue = realloc(loadQueue,
			    sizeof(struct objc_category *) *
			    (loadQueueCount + 1));

			if (loadQueue == NULL)
				_OBJC_ERROR("Not enough memory for load "
				    "queue!");

			loadQueue[loadQueueCount++] = category;
		}
	}
}

void
_objc_registerAllCategories(struct objc_symtab *symtab)
{
	struct objc_category **categories =
	    (struct objc_category **)symtab->defs + symtab->classDefsCount;

	for (size_t i = 0; i < symtab->categoryDefsCount; i++) {
		registerSelectors(categories[i]);
		registerCategory(categories[i]);
	}
}

struct objc_category **
_objc_categoriesForClass(Class class)
{
	if (categoriesMap == NULL)
		return NULL;

	return (struct objc_category **)_objc_hashtable_get(categoriesMap,
	    class->name);
}

void
_objc_unregisterAllCategories(void)
{
	if (categoriesMap == NULL)
		return;

	for (uint32_t i = 0; i < categoriesMap->size; i++)
		if (categoriesMap->data[i] != NULL)
			free((void *)categoriesMap->data[i]->object);

	_objc_hashtable_free(categoriesMap);
	categoriesMap = NULL;
}
