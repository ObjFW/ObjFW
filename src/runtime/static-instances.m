/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_static_instances **staticInstancesList = NULL;
static size_t staticInstancesCount = 0;

void
_objc_initStaticInstances(struct objc_symtab *symtab)
{
	struct objc_static_instances **staticInstances;

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
			    sizeof(*staticInstancesList) *
			    staticInstancesCount);

			if (staticInstancesList == NULL)
				_OBJC_ERROR("Not enough memory for list of "
				    "static instances!");

			/*
			 * We moved the last entry to the current index,
			 * therefore we need to run again for the current index.
			 */
			i--;
		}
	}

	staticInstances = (struct objc_static_instances **)
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
			    sizeof(*staticInstancesList) *
			    (staticInstancesCount + 1));

			if (staticInstancesList == NULL)
				_OBJC_ERROR("Not enough memory for list of "
				    "static instances!");

			staticInstancesList[staticInstancesCount++] =
			    *staticInstances;
		}
	}
}

void
_objc_forgetPendingStaticInstances(void)
{
	free(staticInstancesList);
	staticInstancesList = NULL;
	staticInstancesCount = 0;
}
