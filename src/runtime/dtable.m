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

#import "ObjFWRT.h"
#import "private.h"

static struct objc_dtable_level2 *emptyLevel2 = NULL;
#ifdef OF_SELUID24
static struct objc_dtable_level3 *emptyLevel3 = NULL;
#endif

static void
init(void)
{
	if ((emptyLevel2 = malloc(sizeof(*emptyLevel2))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dispatch table!");

#ifdef OF_SELUID24
	if ((emptyLevel3 = malloc(sizeof(*emptyLevel3))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dispatch table!");
#endif

#ifdef OF_SELUID24
	for (uint_fast16_t i = 0; i < 256; i++) {
		emptyLevel2->buckets[i] = emptyLevel3;
		emptyLevel3->buckets[i] = (IMP)0;
	}
#else
	for (uint_fast16_t i = 0; i < 256; i++)
		emptyLevel2->buckets[i] = (IMP)0;
#endif
}

struct objc_dtable *
objc_dtable_new(void)
{
	struct objc_dtable *dTable;

#ifdef OF_SELUID24
	if (emptyLevel2 == NULL || emptyLevel3 == NULL)
		init();
#else
	if (emptyLevel2 == NULL)
		init();
#endif

	if ((dTable = malloc(sizeof(*dTable))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dispatch table!");

	for (uint_fast16_t i = 0; i < 256; i++)
		dTable->buckets[i] = emptyLevel2;

	return dTable;
}

void
objc_dtable_copy(struct objc_dtable *dest, struct objc_dtable *src)
{
	for (uint_fast16_t i = 0; i < 256; i++) {
		if (src->buckets[i] == emptyLevel2)
			continue;

#ifdef OF_SELUID24
		for (uint_fast16_t j = 0; j < 256; j++) {
			if (src->buckets[i]->buckets[j] == emptyLevel3)
				continue;

			for (uint_fast16_t k = 0; k < 256; k++) {
				IMP implementation;
				uint32_t idx;

				implementation =
				    src->buckets[i]->buckets[j]->buckets[k];

				if (implementation == (IMP)0)
					continue;

				idx = (uint32_t)
				    (((uint32_t)i << 16) | (j << 8) | k);
				objc_dtable_set(dest, idx, implementation);
			}
		}
#else
		for (uint_fast16_t j = 0; j < 256; j++) {
			IMP implementation = src->buckets[i]->buckets[j];
			uint32_t idx;

			if (implementation == (IMP)0)
				continue;

			idx = (uint32_t)((i << 8) | j);
			objc_dtable_set(dest, idx, implementation);
		}
#endif
	}
}

void
objc_dtable_set(struct objc_dtable *dTable, uint32_t idx, IMP implementation)
{
#ifdef OF_SELUID24
	uint8_t i = idx >> 16;
	uint8_t j = idx >> 8;
	uint8_t k = idx;
#else
	uint8_t i = idx >> 8;
	uint8_t j = idx;
#endif

	if (dTable->buckets[i] == emptyLevel2) {
		struct objc_dtable_level2 *level2 = malloc(sizeof(*level2));

		if (level2 == NULL)
			OBJC_ERROR("Not enough memory to insert into "
			    "dispatch table!");

		for (uint_fast16_t l = 0; l < 256; l++)
#ifdef OF_SELUID24
			level2->buckets[l] = emptyLevel3;
#else
			level2->buckets[l] = (IMP)0;
#endif

		dTable->buckets[i] = level2;
	}

#ifdef OF_SELUID24
	if (dTable->buckets[i]->buckets[j] == emptyLevel3) {
		struct objc_dtable_level3 *level3 = malloc(sizeof(*level3));

		if (level3 == NULL)
			OBJC_ERROR("Not enough memory to insert into "
			    "dispatch table!");

		for (uint_fast16_t l = 0; l < 256; l++)
			level3->buckets[l] = (IMP)0;

		dTable->buckets[i]->buckets[j] = level3;
	}

	dTable->buckets[i]->buckets[j]->buckets[k] = implementation;
#else
	dTable->buckets[i]->buckets[j] = implementation;
#endif
}

void
objc_dtable_free(struct objc_dtable *dTable)
{
	for (uint_fast16_t i = 0; i < 256; i++) {
		if (dTable->buckets[i] == emptyLevel2)
			continue;

#ifdef OF_SELUID24
		for (uint_fast16_t j = 0; j < 256; j++)
			if (dTable->buckets[i]->buckets[j] != emptyLevel3)
				free(dTable->buckets[i]->buckets[j]);
#endif

		free(dTable->buckets[i]);
	}

	free(dTable);
}

void
objc_dtable_cleanup(void)
{
	if (emptyLevel2 != NULL)
		free(emptyLevel2);
#ifdef OF_SELUID24
	if (emptyLevel3 != NULL)
		free(emptyLevel3);
#endif

	emptyLevel2 = NULL;
#ifdef OF_SELUID24
	emptyLevel3 = NULL;
#endif
}
