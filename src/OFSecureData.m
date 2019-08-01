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

#include <errno.h>
#include <stdlib.h>

#ifdef HAVE_SYS_MMAN_H
# include <sys/mman.h>
#endif

#import "OFSecureData.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#ifdef OF_HAVE_THREADS
# import "tlskey.h"
#endif

#define CHUNK_SIZE 16

struct page {
	struct page *next, *previous;
	void *map;
	unsigned char *page;
};

#if defined(OF_HAVE_COMPILER_TLS)
static thread_local struct page *firstPage = NULL;
static thread_local struct page *lastPage = NULL;
static thread_local struct page **preallocatedPages = NULL;
static thread_local size_t numPreallocatedPages = 0;
#elif defined(OF_HAVE_THREADS)
static of_tlskey_t firstPageKey, lastPageKey;
static of_tlskey_t preallocatedPagesKey, numPreallocatedPagesKey;
#else
static struct page *firstPage = NULL;
static struct page *lastPage = NULL;
static struct page **preallocatedPages = NULL;
static size_t numPreallocatedPages = 0;
#endif

static void *
mapPages(size_t numPages)
{
	size_t pageSize = [OFSystemInfo pageSize];
	void *pointer;

	if (numPages > SIZE_MAX / pageSize)
		@throw [OFOutOfRangeException exception];

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	if ((pointer = mmap(NULL, numPages * pageSize, PROT_READ | PROT_WRITE,
	    MAP_PRIVATE | MAP_ANON, -1, 0)) == MAP_FAILED)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: pageSize];

	if (mlock(pointer, numPages * pageSize) != 0 && errno != EPERM)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: pageSize];
#else
	if ((pointer = malloc(numPages * pageSize)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: pageSize];
#endif

	return pointer;
}

static void
unmapPages(void *pointer, size_t numPages)
{
	size_t pageSize = [OFSystemInfo pageSize];

	if (numPages > SIZE_MAX / pageSize)
		@throw [OFOutOfRangeException exception];

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	munlock(pointer, numPages * pageSize);
	munmap(pointer, numPages * pageSize);
#else
	free(pointer);
#endif
}

static struct page *
addPage(bool allowPreallocated)
{
	size_t pageSize = [OFSystemInfo pageSize];
	size_t mapSize = OF_ROUND_UP_POW2(8, pageSize / CHUNK_SIZE) / 8;
	struct page *page;
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	struct page *lastPage;
#endif

	if (allowPreallocated) {
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		uintptr_t numPreallocatedPages =
		    (uintptr_t)of_tlskey_get(numPreallocatedPagesKey);
#endif

		if (numPreallocatedPages > 0) {
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			struct page **preallocatedPages =
			    of_tlskey_get(preallocatedPagesKey);
#endif

			numPreallocatedPages--;
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			OF_ENSURE(of_tlskey_set(numPreallocatedPagesKey,
			    (void *)numPreallocatedPages));
#endif

			page = preallocatedPages[numPreallocatedPages];

			if (numPreallocatedPages == 0) {
				free(preallocatedPages);
				preallocatedPages = NULL;
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
				OF_ENSURE(of_tlskey_set(preallocatedPagesKey,
				    preallocatedPages));
#endif
			}

			return page;
		}
	}

	if ((page = malloc(sizeof(*page))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: sizeof(*page)];

	if ((page->map = calloc(1, mapSize)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: mapSize];

	page->page = mapPages(1);
	of_explicit_memset(page->page, 0, pageSize);

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	lastPage = of_tlskey_get(lastPageKey);
#endif

	page->previous = lastPage;
	page->next = NULL;

	if (lastPage != NULL)
		lastPage->next = page;

#if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
	lastPage = page;

	if (firstPage == NULL)
		firstPage = page;
#else
	OF_ENSURE(of_tlskey_set(lastPageKey, page));

	if (of_tlskey_get(firstPageKey) == NULL)
		OF_ENSURE(of_tlskey_set(firstPageKey, page));
#endif

	return page;
}

static void
removePageIfEmpty(struct page *page)
{
	unsigned char *map = page->map;
	size_t pageSize = [OFSystemInfo pageSize];
	size_t mapSize = OF_ROUND_UP_POW2(8, pageSize / CHUNK_SIZE) / 8;

	for (size_t i = 0; i < mapSize; i++)
		if (map[i] != 0)
			return;

	unmapPages(page->page, 1);
	free(page->map);

	if (page->previous != NULL)
		page->previous->next = page->next;
	if (page->next != NULL)
		page->next->previous = page->previous;

#if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
	if (firstPage == page)
		firstPage = page->next;
	if (lastPage == page)
		lastPage = page->previous;
#else
	if (of_tlskey_get(firstPageKey) == page)
		OF_ENSURE(of_tlskey_set(firstPageKey, page->next));
	if (of_tlskey_get(lastPageKey) == page)
		OF_ENSURE(of_tlskey_set(lastPageKey, page->previous));
#endif

	free(page);
}

static void *
allocateMemory(struct page *page, size_t bytes)
{
	size_t chunks, chunksLeft, pageSize, i, firstChunk;

	bytes = OF_ROUND_UP_POW2(CHUNK_SIZE, bytes);
	chunks = chunksLeft = bytes / CHUNK_SIZE;
	firstChunk = 0;
	pageSize = [OFSystemInfo pageSize];

	for (i = 0; i < pageSize / CHUNK_SIZE; i++) {
		if (of_bitset_isset(page->map, i)) {
			chunksLeft = chunks;
			firstChunk = i + 1;
			continue;
		}

		if (--chunksLeft == 0)
			break;
	}

	if (chunksLeft == 0) {
		for (size_t j = firstChunk; j < firstChunk + chunks; j++)
			of_bitset_set(page->map, j);

		return page->page + (CHUNK_SIZE * firstChunk);
	}

	return NULL;
}

static void
freeMemory(struct page *page, void *pointer, size_t bytes)
{
	size_t chunks, chunkIndex;

	bytes = OF_ROUND_UP_POW2(CHUNK_SIZE, bytes);
	chunks = bytes / CHUNK_SIZE;
	chunkIndex = ((uintptr_t)pointer - (uintptr_t)page->page) / CHUNK_SIZE;

	of_explicit_memset(pointer, 0, bytes);

	for (size_t i = 0; i < chunks; i++)
		of_bitset_clear(page->map, chunkIndex + i);
}

@implementation OFSecureData
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
+ (void)initialize
{
	if (self != [OFSecureData class])
		return;

	if (!of_tlskey_new(&firstPageKey) || !of_tlskey_new(&lastPageKey) ||
	    !of_tlskey_new(&preallocatedPagesKey) ||
	    !of_tlskey_new(&numPreallocatedPagesKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (bool)isSecure
{
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	bool isSecure = true;
	size_t pageSize = [OFSystemInfo pageSize];
	void *pointer;

	if ((pointer = mmap(NULL, pageSize, PROT_READ | PROT_WRITE,
	    MAP_PRIVATE | MAP_ANON, -1, 0)) == MAP_FAILED)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: pageSize];

	if (mlock(pointer, pageSize) != 0) {
		if (errno != EPERM) {
			munmap(pointer, pageSize);

			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: pageSize];
		}

		isSecure = false;
	}

	munlock(pointer, pageSize);
	munmap(pointer, pageSize);

	return isSecure;
#else
	return false;
#endif
}

+ (void)preallocateMemoryWithSize: (size_t)size
{
	size_t pageSize = [OFSystemInfo pageSize];
	size_t numPages = OF_ROUND_UP_POW2(pageSize, size) / pageSize;
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	struct page **preallocatedPages = of_tlskey_get(preallocatedPagesKey);
	size_t numPreallocatedPages;
#endif

	if (preallocatedPages != NULL)
		@throw [OFInvalidArgumentException exception];

	preallocatedPages = calloc(numPages, sizeof(struct page));
	if (preallocatedPages == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: numPages * sizeof(struct page)];

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	of_tlskey_set(preallocatedPagesKey, preallocatedPages);
#endif

	for (size_t i = 0; i < numPages; i++)
		preallocatedPages[i] = addPage(false);

	numPreallocatedPages = numPages;
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	of_tlskey_set(numPreallocatedPagesKey,
	    (void *)(uintptr_t)numPreallocatedPages);
#endif
}

+ (instancetype)dataWithCount: (size_t)count
{
	return [[[self alloc] initWithCount: count] autorelease];
}

+ (instancetype)dataWithItemSize: (size_t)itemSize
			   count: (size_t)count
{
	return [[[self alloc] initWithItemSize: itemSize
					 count: count] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}
#endif

+ (instancetype)dataWithContentsOfURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithStringRepresentation: (OFString *)string
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithBase64EncodedString: (OFString *)string
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithSerialization: (OFXMLElement *)element
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithCount: (size_t)count
{
	return [self initWithItemSize: 1
				count: count];
}

- (instancetype)initWithItemSize: (size_t)itemSize
			   count: (size_t)count
{
	self = [super init];

	@try {
		size_t pageSize = [OFSystemInfo pageSize];

		if (count > SIZE_MAX / itemSize)
			@throw [OFOutOfRangeException exception];

		if (count * itemSize >= pageSize)
			_items = mapPages(OF_ROUND_UP_POW2(pageSize,
			    count * itemSize) / pageSize);
		else {
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			struct page *lastPage = of_tlskey_get(lastPageKey);
#endif

			for (struct page *page = lastPage; page != NULL;
			    page = page->previous) {
				_items = allocateMemory(page, count * itemSize);

				if (_items != NULL) {
					_page = page;
					break;
				}
			}

			if (_items == NULL) {
				_page = addPage(true);
				_items = allocateMemory(_page,
				    count * itemSize);

				if (_items == NULL)
					@throw [OFOutOfMemoryException
					    exceptionWithRequestedSize:
					    count * itemSize];
			}
		}

		_itemSize = itemSize;
		_count = count;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithItems: (const void *)items
		     itemSize: (size_t)itemSize
			count: (size_t)count
{
	self = [self initWithItemSize: itemSize
				count: count];

	memcpy(_items, items, count * itemSize);

	return self;
}

- (instancetype)initWithItemsNoCopy: (void *)items
			   itemSize: (size_t)itemSize
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	self = [self initWithItems: items
			  itemSize: itemSize
			     count: count];

	if (freeWhenDone) {
		of_explicit_memset(items, 0, count * itemSize);
		free(items);
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	OF_INVALID_INIT_METHOD
}
#endif

- (instancetype)initWithContentsOfURL: (OFURL *)URL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStringRepresentation: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithBase64EncodedString: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	size_t pageSize = [OFSystemInfo pageSize];

	if (_count * _itemSize > pageSize)
		unmapPages(_items,
		    OF_ROUND_UP_POW2(pageSize, _count * _itemSize) / pageSize);
	else if (_page != NULL) {
		if (_items != NULL)
			freeMemory(_page, _items, _count * _itemSize);

		removePageIfEmpty(_page);
	}

	[super dealloc];
}

- (void *)mutableItems
{
	return _items;
}

- (void *)mutableItemAtIndex: (size_t)idx
{
	if (idx >= _count)
		@throw [OFOutOfRangeException exception];

	return _items + idx * _itemSize;
}

- (void)zero
{
	of_explicit_memset(_items, 0, _count * _itemSize);
}

- (id)copy
{
	return [[OFSecureData alloc] initWithItems: _items
					  itemSize: _itemSize
					     count: _count];
}

- (id)mutableCopy
{
	return [[OFSecureData alloc] initWithItems: _items
					  itemSize: _itemSize
					     count: _count];
}

- (bool)isEqual: (id)object
{
	OFData *otherData;
	unsigned char diff;

	if (![object isKindOfClass: [OFData class]])
		return false;

	otherData = object;

	if (otherData->_count != _count || otherData->_itemSize != _itemSize)
		return false;

	diff = 0;

	for (size_t i = 0; i < _count * _itemSize; i++)
		diff |= otherData->_items[i] ^ _items[i];

	return (diff == 0);
}

- (OFString *)description
{
	return @"<OFSecureData>";
}

- (OFString *)stringRepresentation
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)stringByBase64Encoding
{
	OF_UNRECOGNIZED_SELECTOR
}

#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}
#endif

- (void)writeToURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFXMLElement *)XMLElementBySerializing
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFData *)messagePackRepresentation
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
