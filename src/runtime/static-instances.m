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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_abi_static_instances **staticInstancesList = NULL;
static size_t staticInstancesCount = 0;

void
objc_init_static_instances(struct objc_abi_symtab *symtab)
{
	struct objc_abi_static_instances **staticInstances;

	/* Check if the class for a static instance became available */
	for (size_t i = 0; i < staticInstancesCount; i++) {
		Class class = objc_lookUpClass(
		    staticInstancesList[i]->className);

		if (class != Nil) {
			for (id *instances = staticInstancesList[i]->instances;
			    *instances != nil; instances++)
				object_setClass(*instances, class);

			staticInstancesCount--;

			if (staticInstancesCount == 0) {
				free(staticInstancesList);
				staticInstancesList = NULL;
				break;
			}

			staticInstancesList[i] =
			    staticInstancesList[staticInstancesCount];

			staticInstancesList = realloc(staticInstancesList,
			    sizeof(struct objc_abi_static_instances *) *
			    staticInstancesCount);

			if (staticInstancesList == NULL)
				OBJC_ERROR("Not enough memory for list of "
				    "static instances!");

			/*
			 * We moved the last entry to the current index,
			 * therefore we need to run again for the current index.
			 */
			i--;
		}
	}

	staticInstances = (struct objc_abi_static_instances **)
	    symtab->defs[symtab->classDefsCount + symtab->categoryDefsCount];

	if (staticInstances == NULL)
		return;

	for (; *staticInstances != NULL; staticInstances++) {
		Class class = objc_lookUpClass((*staticInstances)->className);

		if (class != Nil) {
			for (id *instances = (*staticInstances)->instances;
			    *instances != nil; instances++)
				object_setClass(*instances, class);
		} else {
			staticInstancesList = realloc(staticInstancesList,
			    sizeof(struct objc_abi_static_instances *) *
			    (staticInstancesCount + 1));

			if (staticInstancesList == NULL)
				OBJC_ERROR("Not enough memory for list of "
				    "static instances!");

			staticInstancesList[staticInstancesCount++] =
			    *staticInstances;
		}
	}
}

void
objc_forget_pending_static_instances()
{
	free(staticInstancesList);
	staticInstancesList = NULL;
	staticInstancesCount = 0;
}
