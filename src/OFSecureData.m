/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <stdlib.h>

#ifdef HAVE_SYS_MMAN_H
# include <sys/mman.h>
#endif

#import "OFSecureData.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@implementation OFSecureData
+ (bool)isSecure
{
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	return true;
#else
	return false;
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
		size_t size;
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
		size_t pageSize;
#endif

		if OF_UNLIKELY (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		if OF_UNLIKELY (count > SIZE_MAX / itemSize)
			@throw [OFOutOfRangeException exception];

		size = itemSize * count;
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
		pageSize = [OFSystemInfo pageSize];
		_mappingSize = OF_ROUND_UP_POW2(pageSize, size);

		if OF_UNLIKELY (_mappingSize < size)
			@throw [OFOutOfRangeException exception];

		if OF_UNLIKELY ((_items = mmap(NULL, _mappingSize,
		    PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0)) ==
		    MAP_FAILED)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: _mappingSize];

		if OF_UNLIKELY (mlock(_items, _mappingSize) != 0)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: _mappingSize];
#else
		if OF_UNLIKELY ((_items = malloc(size)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: size];
#endif

		_itemSize = itemSize;
		_count = count;

		[self zero];
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
	[self zero];

#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	munlock(_items, _mappingSize);
	munmap(_items, _mappingSize);
#else
	free(_items);
#endif

	[super dealloc];
}

- (void)zero
{
#if defined(HAVE_MMAP) && defined(HAVE_MLOCK) && defined(MAP_ANON)
	of_explicit_memset(_items, 0, _mappingSize);
#else
	of_explicit_memset(_items, 0, _count * _itemSize);
#endif
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
