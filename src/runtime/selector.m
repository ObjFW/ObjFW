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

#import "macros.h"

#ifdef OF_SELUID24
static const uint32_t maxSel = 0xFFFFFF;
static const uint8_t selLevels = 3;
#else
static const uint32_t maxSel = 0xFFFF;
static const uint8_t selLevels = 2;
#endif

static struct objc_hashtable *selectors = NULL;
static uint32_t selectorsCount = 0;
static struct objc_sparsearray *selectorNames = NULL;
static void **freeList = NULL;
static size_t freeListCount = 0;

void
objc_registerSelector(struct objc_selector *selector)
{
	SEL existingSelector;
	const char *name;

	if (selectorsCount > maxSel)
		OBJC_ERROR("Out of selector slots!");

	if (selectors == NULL)
		selectors = objc_hashtable_new(
		    objc_string_hash, objc_string_equal, 2);
	else if ((existingSelector = objc_hashtable_get(selectors,
	    (const char *)selector->UID)) != NULL) {
		selector->UID = existingSelector->UID;
		return;
	}

	if (selectorNames == NULL)
		selectorNames = objc_sparsearray_new(selLevels);

	name = (const char *)selector->UID;
	selector->UID = selectorsCount++;

	objc_hashtable_set(selectors, name, selector);
	objc_sparsearray_set(selectorNames, (uint32_t)selector->UID,
	    (void *)name);
}

SEL
sel_registerName(const char *name)
{
	struct objc_selector *selector;

	objc_globalMutex_lock();

	if (selectors != NULL &&
	    (selector = objc_hashtable_get(selectors, name)) != NULL) {
		objc_globalMutex_unlock();
		return (SEL)selector;
	}

	if ((selector = malloc(sizeof(*selector))) == NULL ||
	    (selector->UID = (uintptr_t)objc_strdup(name)) == 0)
		OBJC_ERROR("Not enough memory to allocate selector!");

	selector->typeEncoding = NULL;

	if ((freeList = realloc(freeList,
	    sizeof(void *) * (freeListCount + 2))) == NULL)
		OBJC_ERROR("Not enough memory to allocate selector!");

	freeList[freeListCount++] = selector;
	freeList[freeListCount++] = (char *)selector->UID;

	objc_registerSelector(selector);

	objc_globalMutex_unlock();
	return (SEL)selector;
}

void
objc_registerAllSelectors(struct objc_symtab *symtab)
{
	struct objc_selector *selector;

	if (symtab->selectorRefs == NULL)
		return;

	for (selector = symtab->selectorRefs; selector->UID != 0; selector++)
		objc_registerSelector(selector);
}

const char *
sel_getName(SEL selector)
{
	const char *ret;

	objc_globalMutex_lock();
	ret = objc_sparsearray_get(selectorNames, (uint32_t)selector->UID);
	objc_globalMutex_unlock();

	return ret;
}

bool
sel_isEqual(SEL selector1, SEL selector2)
{
	return (selector1->UID == selector2->UID);
}

void
objc_unregisterAllSelectors(void)
{
	objc_hashtable_free(selectors);
	objc_sparsearray_free(selectorNames);

	if (freeList != NULL) {
		for (size_t i = 0; i < freeListCount; i++)
			free(freeList[i]);

		free(freeList);
	}

	selectors = NULL;
	selectorsCount = 0;
	selectorNames = NULL;
	freeList = NULL;
	freeListCount = 0;
}
