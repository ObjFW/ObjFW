/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifdef _WIN32
#include <windows.h>
#endif

static int lastpagebyte = 0;

@implementation OFDataArray
+ dataArrayWithItemSize: (size_t)is
{
	return [[[self alloc] initWithItemSize: is] autorelease];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithItemSize: (size_t)is
{
	Class c;

	self = [super init];

	if (is == 0) {
		c = isa;
		[super dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	data = NULL;
	itemsize = is;

	return self;
}

- (size_t)count
{
	return count;
}

- (size_t)itemsize
{
	return itemsize;
}

- (void*)cArray
{
	return data;
}

- (void*)itemAtIndex: (size_t)index
{
	if (index >= count)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data + index * itemsize;
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

	return data + (count - 1) * itemsize;
}

- addItem: (void*)item
{
	if (SIZE_MAX - count < 1)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + 1
			 withSize: itemsize];

	memcpy(data + count++ * itemsize, item, itemsize);

	return self;
}

-  addNItems: (size_t)nitems
  fromCArray: (void*)carray
{
	if (nitems > SIZE_MAX - count)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + nitems
			 withSize: itemsize];

	memcpy(data + count * itemsize, carray, nitems * itemsize);
	count += nitems;

	return self;
}

- removeItemAtIndex: (size_t)index
{
	return [self removeNItems: 1
			  atIndex: index];
}

- removeNItems: (size_t)nitems
{
	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];


	count -= nitems;
	data = [self resizeMemory: data
			 toNItems: count
			 withSize: itemsize];

	return self;
}

- removeNItems: (size_t)nitems
       atIndex: (size_t)index
{
	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(data + index * itemsize, data + (index + nitems) * itemsize,
	    nitems * itemsize);

	count -= nitems;
	data = [self resizeMemory: data
			 toNItems: count
			 withSize: itemsize];

	return self;
}

- (id)copy
{
	OFDataArray *new = [[OFDataArray alloc] initWithItemSize: itemsize];
	[new addNItems: count
	    fromCArray: data];

	return new;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOfClass: [OFDataArray class]])
		return NO;
	if ([obj count] != count || [obj itemsize] != itemsize)
		return NO;
	if (memcmp([obj cArray], data, count * itemsize))
		return NO;

	return YES;
}

- (of_comparison_result_t)compare: (OFDataArray*)ary
{
	int cmp;
	size_t ary_count, min_count;

	if (![ary isKindOfClass: [OFDataArray class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	if ([ary itemsize] != itemsize)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	ary_count = [ary count];
	min_count = (count > ary_count ? ary_count : count);

	if ((cmp = memcmp(data, [ary cArray], min_count * itemsize)) == 0) {
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
	for (i = 0; i < count * itemsize; i++)
		OF_HASH_ADD(hash, ((char*)data)[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

@implementation OFBigDataArray
- initWithItemSize: (size_t)is
{
	self = [super initWithItemSize: is];

	if (lastpagebyte == 0) {
#ifndef _WIN32
		if ((lastpagebyte = sysconf(_SC_PAGESIZE)) == -1)
			lastpagebyte = 4096;
		lastpagebyte--;
#else
		SYSTEM_INFO si;
		GetSystemInfo(&si);
		lastpagebyte = si.dwPageSize - 1;
#endif
	}

	return self;
}

- addItem: (void*)item
{
	size_t nsize;

	if (SIZE_MAX - count < 1 || count + 1 > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((count + 1) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count++ * itemsize, item, itemsize);
	size = nsize;

	return self;
}

-  addNItems: (size_t)nitems
  fromCArray: (void*)carray
{
	size_t nsize;

	if (nitems > SIZE_MAX - count || count + nitems > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((count + nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count * itemsize, carray, nitems * itemsize);
	count += nitems;
	size = nsize;

	return self;
}

- removeNItems: (size_t)nitems
{
	size_t nsize;

	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	count -= nitems;
	nsize = (count * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];
	size = nsize;

	return self;
}

- removeNItems: (size_t)nitems
       atIndex: (size_t)index
{
	size_t nsize;

	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(data + index * itemsize, data + (index + nitems) * itemsize,
	    nitems * itemsize);

	count -= nitems;
	nsize = (count * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];
	size = nsize;

	return self;
}

- (id)copy
{
	OFDataArray *new = [[OFBigDataArray alloc] initWithItemSize: itemsize];

	[new addNItems: count
	    fromCArray: data];

	return new;
}
@end
