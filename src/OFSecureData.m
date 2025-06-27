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

#include <errno.h>
#include <stdlib.h>

#ifdef HAVE_SYS_MMAN_H
# include <sys/mman.h>
#endif

#import "OFSecureData.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#ifdef OF_HAVE_THREADS
# import "OFTLSKey.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
static const size_t chunkSize = 16;

struct Page {
	struct Page *next, *previous;
	unsigned long *map;
	unsigned char *page;
};

# if defined(OF_HAVE_COMPILER_TLS)
static thread_local struct Page *firstPage = NULL;
static thread_local struct Page *lastPage = NULL;
static thread_local struct Page **preallocatedPages = NULL;
static thread_local size_t numPreallocatedPages = 0;
# elif defined(OF_HAVE_THREADS)
static OFTLSKey firstPageKey, lastPageKey;
static OFTLSKey preallocatedPagesKey, numPreallocatedPagesKey;
# else
static struct Page *firstPage = NULL;
static struct Page *lastPage = NULL;
static struct Page **preallocatedPages = NULL;
static size_t numPreallocatedPages = 0;
# endif

static void *
mapPages(size_t numPages)
{
	size_t pageSize = [OFSystemInfo pageSize];
	void *pointer;

	if (numPages > SIZE_MAX / pageSize)
		@throw [OFOutOfRangeException exception];

	if ((pointer = mmap(NULL, numPages * pageSize, PROT_READ | PROT_WRITE,
	    MAP_PRIVATE | MAP_ANON, -1, 0)) == MAP_FAILED)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: numPages * pageSize];

	if (mlock(pointer, numPages * pageSize) != 0) {
		munmap(pointer, numPages * pageSize);
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: numPages * pageSize];
	}

	return pointer;
}

static void
unmapPages(void *pointer, size_t numPages)
{
	size_t pageSize = [OFSystemInfo pageSize];

	if (numPages > SIZE_MAX / pageSize)
		@throw [OFOutOfRangeException exception];

	munlock(pointer, numPages * pageSize);
	munmap(pointer, numPages * pageSize);
}

static struct Page *
addPage(bool allowPreallocated)
{
	size_t pageSize = [OFSystemInfo pageSize];
	size_t mapSize = OFRoundUpToPowerOf2(OF_ULONG_BIT,
	    pageSize / chunkSize) / OF_ULONG_BIT;
	struct Page *page;
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	struct Page *lastPage;
# endif

	if (allowPreallocated) {
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		uintptr_t numPreallocatedPages =
		    (uintptr_t)OFTLSKeyGet(numPreallocatedPagesKey);
# endif

		if (numPreallocatedPages > 0) {
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			struct Page **preallocatedPages =
			    OFTLSKeyGet(preallocatedPagesKey);
# endif

			numPreallocatedPages--;
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			OFEnsure(OFTLSKeySet(numPreallocatedPagesKey,
			    (void *)numPreallocatedPages) == 0);
# endif

			page = preallocatedPages[numPreallocatedPages];

			if (numPreallocatedPages == 0) {
				OFFreeMemory(preallocatedPages);
				preallocatedPages = NULL;
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
				OFEnsure(OFTLSKeySet(preallocatedPagesKey,
				    preallocatedPages) == 0);
# endif
			}

			return page;
		}
	}

	page = OFAllocMemory(1, sizeof(*page));
	@try {
		page->map = OFAllocZeroedMemory(mapSize, sizeof(unsigned long));
	} @catch (id e) {
		OFFreeMemory(page);
		@throw e;
	}
	@try {
		page->page = mapPages(1);
	} @catch (id e) {
		OFFreeMemory(page->map);
		OFFreeMemory(page);
		@throw e;
	}
	OFZeroMemory(page->page, pageSize);

# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	lastPage = OFTLSKeyGet(lastPageKey);
# endif

	page->previous = lastPage;
	page->next = NULL;

	if (lastPage != NULL)
		lastPage->next = page;

# if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
	lastPage = page;

	if (firstPage == NULL)
		firstPage = page;
# else
	OFEnsure(OFTLSKeySet(lastPageKey, page) == 0);

	if (OFTLSKeyGet(firstPageKey) == NULL)
		OFEnsure(OFTLSKeySet(firstPageKey, page) == 0);
# endif

	return page;
}

static void
removePageIfEmpty(struct Page *page)
{
	unsigned long *map = page->map;
	size_t pageSize = [OFSystemInfo pageSize];
	size_t mapSize = OFRoundUpToPowerOf2(OF_ULONG_BIT,
	    pageSize / chunkSize) / OF_ULONG_BIT;

	for (size_t i = 0; i < mapSize; i++)
		if (map[i] != 0)
			return;

	unmapPages(page->page, 1);
	OFFreeMemory(page->map);

	if (page->previous != NULL)
		page->previous->next = page->next;
	if (page->next != NULL)
		page->next->previous = page->previous;

# if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
	if (firstPage == page)
		firstPage = page->next;
	if (lastPage == page)
		lastPage = page->previous;
# else
	if (OFTLSKeyGet(firstPageKey) == page)
		OFEnsure(OFTLSKeySet(firstPageKey, page->next) == 0);
	if (OFTLSKeyGet(lastPageKey) == page)
		OFEnsure(OFTLSKeySet(lastPageKey, page->previous) == 0);
# endif

	OFFreeMemory(page);
}

static void *
allocateMemory(struct Page *page, size_t bytes)
{
	size_t chunks, chunksLeft, pageSize, i, firstChunk;

	bytes = OFRoundUpToPowerOf2(chunkSize, bytes);
	chunks = chunksLeft = bytes / chunkSize;
	firstChunk = 0;
	pageSize = [OFSystemInfo pageSize];

	for (i = 0; i < pageSize / chunkSize; i++) {
		if (OFBitSetIsSet(page->map, i)) {
			chunksLeft = chunks;
			firstChunk = i + 1;
			continue;
		}

		if (--chunksLeft == 0)
			break;
	}

	if (chunksLeft == 0) {
		for (size_t j = firstChunk; j < firstChunk + chunks; j++)
			OFBitSetSet(page->map, j);

		return page->page + (chunkSize * firstChunk);
	}

	return NULL;
}

static void
freeMemory(struct Page *page, void *pointer, size_t bytes)
{
	size_t chunks, chunkIndex;

	bytes = OFRoundUpToPowerOf2(chunkSize, bytes);
	chunks = bytes / chunkSize;
	chunkIndex = ((uintptr_t)pointer - (uintptr_t)page->page) / chunkSize;

	OFZeroMemory(pointer, bytes);

	for (size_t i = 0; i < chunks; i++)
		OFBitSetClear(page->map, chunkIndex + i);
}
#endif

@implementation OFSecureData
@synthesize allowsSwappableMemory = _allowsSwappableMemory;

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON) && \
    !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
+ (void)initialize
{
	if (self != [OFSecureData class])
		return;

	if (OFTLSKeyNew(&firstPageKey) != 0 || OFTLSKeyNew(&lastPageKey) != 0 ||
	    OFTLSKeyNew(&preallocatedPagesKey) != 0 ||
	    OFTLSKeyNew(&numPreallocatedPagesKey) != 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (void)preallocateUnswappableMemoryWithSize: (size_t)size
{
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	size_t pageSize = [OFSystemInfo pageSize];
	size_t numPages = OFRoundUpToPowerOf2(pageSize, size) / pageSize;
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	struct Page **preallocatedPages = OFTLSKeyGet(preallocatedPagesKey);
	size_t numPreallocatedPages;
# endif
	size_t i;

	if (preallocatedPages != NULL)
		@throw [OFInvalidArgumentException exception];

	preallocatedPages = OFAllocZeroedMemory(numPages, sizeof(struct Page));
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OFEnsure(OFTLSKeySet(preallocatedPagesKey, preallocatedPages) == 0);
# endif

	@try {
		for (i = 0; i < numPages; i++)
			preallocatedPages[i] = addPage(false);
	} @catch (id e) {
		for (size_t j = 0; j < i; j++)
			removePageIfEmpty(preallocatedPages[j]);

		OFFreeMemory(preallocatedPages);
		preallocatedPages = NULL;

		@throw e;
	}

	numPreallocatedPages = numPages;
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OFEnsure(OFTLSKeySet(numPreallocatedPagesKey,
	    (void *)(uintptr_t)numPreallocatedPages) == 0);
# endif
#else
	@throw [OFNotImplementedException exceptionWithSelector: _cmd
							 object: self];
#endif
}

+ (instancetype)dataWithCount: (size_t)count
	allowsSwappableMemory: (bool)allowsSwappableMemory
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCount: count
		  allowsSwappableMemory: allowsSwappableMemory]);
}

+ (instancetype)dataWithCount: (size_t)count
		     itemSize: (size_t)itemSize
	allowsSwappableMemory: (bool)allowsSwappableMemory
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCount: count
			       itemSize: itemSize
		  allowsSwappableMemory: allowsSwappableMemory]);
}

+ (instancetype)dataWithItems: (const void *)items count: (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	OF_UNRECOGNIZED_SELECTOR
}

#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}
#endif

+ (instancetype)dataWithContentsOfIRI: (OFIRI *)IRI
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

- (instancetype)initWithCount: (size_t)count
	allowsSwappableMemory: (bool)allowsSwappableMemory
{
	return [self initWithCount: count
			  itemSize: 1
	     allowsSwappableMemory: allowsSwappableMemory];
}

- (instancetype)initWithCount: (size_t)count
		     itemSize: (size_t)itemSize
	allowsSwappableMemory: (bool)allowsSwappableMemory
{
	self = [super init];

	@try {
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
		size_t pageSize = [OFSystemInfo pageSize];
#endif

		if (count > SIZE_MAX / itemSize)
			@throw [OFOutOfRangeException exception];

		if (allowsSwappableMemory) {
			_items = OFAllocMemory(count, itemSize);
			_freeWhenDone = true;
			memset(_items, 0, count * itemSize);
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
		} else if (count * itemSize >= pageSize)
			_items = mapPages(OFRoundUpToPowerOf2(pageSize,
			    count * itemSize) / pageSize);
		else {
# if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
			struct Page *lastPage = OFTLSKeyGet(lastPageKey);
# endif

			for (struct Page *page = lastPage; page != NULL;
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
#else
		} else
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: nil];
#endif

		_count = count;
		_itemSize = itemSize;
		_allowsSwappableMemory = allowsSwappableMemory;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItemSize: (size_t)itemSize
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItems: (const void *)items count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	OF_INVALID_INIT_METHOD
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path
{
	OF_INVALID_INIT_METHOD
}
#endif

- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI
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

- (void)dealloc
{
	[self zero];

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	if (!_allowsSwappableMemory) {
		size_t pageSize = [OFSystemInfo pageSize];
		/* Extra variable needed to work around a bug in GCC 15. */
		size_t count = _count;

		if (count * _itemSize > pageSize)
			unmapPages(_items,
			    OFRoundUpToPowerOf2(pageSize, count * _itemSize) /
			    pageSize);
		else if (_page != NULL) {
			if (_items != NULL)
				freeMemory(_page, _items, count * _itemSize);

			removePageIfEmpty(_page);
		}
	}
#endif

	if (_freeWhenDone)
		OFFreeMemory(_items);

	[super dealloc];
}

- (size_t)count
{
	return _count;
}

- (size_t)itemSize
{
	return _itemSize;
}

- (const void *)items
{
	return _items;
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
	OFZeroMemory(_items, _count * _itemSize);
}

- (id)copy
{
	OFSecureData *copy = [[OFSecureData alloc]
		    initWithCount: _count
			 itemSize: _itemSize
	    allowsSwappableMemory: _allowsSwappableMemory];

	memcpy(copy.mutableItems, _items, _count * _itemSize);

	return copy;
}

- (id)mutableCopy
{
	OFSecureData *copy = [[OFSecureData alloc]
		    initWithCount: _count
			 itemSize: _itemSize
	    allowsSwappableMemory: _allowsSwappableMemory];

	memcpy(copy.mutableItems, _items, _count * _itemSize);

	return copy;
}

- (bool)isEqual: (id)object
{
	OFData *otherData;
	const unsigned char *otherDataItems;
	unsigned char diff;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFData class]])
		return false;

	otherData = object;
	otherDataItems = otherData.items;

	if (otherData.count != _count || otherData.itemSize != _itemSize)
		return false;

	diff = 0;

	for (size_t i = 0; i < _count * _itemSize; i++)
		diff |= otherDataItems[i] ^ _items[i];

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

- (void)writeToIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFData *)messagePackRepresentation
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
