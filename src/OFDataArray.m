/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
#include <string.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFExceptions.h"
#import "macros.h"

@implementation OFDataArray
+ dataArrayWithItemSize: (size_t)is
{
	return [[[self alloc] initWithItemSize: is] autorelease];
}

+ dataArrayWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithItemSize: (size_t)is
{
	self = [super init];

	@try {
		if (is == 0)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		data = NULL;
		itemSize = is;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithContentsOfFile: (OFString*)path
{
	self = [super init];

	@try {
		OFFile *file = [[OFFile alloc] initWithPath: path
						       mode: @"rb"];
		itemSize = 1;

		@try {
			char *buf = [self allocMemoryWithSize: of_pagesize];

			while (![file isAtEndOfStream]) {
				size_t size;

				size = [file readNBytes: of_pagesize
					     intoBuffer: buf];
				[self addNItems: size
				     fromCArray: buf];
			}

			[self freeMemory: buf];
		} @finally {
			[file release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)count
{
	return count;
}

- (size_t)itemSize
{
	return itemSize;
}

- (void*)cArray
{
	return data;
}

- (void*)itemAtIndex: (size_t)index
{
	if (index >= count)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data + index * itemSize;
}

- (void*)firstItem
{
	if (data == NULL || count == 0)
		return NULL;

	return data;
}

- (void*)lastItem
{
	if (data == NULL || count == 0)
		return NULL;

	return data + (count - 1) * itemSize;
}

- (void)addItem: (void*)item
{
	if (SIZE_MAX - count < 1)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + 1
			 withSize: itemSize];

	memcpy(data + count * itemSize, item, itemSize);

	count++;
}

- (void)addItem: (void*)item
	atIndex: (size_t)index
{
	[self addNItems: 1
	     fromCArray: item
		atIndex: index];
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
{
	if (nitems > SIZE_MAX - count)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + nitems
			 withSize: itemSize];

	memcpy(data + count * itemSize, carray, nitems * itemSize);
	count += nitems;
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
	  atIndex: (size_t)index
{
	if (nitems > SIZE_MAX - count)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + nitems
			 withSize: itemSize];

	memmove(data + (index + nitems) * itemSize, data + index * itemSize,
	    (count - index) * itemSize);
	memcpy(data + index * itemSize, carray, nitems * itemSize);

	count += nitems;
}

- (void)removeItemAtIndex: (size_t)index
{
	[self removeNItems: 1
		   atIndex: index];
}

- (void)removeNItems: (size_t)nitems
{
	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];


	count -= nitems;
	@try {
		data = [self resizeMemory: data
				 toNItems: count
				 withSize: itemSize];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e dealloc];
	}
}

- (void)removeNItems: (size_t)nitems
	     atIndex: (size_t)index
{
	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(data + index * itemSize, data + (index + nitems) * itemSize,
	    (count - index - nitems) * itemSize);

	count -= nitems;
	@try {
		data = [self resizeMemory: data
				 toNItems: count
				 withSize: itemSize];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e dealloc];
	}
}

- copy
{
	OFDataArray *new = [[OFDataArray alloc] initWithItemSize: itemSize];
	[new addNItems: count
	    fromCArray: data];

	return new;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOfClass: [OFDataArray class]])
		return NO;
	if ([(OFDataArray*)obj count] != count ||
	    [(OFDataArray*)obj itemSize] != itemSize)
		return NO;
	if (memcmp([(OFDataArray*)obj cArray], data, count * itemSize))
		return NO;

	return YES;
}

- (of_comparison_result_t)compare: (id)obj
{
	int cmp;
	size_t ary_count, min_count;

	if (![obj isKindOfClass: [OFDataArray class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	if ([(OFDataArray*)obj itemSize] != itemSize)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	ary_count = [(OFDataArray*)obj count];
	min_count = (count > ary_count ? ary_count : count);

	if ((cmp = memcmp(data, [(OFDataArray*)obj cArray],
	    min_count * itemSize)) == 0) {
		if (count > ary_count)
			return OF_ORDERED_DESCENDING;
		if (count < ary_count)
			return OF_ORDERED_ASCENDING;
		return OF_ORDERED_SAME;
	}

	if (cmp > 0)
		return OF_ORDERED_DESCENDING;
	else
		return OF_ORDERED_ASCENDING;
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < count * itemSize; i++)
		OF_HASH_ADD(hash, ((char*)data)[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

@implementation OFBigDataArray
- (void)addItem: (void*)item
{
	size_t nsize, lastpagebyte;

	if (SIZE_MAX - count < 1 || count + 1 > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + 1) * itemSize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count * itemSize, item, itemSize);

	count++;
	size = nsize;
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
{
	size_t nsize, lastpagebyte;

	if (nitems > SIZE_MAX - count || count + nitems > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + nitems) * itemSize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count * itemSize, carray, nitems * itemSize);

	count += nitems;
	size = nsize;
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
	  atIndex: (size_t)index
{
	size_t nsize, lastpagebyte;

	if (nitems > SIZE_MAX - count || count + nitems > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + nitems) * itemSize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				 toNItems: nsize
				 withSize: itemSize];

	memmove(data + (index + nitems) * itemSize, data + index * itemSize,
	    (count - index) * itemSize);
	memcpy(data + index * itemSize, carray, nitems * itemSize);

	count += nitems;
	size = nsize;
}

- (void)removeNItems: (size_t)nitems
{
	size_t nsize, lastpagebyte;

	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	count -= nitems;
	lastpagebyte = of_pagesize - 1;
	nsize = (count * itemSize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];
	size = nsize;
}

- (void)removeNItems: (size_t)nitems
	     atIndex: (size_t)index
{
	size_t nsize, lastpagebyte;

	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(data + index * itemSize, data + (index + nitems) * itemSize,
	    (count - index - nitems) * itemSize);

	count -= nitems;
	lastpagebyte = of_pagesize - 1;
	nsize = (count * itemSize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];
	size = nsize;
}

- copy
{
	OFDataArray *new = [[OFBigDataArray alloc] initWithItemSize: itemSize];

	[new addNItems: count
	    fromCArray: data];

	return new;
}
@end
