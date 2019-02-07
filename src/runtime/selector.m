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

#import "macros.h"

#ifdef OF_SELUID24
# define SEL_MAX 0xFFFFFF
# define SEL_SIZE 3
#else
# define SEL_MAX 0xFFFF
# define SEL_SIZE 2
#endif

static struct objc_hashtable *selectors = NULL;
static uint32_t selectorsCount = 0;
static struct objc_sparsearray *selectorNames = NULL;
static void **freeList = NULL;
static size_t freeListCount = 0;

void
objc_register_selector(struct objc_abi_selector *sel)
{
	struct objc_selector *rsel;
	const char *name;

	if (selectorsCount > SEL_MAX)
		OBJC_ERROR("Out of selector slots!");

	if (selectors == NULL)
		selectors = objc_hashtable_new(
		    objc_hash_string, objc_equal_string, 2);
	else if ((rsel = objc_hashtable_get(selectors, sel->name)) != NULL) {
		((struct objc_selector *)sel)->UID = rsel->UID;
		return;
	}

	if (selectorNames == NULL)
		selectorNames = objc_sparsearray_new(SEL_SIZE);

	name = sel->name;
	rsel = (struct objc_selector *)sel;
	rsel->UID = selectorsCount++;

	objc_hashtable_set(selectors, name, rsel);
	objc_sparsearray_set(selectorNames, (uint32_t)rsel->UID, (void *)name);
}

SEL
sel_registerName(const char *name)
{
	const struct objc_abi_selector *rsel;
	struct objc_abi_selector *sel;

	objc_global_mutex_lock();

	if (selectors != NULL &&
	    (rsel = objc_hashtable_get(selectors, name)) != NULL) {
		objc_global_mutex_unlock();
		return (SEL)rsel;
	}

	if ((sel = malloc(sizeof(struct objc_abi_selector))) == NULL)
		OBJC_ERROR("Not enough memory to allocate selector!");

	if ((sel->name = of_strdup(name)) == NULL)
		OBJC_ERROR("Not enough memory to allocate selector!");

	sel->typeEncoding = NULL;

	if ((freeList = realloc(freeList,
	    sizeof(void *) * (freeListCount + 2))) == NULL)
		OBJC_ERROR("Not enough memory to allocate selector!");

	freeList[freeListCount++] = sel;
	freeList[freeListCount++] = (char *)sel->name;

	objc_register_selector(sel);

	objc_global_mutex_unlock();
	return (SEL)sel;
}

void
objc_register_all_selectors(struct objc_abi_symtab *symtab)
{
	struct objc_abi_selector *sel;

	if (symtab->selectorRefs == NULL)
		return;

	for (sel = symtab->selectorRefs; sel->name != NULL; sel++)
		objc_register_selector(sel);
}

const char *
sel_getName(SEL selector)
{
	const char *ret;

	objc_global_mutex_lock();
	ret = objc_sparsearray_get(selectorNames, (uint32_t)selector->UID);
	objc_global_mutex_unlock();

	return ret;
}

bool
sel_isEqual(SEL selector1, SEL selector2)
{
	return (selector1->UID == selector2->UID);
}

void
objc_unregister_all_selectors(void)
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
