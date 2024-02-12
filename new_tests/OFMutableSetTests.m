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
	[_mutableSet release];

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
- (instancetype)init
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSet: (OFSet *)set
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithSet: set];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithArray: array];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithObject: firstObject
						  arguments: arguments];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_set release];

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
