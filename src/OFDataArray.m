/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

#import "OFDataArray.h"
#import "OFExceptions.h"
#import "OFMacros.h"

static size_t lastpagebyte = 0;
extern int getpagesize(void);

@implementation OFDataArray
+ dataArrayWithItemSize: (size_t)is
{
	return [[[OFDataArray alloc] initWithItemSize: is] autorelease];
}

+ bigDataArrayWithItemSize: (size_t)is
{
	return [[[OFBigDataArray alloc] initWithItemSize: is] autorelease];
}

- initWithItemSize: (size_t)is
{
	Class c;

	self = [super init];

	if (is == 0) {
		c = isa;
		[super free];
		@throw [OFInvalidArgumentException newWithClass: c];
	}

	data = NULL;
	itemsize = is;
	count = 0;

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

- (void*)data
{
	return data;
}

- (void*)item: (size_t)index
{
	if (index >= count)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data + index * itemsize;
}

- (void*)last
{
	return data + (count - 1) * itemsize;
}

- add: (void*)item
{
	if (SIZE_MAX - count < 1)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: count + 1
		      withSize: itemsize];

	memcpy(data + count++ * itemsize, item, itemsize);

	return self;
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	if (nitems > SIZE_MAX - count)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: count + nitems
		      withSize: itemsize];

	memcpy(data + count * itemsize, carray, nitems * itemsize);
	count += nitems;

	return self;
}

- removeNItems: (size_t)nitems
{
	if (nitems > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: count - nitems
		      withSize: itemsize];

	count -= nitems;

	return self;
}

- (id)copy
{
	OFDataArray *new = [OFDataArray dataArrayWithItemSize: itemsize];
	[new addNItems: count
	    fromCArray: data];

	return new;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFDataArray class]])
		return NO;
	if ([obj count] != count || [obj itemsize] != itemsize)
		return NO;
	if (memcmp([obj data], data, count * itemsize))
		return NO;

	return YES;
}

- (int)compare: (id)obj
{
	int ret;

	if (![obj isKindOf: [OFDataArray class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];
	if ([obj itemsize] != itemsize)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	if ([obj count] == count)
		return memcmp(data, [obj data], count * itemsize);

	if (count > [obj count]) {
		if ((ret = memcmp(data, [obj data], [obj count] * itemsize)))
			return ret;

		return *(char*)[self item: [obj count]];
	} else {
		if ((ret = memcmp(data, [obj data], count * itemsize)))
			return ret;

		return *(char*)[obj item: count] * -1;
	}
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

	if (lastpagebyte == 0)
		lastpagebyte = getpagesize() - 1;
	size = 0;

	return self;
}

- add: (void*)item
{
	size_t nsize;

	if (SIZE_MAX - count < 1 || count + 1 > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((count + 1) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
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
		data = [self resizeMem: data
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

	nsize = ((count - nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	count -= nitems;
	size = nsize;

	return self;
}

- (id)copy
{
	OFDataArray *new = [OFDataArray bigDataArrayWithItemSize: itemsize];

	[new addNItems: count
	    fromCArray: data];

	return new;
}
@end
