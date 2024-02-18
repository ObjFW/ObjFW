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
	[_set release];

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
	OTAssertEqualObjects([[_set copy] autorelease], _set);
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
@end
