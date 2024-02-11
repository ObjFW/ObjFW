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

#import "OFArrayTests.h"

@interface CustomArray: OFArray
{
	OFMutableArray *_array;
}
@end

static OFString *const cArray[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation OFArrayTests
- (Class)arrayClass
{
	return [CustomArray class];
}

- (void)setUp
{
	[super setUp];

	_array = [[self.arrayClass alloc]
	    initWithObjects: cArray
		      count: sizeof(cArray) / sizeof(*cArray)];
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (void)testArray
{
	OFArray *array = [self.arrayClass array];

	OTAssertNotNil(array);
	OTAssertEqual(array.count, 0);
}

- (void)testArrayWithObjects
{
	OFArray *array = [self.arrayClass arrayWithObjects:
	    @"Foo", @"Bar", @"Baz", nil];

	OTAssertNotNil(array);
	OTAssertEqual(array.count, 3);
	OTAssertEqualObjects([array objectAtIndex: 0], @"Foo");
	OTAssertEqualObjects([array objectAtIndex: 1], @"Bar");
	OTAssertEqualObjects([array objectAtIndex: 2], @"Baz");
}

- (void)testArrayWithObjectsCount
{
	OFArray *array1 = [self.arrayClass arrayWithObjects:
	    @"Foo", @"Bar", @"Baz", nil];
	OFArray *array2 = [self.arrayClass arrayWithObjects: cArray count: 3];

	OTAssertEqualObjects(array1, array2);
}

- (void)testDescription
{
	OTAssertEqualObjects(_array.description,
	    @"(\n\tFoo,\n\tBar,\n\tBaz\n)");
}

- (void)testCount
{
	OTAssertEqual(_array.count, 3);
}

- (void)testIsEqual
{
	OFArray *array = [self.arrayClass arrayWithObjects: cArray count: 3];

	OTAssertEqualObjects(array, _array);
	OTAssertNotEqual(array, _array);
}

- (void)testObjectAtIndex
{
	OTAssertEqualObjects([_array objectAtIndex: 0], cArray[0]);
	OTAssertEqualObjects([_array objectAtIndex: 1], cArray[1]);
	OTAssertEqualObjects([_array objectAtIndex: 2], cArray[2]);
}

- (void)testObjectAtIndexFailsWhenOutOfRange
{
	OTAssertThrowsSpecific([_array objectAtIndex: _array.count],
	    OFOutOfRangeException);
}

- (void)testContainsObject
{
	OTAssertTrue([_array containsObject: cArray[1]]);
	OTAssertFalse([_array containsObject: @"nonexistent"]);
}

- (void)testContainsObjectIdenticalTo
{
	OTAssertTrue([_array containsObjectIdenticalTo: cArray[1]]);
	OTAssertFalse([_array containsObjectIdenticalTo:
	    [OFString stringWithString: cArray[1]]]);
}

- (void)testIndexOfObject
{
	OTAssertEqual([_array indexOfObject: cArray[1]], 1);
	OTAssertEqual([_array indexOfObject: @"nonexistent"], OFNotFound);
}

- (void)testIndexOfObjectIdenticalTo
{
	OTAssertEqual([_array indexOfObjectIdenticalTo: cArray[1]], 1);
	OTAssertEqual([_array indexOfObjectIdenticalTo:
	    [OFString stringWithString: cArray[1]]],
	    OFNotFound);
}

- (void)objectsInRange
{
	OTAssertEqualObjects([_array objectsInRange: OFMakeRange(1, 2)],
	    ([self.arrayClass arrayWithObjects: cArray[1], cArray[2], nil]));
}

- (void)testEnumerator
{
	OFEnumerator *enumerator = [_array objectEnumerator];

	OTAssertEqualObjects([enumerator nextObject], cArray[0]);
	OTAssertEqualObjects([enumerator nextObject], cArray[1]);
	OTAssertEqualObjects([enumerator nextObject], cArray[2]);
	OTAssertNil([enumerator nextObject]);
}

- (void)testFastEnumeration
{
	size_t i = 0;

	for (OFString *object in _array) {
		OTAssert(i < 3);
		OTAssertEqualObjects(object, cArray[i++]);
	}
}

- (void)testComponentsJoinedByString
{
	OFArray *array;

	array = [self.arrayClass arrayWithObjects: @"", @"a", @"b", @"c", nil];
	OTAssertEqualObjects([array componentsJoinedByString: @" "],
	    @" a b c");

	array = [self.arrayClass arrayWithObject: @"foo"];
	OTAssertEqualObjects([array componentsJoinedByString: @" "], @"foo");
}

- (void)testComponentsJoinedByStringOptions
{
	OFArray *array;

	array = [self.arrayClass
	    arrayWithObjects: @"", @"foo", @"", @"", @"bar", @"", nil];
	OTAssertEqualObjects(
	    [array componentsJoinedByString: @" "
				    options: OFArraySkipEmptyComponents],
	    @"foo bar");
}

- (void)testSortedArray
{
	OFArray *array = [_array arrayByAddingObjectsFromArray:
	    [OFArray arrayWithObjects: @"0", @"z", nil]];

	OTAssertEqualObjects([array sortedArray],
	    ([OFArray arrayWithObjects: @"0", @"Bar", @"Baz", @"Foo", @"z",
	    nil]));

	OTAssertEqualObjects(
	    [array sortedArrayUsingSelector: @selector(compare:)
				    options: OFArraySortDescending],
	    ([OFArray arrayWithObjects: @"z", @"Foo", @"Baz", @"Bar", @"0",
	    nil]));
}

- (void)testReversedArray
{
	OTAssertEqualObjects(_array.reversedArray,
	    ([OFArray arrayWithObjects: cArray[2], cArray[1], cArray[0], nil]));
}

#ifdef OF_HAVE_BLOCKS
- (void)testEnumerateObjectsUsingBlock
{
	__block size_t i = 0;

	[_array enumerateObjectsUsingBlock:
	    ^ (id object, size_t idx, bool *stop) {
		OTAssertEqualObjects(object, [_array objectAtIndex: i++]);
	}];

	OTAssertEqual(i, _array.count);
}

- (void)testMappedArrayUsingBlock
{
	OTAssertEqualObjects(
	    [_array mappedArrayUsingBlock: ^ id (id object, size_t idx) {
		switch (idx) {
		case 0:
			return @"foobar";
		case 1:
			return @"qux";
		}

		return @"";
	    }].description,
	    @"(\n\tfoobar,\n\tqux,\n\t\n)");
}

- (void)testFilteredArrayUsingBlock
{
	OTAssertEqualObjects(
	    [_array filteredArrayUsingBlock: ^ bool (id object, size_t idx) {
		return [object isEqual: @"Foo"];
	    }].description,
	    @"(\n\tFoo\n)");

}

- (void)testFoldUsingBlock
{
	OTAssertEqualObjects(
	    [([self.arrayClass arrayWithObjects: [OFMutableString string],
						 @"foo", @"bar", @"baz", nil])
	    foldUsingBlock: ^ id (id left, id right) {
		[left appendString: right];
		return left;
	    }],
	    @"foobarbaz");
}
#endif

- (void)testValueForKey
{
	OTAssertEqualObjects(
	    [([self.arrayClass arrayWithObjects: @"foo", @"bar", @"quxqux",
	    nil]) valueForKey: @"length"],
	    ([self.arrayClass arrayWithObjects: [OFNumber numberWithInt: 3],
	    [OFNumber numberWithInt: 3], [OFNumber numberWithInt: 6], nil]));

	OTAssertEqualObjects(
	    [([self.arrayClass arrayWithObjects: @"1", @"2", nil])
	    valueForKey: @"@count"],
	    [OFNumber numberWithInt: 2]);
}
@end

@implementation CustomArray
- (instancetype)init
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)object arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] initWithObject: object
						      arguments: arguments];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] initWithObjects: objects
							   count: count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (id)objectAtIndex: (size_t)idx
{
	return [_array objectAtIndex: idx];
}

- (size_t)count
{
	return [_array count];
}
@end
