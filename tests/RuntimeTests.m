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

#import "ObjFW.h"
#import "ObjFWTest.h"

static void *testKey = &testKey;

@interface RuntimeTestClass: OFObject
{
	OFString *_foo, *_bar;
}

@property (nonatomic, copy) OFString *foo;
@property (retain) OFString *bar;

- (id)nilSuperTest;
@end

@interface RuntimeTests: OTTestCase
{
	RuntimeTestClass *_test;
}
@end

@interface OFObject (SuperTest)
- (id)superTest;
@end

@implementation RuntimeTests
- (void)setUp
{
	[super setUp];

	_test = [[RuntimeTestClass alloc] init];
}

- (void)dealloc
{
	objc_release(_test);

	[super dealloc];
}

- (void)testCallNonExistentMethodViaSuper
{
	OTAssertThrowsSpecific([_test superTest], OFNotImplementedException);
}

- (void)testCallMethodViaSuperWithNilSelf
{
	OTAssertNil([_test nilSuperTest]);
}

- (void)testPropertyCopyNonatomic
{
	OFMutableString *string = [OFMutableString stringWithString: @"foo"];
	OFString *foo = @"foo";

	_test.foo = string;
	OTAssertEqualObjects(_test.foo, foo);
	OTAssertNotEqual(_test.foo, foo);
	OTAssertEqual(_test.foo.retainCount, 1);
}

- (void)testPropertyRetainAtomic
{
	OFMutableString *string = [OFMutableString stringWithString: @"foo"];

	_test.bar = string;
	OTAssertEqual(_test.bar, string);
	OTAssertEqual(string.retainCount, 3);
}

- (void)testAssociatedObjects
{
	objc_setAssociatedObject(self, testKey, _test, OBJC_ASSOCIATION_ASSIGN);
	OTAssertEqual(_test.retainCount, 1);

	objc_setAssociatedObject(self, testKey, _test, OBJC_ASSOCIATION_RETAIN);
	OTAssertEqual(_test.retainCount, 2);

	OTAssertEqual(objc_getAssociatedObject(self, testKey), _test);
	OTAssertEqual(_test.retainCount, 3);

	objc_setAssociatedObject(self, testKey, _test, OBJC_ASSOCIATION_ASSIGN);
	OTAssertEqual(_test.retainCount, 2);

	objc_setAssociatedObject(self, testKey, _test,
	    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	OTAssertEqual(_test.retainCount, 3);

	OTAssertEqual(objc_getAssociatedObject(self, testKey), _test);
	OTAssertEqual(_test.retainCount, 3);

	objc_removeAssociatedObjects(self);
	OTAssertEqual(_test.retainCount, 2);
}

#ifdef OF_OBJFW_RUNTIME
- (void)testTaggedPointers
{
	int classID;
	uintmax_t value;
	id object;

	if (sizeof(uintptr_t) == 8)
		value = 0xDEADBEEFDEADBEF;
	else if (sizeof(uintptr_t) == 4)
		value = 0xDEADBEF;
	else
		OTAssert(sizeof(uintptr_t) == 8 || sizeof(uintptr_t) == 4);

	OTAssertNotEqual(objc_registerTaggedPointerClass([OFString class]), -1);

	classID = objc_registerTaggedPointerClass([OFNumber class]);
	OTAssertNotEqual(classID, -1);

	object = objc_createTaggedPointer(classID, (uintptr_t)value);
	OTAssertNotNil(object);
	OTAssertEqual(object_getClass(object), [OFNumber class]);
	OTAssertEqual([object class], [OFNumber class]);
	OTAssertEqual(object_getTaggedPointerValue(object), value);
	OTAssertNotNil(objc_createTaggedPointer(classID, UINTPTR_MAX >> 4));
	OTAssertNil(objc_createTaggedPointer(classID, (UINTPTR_MAX >> 4) + 1));
}
#endif
@end

@implementation RuntimeTestClass
@synthesize foo = _foo;
@synthesize bar = _bar;

- (void)dealloc
{
	objc_release(_foo);
	objc_release(_bar);

	[super dealloc];
}

- (id)superTest
{
	return [super superTest];
}

- (id)nilSuperTest
{
	self = nil;

	return [self superTest];
}
@end
