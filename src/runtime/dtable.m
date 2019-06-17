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

static struct objc_dtable_level2 *emptyLevel2 = NULL;
#ifdef OF_SELUID24
static struct objc_dtable_level3 *emptyLevel3 = NULL;
#endif

static void
init(void)
{
	if ((emptyLevel2 = malloc(sizeof(*emptyLevel2))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dtable!");

#ifdef OF_SELUID24
	if ((emptyLevel3 = malloc(sizeof(*emptyLevel3))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dtable!");
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
	struct objc_dtable *DTable;

#ifdef OF_SELUID24
	if (emptyLevel2 == NULL || emptyLevel3 == NULL)
		init();
#else
	if (emptyLevel2 == NULL)
		init();
#endif

	if ((DTable = malloc(sizeof(*DTable))) == NULL)
		OBJC_ERROR("Not enough memory to allocate dtable!");

	for (uint_fast16_t i = 0; i < 256; i++)
		DTable->buckets[i] = emptyLevel2;

	return DTable;
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
objc_dtable_set(struct objc_dtable *DTable, uint32_t idx, IMP implementation)
{
#ifdef OF_SELUID24
	uint8_t i = idx >> 16;
	uint8_t j = idx >> 8;
	uint8_t k = idx;
#else
	uint8_t i = idx >> 8;
	uint8_t j = idx;
#endif

	if (DTable->buckets[i] == emptyLevel2) {
		struct objc_dtable_level2 *level2 = malloc(sizeof(*level2));

		if (level2 == NULL)
			OBJC_ERROR("Not enough memory to insert into dtable!");

		for (uint_fast16_t l = 0; l < 256; l++)
#ifdef OF_SELUID24
			level2->buckets[l] = emptyLevel3;
#else
			level2->buckets[l] = (IMP)0;
#endif

		DTable->buckets[i] = level2;
	}

#ifdef OF_SELUID24
	if (DTable->buckets[i]->buckets[j] == emptyLevel3) {
		struct objc_dtable_level3 *level3 = malloc(sizeof(*level3));

		if (level3 == NULL)
			OBJC_ERROR("Not enough memory to insert into dtable!");

		for (uint_fast16_t l = 0; l < 256; l++)
			level3->buckets[l] = (IMP)0;

		DTable->buckets[i]->buckets[j] = level3;
	}

	DTable->buckets[i]->buckets[j]->buckets[k] = implementation;
#else
	DTable->buckets[i]->buckets[j] = implementation;
#endif
}

void
objc_dtable_free(struct objc_dtable *DTable)
{
	for (uint_fast16_t i = 0; i < 256; i++) {
		if (DTable->buckets[i] == emptyLevel2)
			continue;

#ifdef OF_SELUID24
		for (uint_fast16_t j = 0; j < 256; j++)
			if (DTable->buckets[i]->buckets[j] != emptyLevel3)
				free(DTable->buckets[i]->buckets[j]);
#endif

		free(DTable->buckets[i]);
	}

	free(DTable);
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
