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

#import "OFConcreteMutableData.h"
#import "OFConcreteData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteMutableData
+ (void)initialize
{
	if (self == [OFConcreteMutableData class])
		[self inheritMethodsFromClass: [OFConcreteData class]];
}

- (instancetype)initWithItemSize: (size_t)itemSize capacity: (size_t)capacity
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = OFAllocMemory(capacity, itemSize);
		_itemSize = itemSize;
		_capacity = capacity;
		_freeWhenDone = true;
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
	self = [self initWithItems: items count: count itemSize: itemSize];

	if (freeWhenDone)
		OFFreeMemory(items);

	return self;
}

- (void *)mutableItems
{
	return _items;
}

- (void)addItem: (const void *)item
{
	if (SIZE_MAX - _count < 1)
		@throw [OFOutOfRangeException exception];

	if (_count + 1 > _capacity) {
		_items = OFResizeMemory(_items, _count + 1, _itemSize);
		_capacity = _count + 1;
	}

	memcpy(_items + _count * _itemSize, item, _itemSize);

	_count++;
}

- (void)addItems: (const void *)items count: (size_t)count
{
	if (count > SIZE_MAX - _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = OFResizeMemory(_items, _count + count, _itemSize);
		_capacity = _count + count;
	}

	memcpy(_items + _count * _itemSize, items, count * _itemSize);
	_count += count;
}

- (void)insertItems: (const void *)items
	    atIndex: (size_t)idx
	      count: (size_t)count
{
	if (count > SIZE_MAX - _count || idx > _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = OFResizeMemory(_items, _count + count, _itemSize);
		_capacity = _count + count;
	}

	memmove(_items + (idx + count) * _itemSize, _items + idx * _itemSize,
	    (_count - idx) * _itemSize);
	memcpy(_items + idx * _itemSize, items, count * _itemSize);

	_count += count;
}

- (void)increaseCountBy: (size_t)count
{
	if (count > SIZE_MAX - _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = OFResizeMemory(_items, _count + count, _itemSize);
		_capacity = _count + count;
	}

	memset(_items + _count * _itemSize, '\0', count * _itemSize);
	_count += count;
}

- (void)removeItemsInRange: (OFRange)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exception];

	memmove(_items + range.location * _itemSize,
	    _items + (range.location + range.length) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	@try {
		_items = OFResizeMemory(_items, _count, _itemSize);
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)removeLastItem
{
	if (_count == 0)
		return;

	_count--;
	@try {
		_items = OFResizeMemory(_items, _count, _itemSize);
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}
}

- (void)removeAllItems
{
	OFFreeMemory(_items);
	_items = NULL;
	_count = 0;
	_capacity = 0;
}

- (void)makeImmutable
{
	if (_capacity != _count) {
		@try {
			_items = OFResizeMemory(_items, _count, _itemSize);
			_capacity = _count;
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}
	}

	object_setClass(self, [OFConcreteData class]);
}
@end
