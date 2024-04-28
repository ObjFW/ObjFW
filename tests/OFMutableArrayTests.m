/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableArrayTests.h"

#import "OFArray+Private.h"

@interface CustomMutableArray: OFMutableArray
{
	OFMutableArray *_array;
}
@end

static OFString *const cArray[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation OFMutableArrayTests
- (Class)arrayClass
{
	return [CustomMutableArray class];
}

- (void)setUp
{
	[super setUp];

	_mutableArray = [[self.arrayClass alloc]
	    initWithObjects: cArray
		      count: sizeof(cArray) / sizeof(*cArray)];
}

- (void)dealloc
{
	[_mutableArray release];

	[super dealloc];
}

- (void)testAddObject
{
	[_mutableArray addObject: cArray[0]];
	[_mutableArray addObject: cArray[2]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Bar", @"Baz", @"Foo", @"Baz",
	    nil]));
}

- (void)testInsertObjectAtIndex
{
	[_mutableArray insertObject: cArray[1] atIndex: 1];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Bar", @"Bar", @"Baz", nil]));
}

- (void)testReplaceObjectWithObject
{
	[_mutableArray insertObject: cArray[1] atIndex: 1];
	[_mutableArray replaceObject: cArray[1] withObject: cArray[0]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Foo", @"Foo", @"Baz", nil]));
}

- (void)testReplaceObjectIdenticalToWithObject
{
	[_mutableArray insertObject: [[cArray[1] mutableCopy] autorelease]
			    atIndex: 1];
	[_mutableArray insertObject: [[cArray[1] mutableCopy] autorelease]
			    atIndex: 4];
	[_mutableArray replaceObjectIdenticalTo: cArray[1]
				     withObject: cArray[0]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Bar", @"Foo", @"Baz", @"Bar",
	    nil]));
}

- (void)testReplaceObjectAtIndexWithObject
{
	[_mutableArray replaceObjectAtIndex: 1
				 withObject: cArray[0]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Foo", @"Baz", nil]));
}

- (void)testRemoveObject
{
	[_mutableArray removeObject: cArray[1]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Baz", nil]));
}

- (void)testRemoveObjectIdenticalTo
{
	[_mutableArray removeObjectIdenticalTo: cArray[1]];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Baz", nil]));
}

- (void)testRemoveObjectAtIndex
{
	[_mutableArray removeObjectAtIndex: 1];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Foo", @"Baz", nil]));
}

- (void)testRemoveObjectsInRange
{
	[_mutableArray removeObjectsInRange: OFMakeRange(1, 2)];

	OTAssertEqualObjects(_mutableArray, [OFArray arrayWithObject: @"Foo"]);
}

- (void)testRemoveObjectsInRangeFailsWhenOutOfRange
{
	OTAssertThrowsSpecific([_mutableArray removeObjectsInRange:
	    OFMakeRange(0, _mutableArray.count + 1)], OFOutOfRangeException);
}

- (void)testReverse
{
	[_mutableArray reverse];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"Baz", @"Bar", @"Foo", nil]));
}

#ifdef OF_HAVE_BLOCKS
- (void)testReplaceObjectsUsingBlock
{
	[_mutableArray replaceObjectsUsingBlock: ^ id (id object, size_t idx) {
		return [object lowercaseString];
	}];

	OTAssertEqualObjects(_mutableArray,
	    ([OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]));
}
#endif

- (void)testSetValueForKey
{
	OFMutableArray *array = [self.arrayClass arrayWithObjects:
	    [OFMutableIRI IRIWithString: @"http://foo.bar/"],
	    [OFMutableIRI IRIWithString: @"http://bar.qux/"],
	    [OFMutableIRI IRIWithString: @"http://qux.quxqux/"], nil];

	[array setValue: [OFNumber numberWithShort: 1234]
		 forKey: @"port"];
	OTAssertEqualObjects(array, ([OFArray arrayWithObjects:
	    [OFIRI IRIWithString: @"http://foo.bar:1234/"],
	    [OFIRI IRIWithString: @"http://bar.qux:1234/"],
	    [OFIRI IRIWithString: @"http://qux.quxqux:1234/"], nil]));
}
@end

@implementation CustomMutableArray
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

- (void)insertObject: (id)object atIndex: (size_t)idx
{
	[_array insertObject: object atIndex: idx];
}

- (void)replaceObjectAtIndex: (size_t)idx withObject: (id)object
{
	[_array replaceObjectAtIndex: idx withObject: object];
}

- (void)removeObjectAtIndex: (size_t)idx
{
	[_array removeObjectAtIndex: idx];
}
@end
