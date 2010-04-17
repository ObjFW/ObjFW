/*
 * Copyright (c) 2008 - 2010
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
#include <limits.h>

#import "OFDataArray.h"
#import "OFExceptions.h"
#import "macros.h"

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

- (size_t)itemSize
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

- (void)addItem: (void*)item
{
	if (SIZE_MAX - count < 1)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMemory: data
			 toNItems: count + 1
			 withSize: itemsize];

	memcpy(data + count * itemsize, item, itemsize);

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
			 withSize: itemsize];

	memcpy(data + count * itemsize, carray, nitems * itemsize);
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
			 withSize: itemsize];

	memmove(data + (index + nitems) * itemsize, data + index * itemsize,
	    (count - index) * itemsize);
	memcpy(data + index * itemsize, carray, nitems * itemsize);

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
				 withSize: itemsize];
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

	memmove(data + index * itemsize, data + (index + nitems) * itemsize,
	    (count - index - nitems) * itemsize);

	count -= nitems;
	@try {
		data = [self resizeMemory: data
				 toNItems: count
				 withSize: itemsize];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e dealloc];
	}
}

- copy
{
	OFDataArray *new = [[OFDataArray alloc] initWithItemSize: itemsize];
	[new addNItems: count
	    fromCArray: data];

	return new;
}

- (BOOL)isEqual: (OFObject*)obj
{
	if (![obj isKindOfClass: [OFDataArray class]])
		return NO;
	if ([(OFDataArray*)obj count] != count ||
	    [(OFDataArray*)obj itemSize] != itemsize)
		return NO;
	if (memcmp([(OFDataArray*)obj cArray], data, count * itemsize))
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
	if ([ary itemSize] != itemsize)
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
- (void)addItem: (void*)item
{
	size_t nsize, lastpagebyte;

	if (SIZE_MAX - count < 1 || count + 1 > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + 1) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count * itemsize, item, itemsize);

	count++;
	size = nsize;
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
{
	size_t nsize, lastpagebyte;

	if (nitems > SIZE_MAX - count || count + nitems > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];

	memcpy(data + count * itemsize, carray, nitems * itemsize);

	count += nitems;
	size = nsize;
}

- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
	  atIndex: (size_t)index
{
	size_t nsize, lastpagebyte;

	if (nitems > SIZE_MAX - count || count + nitems > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	lastpagebyte = of_pagesize - 1;
	nsize = ((count + nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				 toNItems: nsize
				 withSize: itemsize];

	memmove(data + (index + nitems) * itemsize, data + index * itemsize,
	    (count - index) * itemsize);
	memcpy(data + index * itemsize, carray, nitems * itemsize);

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
	nsize = (count * itemsize + lastpagebyte) & ~lastpagebyte;

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

	memmove(data + index * itemsize, data + (index + nitems) * itemsize,
	    (count - index - nitems) * itemsize);

	count -= nitems;
	lastpagebyte = of_pagesize - 1;
	nsize = (count * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMemory: data
				   toSize: nsize];
	size = nsize;
}

- copy
{
	OFDataArray *new = [[OFBigDataArray alloc] initWithItemSize: itemsize];

	[new addNItems: count
	    fromCArray: data];

	return new;
}
@end
