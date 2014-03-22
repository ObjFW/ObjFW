/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#include <stdint.h>
#include <string.h>

#import "runtime.h"
#import "runtime-private.h"

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
objc_equal_string(const void *obj1, const void *obj2)
{
	return !strcmp(obj1, obj2);
}

struct objc_hashtable*
objc_hashtable_new(uint32_t (*hash)(const void*),
    bool (*equal)(const void*, const void*), uint32_t size)
{
	struct objc_hashtable *table;

	if ((table = malloc(sizeof(struct objc_hashtable))) == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table!");

	table->hash = hash;
	table->equal = equal;

	table->count = 0;
	table->size = size;
	table->data = calloc(size, sizeof(struct objc_hashtable_bucket*));

	if (table->data == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table!");

	return table;
}

static void
insert(struct objc_hashtable *table, const void *key, const void *obj)
{
	uint32_t i, hash, last;
	struct objc_hashtable_bucket *bucket;

	hash = table->hash(key);

	if (table->count + 1 > UINT32_MAX / 4)
		OBJC_ERROR("Integer overflow!");

	if ((table->count + 1) * 4 / table->size >= 3) {
		struct objc_hashtable_bucket **newData;
		uint32_t newSize;

		if (table->size > UINT32_MAX / 2)
			OBJC_ERROR("Integer overflow!");

		newSize = table->size * 2;

		if ((newData = calloc(newSize,
		    sizeof(struct objc_hashtable_bucket*))) == NULL)
			OBJC_ERROR("Not enough memory to insert into hash "
			    "table!");

		for (i = 0; i < table->size; i++) {
			if (table->data[i] != NULL) {
				uint32_t j;

				last = newSize;

				for (j = table->data[i]->hash & (newSize - 1);
				    j < last && newData[j] != NULL; j++);

				if (j >= last) {
					last = table->data[i]->hash &
					    (newSize - 1);

					for (j = 0; j < last &&
					    newData[j] != NULL; j++);
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

	last = table->size;

	for (i = hash & (table->size - 1);
	    i < last && table->data[i] != NULL; i++);

	if (i >= last) {
		last = hash & (table->size - 1);

		for (i = 0; i < last && table->data[i] != NULL; i++);
	}

	if (i >= last)
		OBJC_ERROR("No free bucket!");

	if ((bucket = malloc(sizeof(struct objc_hashtable_bucket))) == NULL)
		OBJC_ERROR("Not enough memory to allocate hash table bucket!");

	bucket->key = key;
	bucket->hash = hash;
	bucket->obj = obj;

	table->data[i] = bucket;
	table->count++;
}

static inline int64_t
index_for_key(struct objc_hashtable *table, const void *key)
{
	uint32_t i, hash;

	hash = table->hash(key) & (table->size - 1);

	for (i = hash; i < table->size && table->data[i] != NULL; i++)
		if (table->equal(table->data[i]->key, key))
			return i;

	if (i < table->size)
		return -1;

	for (i = 0; i < hash && table->data[i] != NULL; i++)
		if (table->equal(table->data[i]->key, key))
			return i;

	return -1;
}

void
objc_hashtable_set(struct objc_hashtable *table, const void *key,
    const void *obj)
{
	int64_t idx = index_for_key(table, key);

	if (idx < 0) {
		insert(table, key, obj);
		return;
	}

	table->data[idx]->obj = obj;
}

void*
objc_hashtable_get(struct objc_hashtable *table, const void *key)
{
	int64_t idx = index_for_key(table, key);

	if (idx < 0)
		return NULL;

	return (void*)table->data[idx]->obj;
}

void
objc_hashtable_free(struct objc_hashtable *table)
{
	uint32_t i;

	for (i = 0; i < table->size; i++)
		if (table->data[i] != NULL)
			free(table->data[i]);

	free(table->data);
	free(table);
}
