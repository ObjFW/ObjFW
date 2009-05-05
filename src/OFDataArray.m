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
	items = 0;

	return self;
}

- (size_t)items
{
	return items;
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
	if (index >= items)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data + index * itemsize;
}

- (void*)last
{
	return data + (items - 1) * itemsize;
}

- add: (void*)item
{
	if (SIZE_MAX - items < 1)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: items + 1
		      withSize: itemsize];

	memcpy(data + items++ * itemsize, item, itemsize);

	return self;
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	if (nitems > SIZE_MAX - items)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: items + nitems
		      withSize: itemsize];

	memcpy(data + items * itemsize, carray, nitems * itemsize);
	items += nitems;

	return self;
}

- removeNItems: (size_t)nitems
{
	if (nitems > items)
		@throw [OFOutOfRangeException newWithClass: isa];

	data = [self resizeMem: data
		      toNItems: items - nitems
		      withSize: itemsize];

	items -= nitems;

	return self;
}

- (id)copy
{
	OFDataArray *new = [OFDataArray dataArrayWithItemSize: itemsize];
	[new addNItems: items
	    fromCArray: data];

	return new;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFDataArray class]])
		return NO;
	if ([obj items] != items || [obj itemsize] != itemsize)
		return NO;
	if (memcmp([obj data], data, items * itemsize))
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

	if ([obj items] == items)
		return memcmp(data, [obj data], items * itemsize);

	if (items > [obj items]) {
		if ((ret = memcmp(data, [obj data], [obj items] * itemsize)))
			return ret;

		return *(char*)[self item: [obj items]];
	} else {
		if ((ret = memcmp(data, [obj data], items * itemsize)))
			return ret;

		return *(char*)[obj item: [self items]] * -1;
	}
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < items * itemsize; i++)
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

	if (SIZE_MAX - items < 1 || items + 1 > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((items + 1) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	memcpy(data + items++ * itemsize, item, itemsize);
	size = nsize;

	return self;
}

-  addNItems: (size_t)nitems
  fromCArray: (void*)carray
{
	size_t nsize;

	if (nitems > SIZE_MAX - items || items + nitems > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((items + nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	memcpy(data + items * itemsize, carray, nitems * itemsize);
	items += nitems;
	size = nsize;

	return self;
}

- removeNItems: (size_t)nitems
{
	size_t nsize;

	if (nitems > items)
		@throw [OFOutOfRangeException newWithClass: isa];

	nsize = ((items - nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	items -= nitems;
	size = nsize;

	return self;
}

- (id)copy
{
	OFDataArray *new = [OFDataArray bigDataArrayWithItemSize: itemsize];

	[new addNItems: items
	    fromCArray: data];

	return new;
}
@end
