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

#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "ObjFWRT.h"
#import "private.h"

struct objc_hashtable_bucket objc_deleted_bucket;

uint32_t
objc_hash_string(const void *str_)
{
	const char *str = str_;
	uint32_t hash = 0;

	while (*str != 0) {
		hash += *str;
		hash += (hash << 10);
		hash ^= (hash >> 6);
		str++;
	}

	hash += (hash << 3);
	hash ^= (hash >> 11);
	hash += (hash << 15);

	return hash;
}

bool
objc_equal_string(const void *ptr1, const void *ptr2)
{
	return (strcmp(ptr1, ptr2) == 0);
}

struct objc_hashtable *
objc_hashtable_new(uint32_t (*hash)(const void *),
    bool (*equal)(const void *, const void *), uint32_t size)
{
	struct objc_hashtable *table;

	if ((table = malloc(sizeof(*table))) == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table!");

	table->hash = hash;
	table->equal = equal;

	table->count = 0;
	table->size = size;
	table->data = calloc(size, sizeof(struct objc_hashtable_bucket *));

	if (table->data == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table!");

	return table;
}

static void
resize(struct objc_hashtable *table, uint32_t count)
{
	uint32_t fullness, newSize;
	struct objc_hashtable_bucket **newData;

	if (count > UINT32_MAX / sizeof(*table->data) || count > UINT32_MAX / 8)
		OBJC_ERROR("Integer overflow!");

	fullness = count * 8 / table->size;

	if (fullness >= 6) {
		if (table->size > UINT32_MAX / 2)
			return;

		newSize = table->size * 2;
	} else if (fullness <= 1)
		newSize = table->size / 2;
	else
		return;

	if (count < table->count && newSize < 16)
		return;

	if ((newData = calloc(newSize, sizeof(*newData))) == NULL)
		OBJC_ERROR("Not enough memory to resize hash table!");

	for (uint32_t i = 0; i < table->size; i++) {
		if (table->data[i] != NULL &&
		    table->data[i] != &objc_deleted_bucket) {
			uint32_t j, last;

			last = newSize;

			for (j = table->data[i]->hash & (newSize - 1);
			    j < last && newData[j] != NULL; j++);

			if (j >= last) {
				last = table->data[i]->hash & (newSize - 1);

				for (j = 0; j < last && newData[j] != NULL;
				    j++);
			}

			if (j >= last)
				OBJC_ERROR("No free bucket!");

			newData[j] = table->data[i];
		}
	}

	free(table->data);
	table->data = newData;
	table->size = newSize;
}

static inline bool
indexForKey(struct objc_hashtable *table, const void *key, uint32_t *idx)
{
	uint32_t i, hash;

	hash = table->hash(key) & (table->size - 1);

	for (i = hash; i < table->size && table->data[i] != NULL; i++) {
		if (table->data[i] == &objc_deleted_bucket)
			continue;

		if (table->equal(table->data[i]->key, key)) {
			*idx = i;
			return true;
		}
	}

	if (i < table->size)
		return false;

	for (i = 0; i < hash && table->data[i] != NULL; i++) {
		if (table->data[i] == &objc_deleted_bucket)
			continue;

		if (table->equal(table->data[i]->key, key)) {
			*idx = i;
			return true;
		}
	}

	return false;
}

void
objc_hashtable_set(struct objc_hashtable *table, const void *key,
    const void *object)
{
	uint32_t i, hash, last;
	struct objc_hashtable_bucket *bucket;

	if (indexForKey(table, key, &i)) {
		table->data[i]->object = object;
		return;
	}

	resize(table, table->count + 1);

	hash = table->hash(key);
	last = table->size;

	for (i = hash & (table->size - 1); i < last && table->data[i] != NULL &&
	    table->data[i] != &objc_deleted_bucket; i++);

	if (i >= last) {
		last = hash & (table->size - 1);

		for (i = 0; i < last && table->data[i] != NULL &&
		    table->data[i] != &objc_deleted_bucket; i++);
	}

	if (i >= last)
		OBJC_ERROR("No free bucket!");

	if ((bucket = malloc(sizeof(*bucket))) == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table bucket!");

	bucket->key = key;
	bucket->hash = hash;
	bucket->object = object;

	table->data[i] = bucket;
	table->count++;
}

void *
objc_hashtable_get(struct objc_hashtable *table, const void *key)
{
	uint32_t idx;

	if (!indexForKey(table, key, &idx))
		return NULL;

	return (void *)table->data[idx]->object;
}

void
objc_hashtable_delete(struct objc_hashtable *table, const void *key)
{
	uint32_t idx;

	if (!indexForKey(table, key, &idx))
		return;

	free(table->data[idx]);
	table->data[idx] = &objc_deleted_bucket;

	table->count--;
	resize(table, table->count);
}

void
objc_hashtable_free(struct objc_hashtable *table)
{
	for (uint32_t i = 0; i < table->size; i++)
		if (table->data[i] != NULL &&
		    table->data[i] != &objc_deleted_bucket)
			free(table->data[i]);

	free(table->data);
	free(table);
}
