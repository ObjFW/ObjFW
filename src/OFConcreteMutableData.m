/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <limits.h>
#include <string.h>

#import "OFConcreteMutableData.h"
#import "OFConcreteData.h"
#import "OFIndexSet.h"
#import "OFIndexSet+Private.h"

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
		objc_release(self);
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

- (void)insertItems: (const void *)items atIndexes: (OFIndexSet *)indexes
{
	const OFRange *ranges = indexes.of_ranges.items;
	size_t rangesCount = indexes.of_ranges.count, count = _count;

	for (size_t i = 0; i < rangesCount; i++) {
		if (ranges[i].length > SIZE_MAX - count)
			@throw [OFOutOfRangeException exception];

		count += ranges[i].length;
	}

	if (count > _capacity) {
		_items = OFResizeMemory(_items, count, _itemSize);
		_capacity = count;
	}

	for (size_t i = 0; i < rangesCount; i++) {
		OFRange range = ranges[i];

		if (range.location > _count)
			@throw [OFOutOfRangeException exception];

		memmove(_items + OFEndOfRange(range) * _itemSize,
		    _items + range.location * _itemSize,
		    (_count - range.location) * _itemSize);
		memcpy(_items + range.location * _itemSize, items,
		    range.length * _itemSize);

		items = (char *)items + range.length * _itemSize;
		_count += range.length;
	}
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
	if (OFEndOfRange(range) > _count)
		@throw [OFOutOfRangeException exception];

	memmove(_items + range.location * _itemSize,
	    _items + OFEndOfRange(range) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	@try {
		_items = OFResizeMemory(_items, _count, _itemSize);
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}
}

- (void)removeItemsAtIndexes: (OFIndexSet *)indexes
{
	void *pool = objc_autoreleasePoolPush();
	const OFRange *ranges = indexes.of_ranges.items;
	size_t count = indexes.of_ranges.count;

	if (count == 0) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	for (size_t i = count; i > 0; i--) {
		OFRange range = ranges[i - 1];

		if (OFEndOfRange(range) > _count)
			@throw [OFOutOfRangeException exception];

		memmove(_items + range.location * _itemSize,
		    _items + OFEndOfRange(range) * _itemSize,
		    (_count - range.location - range.length) * _itemSize);

		_count -= range.length;
	}

	@try {
		_items = OFResizeMemory(_items, _count, _itemSize);
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
	}

	objc_autoreleasePoolPop(pool);
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
