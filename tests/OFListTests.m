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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFListTests: OTTestCase
{
	OFList *_list;
}
@end

@implementation OFListTests
- (void)setUp
{
	[super setUp];

	_list = [[OFList alloc] init];
	[_list appendObject: @"Foo"];
	[_list appendObject: @"Bar"];
	[_list appendObject: @"Baz"];
}

- (void)dealloc
{
	objc_release(_list);

	[super dealloc];
}

- (void)testCount
{
	OTAssertEqual(_list.count, 3);
}

- (void)testAppendObject
{
	OFListItem item;

	[_list appendObject: @"Qux"];

	item = _list.firstListItem;
	OTAssertEqualObjects(OFListItemObject(item), @"Foo");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Bar");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Baz");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Qux");

	item = OFListItemNext(item);
	OTAssertEqual(item, NULL);
}

- (void)testFirstListItem
{
	OTAssertEqualObjects(OFListItemObject(_list.firstListItem), @"Foo");
}

- (void)testFirstObject
{
	OTAssertEqualObjects(_list.firstObject, @"Foo");
}

- (void)testLastListItem
{
	OTAssertEqualObjects(OFListItemObject(_list.lastListItem), @"Baz");
}

- (void)testLastObject
{
	OTAssertEqualObjects(_list.lastObject, @"Baz");
}

- (void)testListItemNext
{
	OTAssertEqualObjects(
	    OFListItemObject(OFListItemNext(_list.firstListItem)), @"Bar");
}

- (void)testListItemPrevious
{
	OTAssertEqualObjects(
	    OFListItemObject(OFListItemPrevious(_list.lastListItem)), @"Bar");
}

- (void)testRemoveListItem
{
	OFListItem item;

	[_list removeListItem: OFListItemNext(_list.firstListItem)];

	item = _list.firstListItem;
	OTAssertEqualObjects(OFListItemObject(item), @"Foo");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Baz");

	item = OFListItemNext(item);
	OTAssertEqual(item, NULL);
}

- (void)testInsertObjectBeforeListItem
{
	OFListItem item;

	[_list insertObject: @"Qux" beforeListItem: _list.lastListItem];

	item = _list.firstListItem;
	OTAssertEqualObjects(OFListItemObject(item), @"Foo");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Bar");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Qux");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Baz");

	item = OFListItemNext(item);
	OTAssertEqual(item, NULL);
}

- (void)testInsertObjectAfterListItem
{
	OFListItem item;

	[_list insertObject: @"Qux" afterListItem: _list.firstListItem];

	item = _list.firstListItem;
	OTAssertEqualObjects(OFListItemObject(item), @"Foo");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Qux");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Bar");

	item = OFListItemNext(item);
	OTAssertEqualObjects(OFListItemObject(item), @"Baz");

	item = OFListItemNext(item);
	OTAssertEqual(item, NULL);
}

- (void)testContainsObject
{
	OTAssertTrue([_list containsObject: @"Foo"]);
	OTAssertFalse([_list containsObject: @"Qux"]);
}

- (void)testContainsObjectIdenticalTo
{
	OFString *foo = _list.firstObject;

	OTAssertTrue([_list containsObjectIdenticalTo: foo]);
	OTAssertFalse([_list containsObjectIdenticalTo:
	    objc_autorelease([foo mutableCopy])]);
}

- (void)testIsEqual
{
	OFList *list = [OFList list];

	[list appendObject: @"Foo"];
	[list appendObject: @"Bar"];
	[list appendObject: @"Baz"];

	OTAssertEqualObjects(list, _list);

	[list appendObject: @"Qux"];

	OTAssertNotEqualObjects(list, _list);
}

- (void)testHash
{
	OFList *list = [OFList list];

	[list appendObject: @"Foo"];
	[list appendObject: @"Bar"];
	[list appendObject: @"Baz"];

	OTAssertEqual(list.hash, _list.hash);

	[list appendObject: @"Qux"];

	OTAssertNotEqual(list.hash, _list.hash);
}

- (void)testCopy
{
	OTAssertEqualObjects(objc_autorelease([_list copy]), _list);
}

- (void)testDescription
{
	OTAssertEqualObjects(_list.description, @"[\n\tFoo,\n\tBar,\n\tBaz\n]");
}

- (void)testEnumerator
{
	OFEnumerator *enumerator = [_list objectEnumerator];

	OTAssertEqualObjects([enumerator nextObject], @"Foo");
	OTAssertEqualObjects([enumerator nextObject], @"Bar");
	OTAssertEqualObjects([enumerator nextObject], @"Baz");
	OTAssertNil([enumerator nextObject]);
}

- (void)testDetectMutationDuringEnumeration
{
	OFEnumerator *enumerator = [_list objectEnumerator];

	[_list removeListItem: _list.firstListItem];

	OTAssertThrowsSpecific([enumerator nextObject],
	    OFEnumerationMutationException);
}

- (void)testFastEnumeration
{
	size_t i = 0;

	for (OFString *object in _list) {
		OTAssertLessThan(i, 3);

		switch (i++) {
		case 0:
			OTAssertEqualObjects(object, @"Foo");
			break;
		case 1:
			OTAssertEqualObjects(object, @"Bar");
			break;
		case 2:
			OTAssertEqualObjects(object, @"Baz");
			break;
		}
	}

	OTAssertEqual(i, 3);
}

- (void)testDetectMutationDuringFastEnumeration
{
	bool detected = false;

	@try {
		for (OFString *object in _list) {
			(void)object;
			[_list removeListItem: _list.firstListItem];
		}
	} @catch (OFEnumerationMutationException *e) {
		detected = true;
	}

	OTAssertTrue(detected);
}
@end
