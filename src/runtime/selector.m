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

#import "runtime.h"
#import "runtime-private.h"

static struct objc_sparsearray *selectors = NULL;

void
objc_register_selector(struct objc_abi_selector *sel)
{
	uint32_t hash, last;
	struct objc_selector *rsel = (struct objc_selector*)sel;
	const char *name;

	if (selectors == NULL)
		selectors = objc_sparsearray_new();

	hash = objc_hash_string(sel->name) & 0xFFFFFF;

	while (hash <= 0xFFFFFF &&
	    (name = objc_sparsearray_get(selectors, hash)) != NULL) {
		if (!strcmp(name, sel->name)) {
			rsel->uid = hash;
			return;
		}

		hash++;
	}

	if (hash > 0xFFFFFF) {
		last = hash;
		hash = 0;

		while (hash < last &&
		    (name = objc_sparsearray_get(selectors, hash)) != NULL) {
			if (!strcmp(name, sel->name)) {
				rsel->uid = hash;
				return;
			}

			hash++;
		}
	}

	objc_sparsearray_set(selectors, hash, (void*)sel->name);
	rsel->uid = hash;
}

SEL
sel_registerName(const char *name)
{
	struct objc_abi_selector *sel;

	/* FIXME: Free on objc_exit() */
	if ((sel = malloc(sizeof(struct objc_abi_selector))) == NULL)
		ERROR("Not enough memory to allocate selector!");

	if ((sel->name = strdup(name)) == NULL)
		ERROR("Not enough memory to allocate selector!");

	sel->types = NULL;

	objc_global_mutex_lock();
	objc_register_selector(sel);
	objc_global_mutex_unlock();

	return (SEL)sel;
}

void
objc_register_all_selectors(struct objc_abi_symtab *symtab)
{
	struct objc_abi_selector *sel;

	if (symtab->sel_refs == NULL)
		return;

	for (sel = symtab->sel_refs; sel->name != NULL; sel++)
		objc_register_selector(sel);
}

const char*
sel_getName(SEL sel)
{
	const char *ret;

	objc_global_mutex_lock();
	ret = objc_sparsearray_get(selectors, (uint32_t)sel->uid);
	objc_global_mutex_unlock();

	return ret;
}

BOOL
sel_isEqual(SEL sel1, SEL sel2)
{
	return sel1->uid == sel2->uid;
}

void
objc_free_all_selectors(void)
{
	objc_sparsearray_free(selectors);
	selectors = NULL;
}
