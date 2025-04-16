/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableSetTests.h"

@interface CustomMutableSet: OFMutableSet
{
	OFMutableSet *_set;
}
@end

@implementation OFMutableSetTests
- (Class)setClass
{
	return [CustomMutableSet class];
}

- (void)setUp
{
	[super setUp];

	_mutableSet = [[OFMutableSet alloc]
	    initWithObjects: @"foo", @"bar", @"baz", nil];
}

- (void)dealloc
{
	objc_release(_mutableSet);

	[super dealloc];
}

- (void)testAddObject
{
	[_mutableSet addObject: @"x"];

	OTAssertEqualObjects(_mutableSet,
	    ([OFSet setWithObjects: @"foo", @"bar", @"baz", @"x", nil]));
}

- (void)testRemoveObject
{
	[_mutableSet removeObject: @"foo"];

	OTAssertEqualObjects(_mutableSet,
	    ([OFSet setWithObjects: @"bar", @"baz", nil]));
}

- (void)testMinusSet
{
	[_mutableSet minusSet: [OFSet setWithObjects: @"foo", @"bar", nil]];

	OTAssertEqualObjects(_mutableSet,
	    ([OFSet setWithObjects: @"baz", nil]));
}

- (void)testIntersectSet
{
	[_mutableSet intersectSet: [OFSet setWithObjects: @"foo", @"qux", nil]];

	OTAssertEqualObjects(_mutableSet,
	    ([OFSet setWithObjects: @"foo", nil]));
}

- (void)testUnionSet
{
	[_mutableSet unionSet: [OFSet setWithObjects: @"x", @"y", nil]];

	OTAssertEqualObjects(_mutableSet,
	    ([OFSet setWithObjects: @"foo", @"bar", @"baz", @"x", @"y", nil]));
}

- (void)testRemoveAllObjects
{
	[_mutableSet removeAllObjects];

	OTAssertEqual(_mutableSet.count, 0);
}
@end

@implementation CustomMutableSet
- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithObjects: objects
						       count: count];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_set);

	[super dealloc];
}

- (size_t)count
{
	return _set.count;
}

- (bool)containsObject: (id)object
{
	return [_set containsObject: object];
}

- (OFEnumerator *)objectEnumerator
{
	return [_set objectEnumerator];
}

- (void)addObject: (id)object
{
	[_set addObject: object];
}

- (void)removeObject: (id)object
{
	[_set removeObject: object];
}
@end
