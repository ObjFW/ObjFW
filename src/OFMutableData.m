/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "OFMutableData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableData
+ (instancetype)data
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dataWithItemSize: (size_t)itemSize
{
	return [[[self alloc] initWithItemSize: itemSize] autorelease];
}

+ (instancetype)dataWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

+ (instancetype)dataWithItemSize: (size_t)itemSize
			capacity: (size_t)capacity
{
	return [[[self alloc] initWithItemSize: itemSize
				      capacity: capacity] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_itemSize = 1;

	return self;
}

- (instancetype)initWithItemSize: (size_t)itemSize
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_itemSize = itemSize;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return [self initWithItemSize: 1
			     capacity: capacity];
}

- (instancetype)initWithItemSize: (size_t)itemSize
			capacity: (size_t)capacity
{
	self = [super init];

	@try {
		if (itemSize == 0)
			@throw [OFInvalidArgumentException exception];

		_items = [self allocMemoryWithSize: itemSize
					     count: capacity];

		_itemSize = itemSize;
		_capacity = capacity;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithItems: (const void *)items
		     itemSize: (size_t)itemSize
			count: (size_t)count
{
	self = [super initWithItems: items
			   itemSize: itemSize
			      count: count];

	_capacity = _count;

	return self;
}

- (instancetype)initWithItemsNoCopy: (void *)items
			   itemSize: (size_t)itemSize
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone
{
	self = [self initWithItems: items
			  itemSize: itemSize
			     count: count];

	if (freeWhenDone)
		free(items);

	return self;
}

- (instancetype)initWithStringRepresentation: (OFString *)string
{
	self = [super initWithStringRepresentation: string];

	_capacity = _count;

	return self;
}

- (void *)mutableItems
{
	return _items;
}

- (void *)mutableItemAtIndex: (size_t)idx
{
	if (idx >= _count)
		@throw [OFOutOfRangeException exception];

	return _items + idx * _itemSize;
}

- (void *)mutableFirstItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items;
}

- (void *)mutableLastItem
{
	if (_items == NULL || _count == 0)
		return NULL;

	return _items + (_count - 1) * _itemSize;
}

- (OFData *)subdataWithRange: (of_range_t)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exception];

	return [OFData dataWithItems: _items + (range.location * _itemSize)
			    itemSize: _itemSize
			       count: range.length];
}

- (void)addItem: (const void *)item
{
	if (SIZE_MAX - _count < 1)
		@throw [OFOutOfRangeException exception];

	if (_count + 1 > _capacity) {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + 1];
		_capacity = _count + 1;
	}

	memcpy(_items + _count * _itemSize, item, _itemSize);

	_count++;
}

- (void)insertItem: (const void *)item
	   atIndex: (size_t)idx
{
	[self insertItems: item
		  atIndex: idx
		    count: 1];
}

- (void)addItems: (const void *)items
	   count: (size_t)count
{
	if (count > SIZE_MAX - _count)
		@throw [OFOutOfRangeException exception];

	if (_count + count > _capacity) {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + count];
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
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + count];
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
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count + count];
		_capacity = _count + count;
	}

	memset(_items + _count * _itemSize, '\0', count * _itemSize);
	_count += count;
}

- (void)removeItemAtIndex: (size_t)idx
{
	[self removeItemsInRange: of_range(idx, 1)];
}

- (void)removeItemsInRange: (of_range_t)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _count)
		@throw [OFOutOfRangeException exception];

	memmove(_items + range.location * _itemSize,
	    _items + (range.location + range.length) * _itemSize,
	    (_count - range.location - range.length) * _itemSize);

	_count -= range.length;
	@try {
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count];
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
		_items = [self resizeMemory: _items
				       size: _itemSize
				      count: _count];
		_capacity = _count;
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
	}
}

- (void)removeAllItems
{
	[self freeMemory: _items];

	_items = NULL;
	_count = 0;
	_capacity = 0;
}

- (id)copy
{
	return [[OFData alloc] initWithItems: _items
				    itemSize: _itemSize
				       count: _count];
}

- (void)makeImmutable
{
	object_setClass(self, [OFData class]);
}
@end
