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

struct objc_sparsearray *
objc_sparsearray_new(uint8_t indexSize)
{
	struct objc_sparsearray *sparsearray;

	if ((sparsearray = calloc(1, sizeof(*sparsearray))) == NULL)
		OBJC_ERROR("Failed to allocate memory for sparse array!");

	if ((sparsearray->data = calloc(1, sizeof(*sparsearray->data))) == NULL)
		OBJC_ERROR("Failed to allocate memory for sparse array!");

	sparsearray->indexSize = indexSize;

	return sparsearray;
}

void *
objc_sparsearray_get(struct objc_sparsearray *sparsearray, uintptr_t idx)
{
	struct objc_sparsearray_data *iter = sparsearray->data;

	for (uint8_t i = 0; i < sparsearray->indexSize - 1; i++) {
		uintptr_t j =
		    (idx >> ((sparsearray->indexSize - i - 1) * 8)) & 0xFF;

		if ((iter = iter->next[j]) == NULL)
			return NULL;
	}

	return iter->next[idx & 0xFF];
}

void
objc_sparsearray_set(struct objc_sparsearray *sparsearray, uintptr_t idx,
    void *value)
{
	struct objc_sparsearray_data *iter = sparsearray->data;

	for (uint8_t i = 0; i < sparsearray->indexSize - 1; i++) {
		uintptr_t j =
		    (idx >> ((sparsearray->indexSize - i - 1) * 8)) & 0xFF;

		if (iter->next[j] == NULL)
			if ((iter->next[j] = calloc(1,
			    sizeof(struct objc_sparsearray_data))) == NULL)
				OBJC_ERROR("Failed to allocate memory for "
				    "sparse array!");

		iter = iter->next[j];
	}

	iter->next[idx & 0xFF] = value;
}

static void
freeSparsearrayData(struct objc_sparsearray_data *data, uint8_t depth)
{
	if (data == NULL || depth == 0)
		return;

	for (uint_fast16_t i = 0; i < 256; i++)
		freeSparsearrayData(data->next[i], depth - 1);

	free(data);
}

void
objc_sparsearray_free(struct objc_sparsearray *sparsearray)
{
	freeSparsearrayData(sparsearray->data, sparsearray->indexSize);
	free(sparsearray);
}
