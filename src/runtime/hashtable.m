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

#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "ObjFWRT.h"
#import "private.h"

struct _objc_hashtable_bucket _objc_deletedBucket;

uint32_t
_objc_string_hash(const void *str_)
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
_objc_string_equal(const void *ptr1, const void *ptr2)
{
	return (strcmp(ptr1, ptr2) == 0);
}

struct _objc_hashtable *
_objc_hashtable_new(uint32_t (*hash)(const void *),
    bool (*equal)(const void *, const void *), uint32_t size)
{
	struct _objc_hashtable *table;

	if ((table = malloc(sizeof(*table))) == NULL)
		_OBJC_ERROR("Not enough memory to allocate hash table!");

	table->hash = hash;
	table->equal = equal;

	table->count = 0;
	table->size = size;
	table->data = calloc(size, sizeof(struct _objc_hashtable_bucket *));

	if (table->data == NULL)
		_OBJC_ERROR("Not enough memory to allocate hash table!");

	return table;
}

static void
resize(struct _objc_hashtable *table, uint32_t count)
{
	uint32_t fullness, newSize;
	struct _objc_hashtable_bucket **newData;

	if (count > UINT32_MAX / sizeof(*table->data) || count > UINT32_MAX / 8)
		_OBJC_ERROR("Integer overflow!");

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
		_OBJC_ERROR("Not enough memory to resize hash table!");

	for (uint32_t i = 0; i < table->size; i++) {
		if (table->data[i] != NULL &&
		    table->data[i] != &_objc_deletedBucket) {
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
				_OBJC_ERROR("No free bucket in hash table!");

			newData[j] = table->data[i];
		}
	}

	free(table->data);
	table->data = newData;
	table->size = newSize;
}

static inline bool
indexForKey(struct _objc_hashtable *table, const void *key, uint32_t *idx)
{
	uint32_t i, hash;

	hash = table->hash(key) & (table->size - 1);

	for (i = hash; i < table->size && table->data[i] != NULL; i++) {
		if (table->data[i] == &_objc_deletedBucket)
			continue;

		if (table->equal(table->data[i]->key, key)) {
			*idx = i;
			return true;
		}
	}

	if (i < table->size)
		return false;

	for (i = 0; i < hash && table->data[i] != NULL; i++) {
		if (table->data[i] == &_objc_deletedBucket)
			continue;

		if (table->equal(table->data[i]->key, key)) {
			*idx = i;
			return true;
		}
	}

	return false;
}

void
_objc_hashtable_set(struct _objc_hashtable *table, const void *key,
    const void *object)
{
	uint32_t i, hash, last;
	struct _objc_hashtable_bucket *bucket;

	if (indexForKey(table, key, &i)) {
		table->data[i]->object = object;
		return;
	}

	resize(table, table->count + 1);

	hash = table->hash(key);
	last = table->size;

	for (i = hash & (table->size - 1); i < last && table->data[i] != NULL &&
	    table->data[i] != &_objc_deletedBucket; i++);

	if (i >= last) {
		last = hash & (table->size - 1);

		for (i = 0; i < last && table->data[i] != NULL &&
		    table->data[i] != &_objc_deletedBucket; i++);
	}

	if (i >= last)
		_OBJC_ERROR("No free bucket in hash table!");

	if ((bucket = malloc(sizeof(*bucket))) == NULL)
		_OBJC_ERROR("Not enough memory to allocate hash table bucket!");

	bucket->key = key;
	bucket->hash = hash;
	bucket->object = object;

	table->data[i] = bucket;
	table->count++;
}

void *
_objc_hashtable_get(struct _objc_hashtable *table, const void *key)
{
	uint32_t idx;

	if (!indexForKey(table, key, &idx))
		return NULL;

	return (void *)table->data[idx]->object;
}

void
_objc_hashtable_delete(struct _objc_hashtable *table, const void *key)
{
	uint32_t idx;

	if (!indexForKey(table, key, &idx))
		return;

	free(table->data[idx]);
	table->data[idx] = &_objc_deletedBucket;

	table->count--;
	resize(table, table->count);
}

void
_objc_hashtable_free(struct _objc_hashtable *table)
{
	for (uint32_t i = 0; i < table->size; i++)
		if (table->data[i] != NULL &&
		    table->data[i] != &_objc_deletedBucket)
			free(table->data[i]);

	free(table->data);
	free(table);
}
