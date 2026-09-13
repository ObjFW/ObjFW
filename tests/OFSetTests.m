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

#import "OFSetTests.h"

@interface CustomSet: OFSet
{
	OFSet *_set;
}
@end

@implementation OFSetTests
- (Class)setClass
{
	return [CustomSet class];
}

- (void)setUp
{
	[super setUp];

	_set = [[OFSet alloc] initWithObjects: @"foo", @"bar", @"baz", nil];
}

- (void)dealloc
{
	objc_release(_set);

	[super dealloc];
}

- (void)testSetWithArray
{
	OTAssertEqualObjects([self.setClass setWithArray:
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", @"foo", nil])],
	    _set);
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_set,
	    ([OFSet setWithObjects: @"foo", @"bar", @"baz", nil]));
}

- (void)testHash
{
	OTAssertEqual(_set.hash,
	    [([OFSet setWithObjects: @"foo", @"bar", @"baz", nil]) hash]);
}

- (void)testDescription
{
	OFString *description = _set.description;

	OTAssert(
	    [description isEqual: @"{(\n\tfoo,\n\tbar,\n\tbaz\n)}"] ||
	    [description isEqual: @"{(\n\tfoo,\n\tbaz,\n\tbar\n)}"] ||
	    [description isEqual: @"{(\n\tbar,\n\tfoo,\n\tbaz\n)}"] ||
	    [description isEqual: @"{(\n\tbar,\n\tbaz,\n\tfoo\n)}"] ||
	    [description isEqual: @"{(\n\tbaz,\n\tfoo,\n\tbar\n)}"] ||
	    [description isEqual: @"{(\n\tbaz,\n\tbar,\n\tfoo\n)}"]);
}

- (void)testCopy
{
	OTAssertEqualObjects(objc_autorelease([_set copy]), _set);
}

- (void)testMutableCopy
{
	OTAssertEqualObjects(objc_autorelease([_set mutableCopy]), _set);
}

- (void)testIsSubsetOfSet
{
	OTAssertTrue([([OFSet setWithObjects: @"foo", nil])
	    isSubsetOfSet: _set]);
	OTAssertFalse([([OFSet setWithObjects: @"foo", @"Foo", nil])
	    isSubsetOfSet: _set]);
}

- (void)testIntersectsSet
{
	OTAssertTrue([([OFSet setWithObjects: @"foo", @"Foo", nil])
	    intersectsSet: _set]);
	OTAssertFalse([([OFSet setWithObjects: @"Foo", nil])
	    intersectsSet: _set]);
}

- (void)testEnumerator
{
	OFEnumerator *enumerator = [_set objectEnumerator];
	bool seenFoo = false, seenBar = false, seenBaz = false;
	OFString *object;

	while ((object = [enumerator nextObject]) != nil) {
		if ([object isEqual: @"foo"]) {
			OTAssertFalse(seenFoo);
			seenFoo = true;
		} else if ([object isEqual: @"bar"]) {
			OTAssertFalse(seenBar);
			seenBar = true;
		} else if ([object isEqual: @"baz"]) {
			OTAssertFalse(seenBaz);
			seenBaz = true;
		} else
			OTAssert(false, @"Unexpected object seen: %@", object);
	}

	OTAssert(seenFoo && seenBar && seenBaz);
}

- (void)testFastEnumeration
{
	bool seenFoo = false, seenBar = false, seenBaz = false;

	for (OFString *object in _set) {
		if ([object isEqual: @"foo"]) {
			OTAssertFalse(seenFoo);
			seenFoo = true;
		} else if ([object isEqual: @"bar"]) {
			OTAssertFalse(seenBar);
			seenBar = true;
		} else if ([object isEqual: @"baz"]) {
			OTAssertFalse(seenBaz);
			seenBaz = true;
		} else
			OTAssert(false, @"Unexpected object seen: %@", object);
	}

	OTAssert(seenFoo && seenBar && seenBaz);
}

#ifdef OF_HAVE_BLOCKS
- (void)testEnumerateObjectsUsingBlock
{
	__block bool seenFoo = false, seenBar = false, seenBaz = false;

	[_set enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		if ([object isEqual: @"foo"]) {
			OTAssertFalse(seenFoo);
			seenFoo = true;
		} else if ([object isEqual: @"bar"]) {
			OTAssertFalse(seenBar);
			seenBar = true;
		} else if ([object isEqual: @"baz"]) {
			OTAssertFalse(seenBaz);
			seenBaz = true;
		} else
			OTAssert(false, @"Unexpected object seen: %@", object);
	}];

	OTAssert(seenFoo && seenBar && seenBaz);
}

- (void)testFilteredSetUsingBlock
{
	OFSet *filteredSet = [_set filteredSetUsingBlock: ^ (id object) {
		return [object hasPrefix: @"ba"];
	}];

	OTAssertEqualObjects(filteredSet,
	    ([OFSet setWithObjects: @"bar", @"baz", nil]));
}
#endif

- (void)testValueForKey
{
	OFSet *set = [[self.setClass setWithObjects:
	    @"a", @"ab", @"abc", @"b", nil] valueForKey: @"length"];

	OTAssertEqualObjects(set, ([OFSet  setWithObjects:
	    [OFNumber numberWithInt: 1], [OFNumber numberWithInt: 2],
	    [OFNumber numberWithInt: 3], nil]));

	OTAssertEqualObjects([set valueForKey: @"@count"],
	    [OFNumber numberWithInt: 3]);
}
@end

@implementation CustomSet
- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	self = [super init];

	@try {
		_set = [[OFSet alloc] initWithObjects: objects count: count];
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
@end
