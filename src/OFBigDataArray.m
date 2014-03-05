/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <string.h>

#import "OFBigDataArray.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

@implementation OFBigDataArray
- init
{
	return [self initWithItemSize: 1
			     capacity: 0];
}

- initWithItemSize: (size_t)itemSize
{
	return [self initWithItemSize: itemSize
			     capacity: 0];
}

- initWithItemSize: (size_t)itemSize
	  capacity: (size_t)capacity
{
	self = [super init];

	@try {
		size_t size, pageSize;

		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		if (capacity > SIZE_MAX / itemSize)
			@throw [OFOutOfRangeException exception];

		pageSize = [OFSystemInfo pageSize];
		size = OF_ROUND_UP_POW2(pageSize, capacity * itemSize);

		if (size == 0)
			size = pageSize;

		_items = [self allocMemoryWithSize: size];

		_itemSize = itemSize;
		_capacity = size / itemSize;
		_size = size;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)addItem: (const void*)item
{
	if (SIZE_MAX - _count < 1 || _count + 1 > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exception];

	if (_count + 1 > _capacity) {
		size_t size, pageSize;

		pageSize = [OFSystemInfo pageSize];
		size = OF_ROUND_UP_POW2(pageSize, (_count + 1) * _itemSize);

		_items = [self resizeMemory: _items
				       size: size];

		_capacity = size / _itemSize;
		_size = size;
	}

	memcpy(_items + _count * _itemSize, item, _itemSize);

	_count++;
}

- (void)addItems: (const void*)items
	   count: (size_t)count
{
	if (count > SIZE_MAX - _count || _count + count > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		size_t size, pageSize;

		pageSize = [OFSystemInfo pageSize];
		size = OF_ROUND_UP_POW2(pageSize, (_count + count) * _itemSize);

		_items = [self resizeMemory: _items
				       size: size];

		_capacity = size / _itemSize;
		_size = size;
	}

	memcpy(_items + _count * _itemSize, items, count * _itemSize);

	_count += count;
}

- (void)insertItems: (const void*)items
	    atIndex: (size_t)index
	      count: (size_t)count
{
	if (count > SIZE_MAX - _count || index > _count ||
	    _count + count > SIZE_MAX / _itemSize)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		size_t size, pageSize;

		pageSize = [OFSystemInfo pageSize];
		size = OF_ROUND_UP_POW2(pageSize, (_count + count) * _itemSize);

		_items = [self resizeMemory: _items
				       size: size];

		_capacity = size / _itemSize;
		_size = size;
	}

	memmove(_items + (index + count) * _itemSize,
	    _items + index * _itemSize, (_count - index) * _itemSize);
	memcpy(_items + index * _itemSize, items, count * _itemSize);

	_count += count;
}

- (void)removeItemsInRange: (of_range_t)range
{
	size_t pageSize, size;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exception];

	memmove(_items + range.location * _itemSize,
	    _items + (range.location + range.length) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	pageSize = [OFSystemInfo pageSize];
	size = OF_ROUND_UP_POW2(pageSize, _count * _itemSize);

	if (_size != size && size >= pageSize) {
		@try {
			_items = [self resizeMemory: _items
					       size: size];
			_capacity = size / _itemSize;
			_size = size;
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}
	}
}

- (void)removeLastItem
{
	size_t pageSize, size;

	if (_count == 0)
		return;

	_count--;
	pageSize = [OFSystemInfo pageSize];
	size = OF_ROUND_UP_POW2(pageSize, _count * _itemSize);

	if (_size != size && size >= pageSize) {
		@try {
			_items = [self resizeMemory: _items
					       size: size];
			_capacity = size / _itemSize;
			_size = size;
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}
	}
}

- (void)removeAllItems
{
	size_t pageSize = [OFSystemInfo pageSize];

	@try {
		_items = [self resizeMemory: _items
				       size: pageSize];
		_capacity = pageSize / _itemSize;
		_size = pageSize;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}

	_count = 0;
}
@end
