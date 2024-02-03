/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <limits.h>
#include <string.h>

#import "OFConcreteData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteData
- (instancetype)init
{
	return [self initWithItemSize: 1];
}

- (instancetype)initWithItemSize: (size_t)itemSize
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_itemSize = itemSize;
		_freeWhenDone = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = OFAllocMemory(count, itemSize);
		_capacity = _count = count;
		_itemSize = itemSize;
		_freeWhenDone = true;

		memcpy(_items, items, count * itemSize);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = (unsigned char *)items;
		_capacity = _count = count;
		_itemSize = itemSize;
		_freeWhenDone = freeWhenDone;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
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
@end
