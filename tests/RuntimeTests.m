/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *const module = @"Runtime";

@interface OFObject (SuperTest)
- (id)superTest;
@end

@interface RuntimeTest: OFObject
{
	OFString *_foo, *_bar;
}

@property (nonatomic, copy) OFString *foo;
@property (retain) OFString *bar;

- (id)nilSuperTest;
@end

@implementation RuntimeTest
@synthesize foo = _foo;
@synthesize bar = _bar;

- (void)dealloc
{
	[_foo release];
	[_bar release];

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

@implementation TestsAppDelegate (RuntimeTests)
- (void)runtimeTests
{
	void *pool = objc_autoreleasePoolPush();
	RuntimeTest *test = [[[RuntimeTest alloc] init] autorelease];
	OFString *string, *foo;
#ifdef OF_OBJFW_RUNTIME
	int classID;
	uintmax_t value;
	id object;
#endif

	EXPECT_EXCEPTION(@"Calling a non-existent method via super",
	    OFNotImplementedException, [test superTest])

	TEST(@"Calling a method via a super with self == nil",
	    [test nilSuperTest] == nil)

	string = [OFMutableString stringWithString: @"foo"];
	foo = @"foo";

	test.foo = string;
	TEST(@"copy, nonatomic properties", [test.foo isEqual: foo] &&
	    test.foo != foo && test.foo.retainCount == 1)

	test.bar = string;
	TEST(@"retain, atomic properties",
	    test.bar == string && string.retainCount == 3)

#ifdef OF_OBJFW_RUNTIME
	if (sizeof(uintptr_t) == 8)
		value = 0xDEADBEEFDEADBEF;
	else if (sizeof(uintptr_t) == 4)
		value = 0xDEADBEF;
	else
		abort();

	TEST(@"Tagged pointers",
	    objc_registerTaggedPointerClass([OFString class]) != -1 &&
	    (classID = objc_registerTaggedPointerClass([OFNumber class])) !=
	    -1 &&
	    (object = objc_createTaggedPointer(classID, (uintptr_t)value)) &&
	    object_getClass(object) == [OFNumber class] &&
	    [object class] == [OFNumber class] &&
	    object_getTaggedPointerValue(object) == value &&
	    objc_createTaggedPointer(classID, UINTPTR_MAX >> 4) != nil &&
	    objc_createTaggedPointer(classID, (UINTPTR_MAX >> 4) + 1) == nil)
#endif

	objc_autoreleasePoolPop(pool);
}
@end
