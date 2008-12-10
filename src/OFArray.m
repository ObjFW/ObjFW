/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdio.h>
#import <string.h>
#import <unistd.h>

#import "OFArray.h"
#import "OFExceptions.h"
#import "OFMacros.h"

static size_t lastpagebyte = 0;

@implementation OFArray
+ newWithItemSize: (size_t)is
{
	return [[self alloc] initWithItemSize: is];
}

- initWithItemSize: (size_t)is
{
	if ((self = [super init])) {
		data = NULL;
		itemsize = is;
		items = 0;
	}

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

- (void*)item: (size_t)item
{
	if (item >= items)
		@throw [OFOutOfRangeException newWithObject: self];

	return data + item * itemsize;
}

- (void*)last
{
	return data + (items - 1) * itemsize;
}

- add: (void*)item
{
	if (SIZE_MAX - items < 1)
		@throw [OFOutOfRangeException newWithObject: self];

	data = [self resizeMem: data
		      toNItems: items + 1
			ofSize: itemsize];

	memcpy(data + items++ * itemsize, item, itemsize);

	return self;
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	if (nitems > SIZE_MAX - items)
		@throw [OFOutOfRangeException newWithObject: self];

	data = [self resizeMem: data
		      toNItems: items + nitems
			ofSize: itemsize];

	memcpy(data + items * itemsize, carray, nitems * itemsize);
	items += nitems;

	return self;
}

- removeNItems: (size_t)nitems
{
	if (nitems > items)
		@throw [OFOutOfRangeException newWithObject: self];

	data = [self resizeMem: data
		      toNItems: items - nitems
			ofSize: itemsize];

	items -= nitems;

	return self;
}
@end

@implementation OFBigArray
- initWithItemSize: (size_t)is
{
	if (lastpagebyte == 0)
		lastpagebyte = getpagesize() - 1;

	if ((self = [super initWithItemSize: is]))
		size = 0;

	return self;
}

- add: (void*)item
{
	size_t nsize;

	if (SIZE_MAX - items < 1 || items + 1 > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithObject: self];

	nsize = ((items + 1) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	memcpy(data + items++ * itemsize, item, itemsize);
	size = nsize;

	return self;
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	size_t nsize;

	if (nitems > SIZE_MAX - items || items + nitems > SIZE_MAX / itemsize)
		@throw [OFOutOfRangeException newWithObject: self];

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
		@throw [OFOutOfRangeException newWithObject: self];

	nsize = ((items - nitems) * itemsize + lastpagebyte) & ~lastpagebyte;

	if (size != nsize)
		data = [self resizeMem: data
				toSize: nsize];

	items -= nitems;
	size = nsize;

	return self;
}
@end
