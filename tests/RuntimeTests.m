/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

static OFString *module = @"Runtime";

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
	RuntimeTest *rt = [[[RuntimeTest alloc] init] autorelease];
	OFString *t, *foo;
#ifdef OF_OBJFW_RUNTIME
	int cid1, cid2;
	uintmax_t value;
	id object;
#endif

	EXPECT_EXCEPTION(@"Calling a non-existent method via super",
	    OFNotImplementedException, [rt superTest])

	TEST(@"Calling a method via a super with self == nil",
	    [rt nilSuperTest] == nil)

	t = [OFMutableString stringWithString: @"foo"];
	foo = @"foo";

	[rt setFoo: t];
	TEST(@"copy, nonatomic properties", [rt.foo isEqual: foo] &&
	    rt.foo != foo && rt.foo.retainCount == 1)

	rt.bar = t;
	TEST(@"retain, atomic properties", rt.bar == t && t.retainCount == 3)

#ifdef OF_OBJFW_RUNTIME
	if (sizeof(uintptr_t) == 8)
		value = 0xDEADBEEFDEADBEF;
	else if (sizeof(uintptr_t) == 4)
		value = 0xDEADBEF;
	else
		abort();

	TEST(@"Tagged pointers",
	    R(cid1 = objc_registerTaggedPointerClass([OFString class])) &&
	    R(cid2 = objc_registerTaggedPointerClass([OFNumber class])) &&
	    cid1 != -1 && cid2 != -1 &&
	    (object = objc_createTaggedPointer(cid2, (uintptr_t)value)) &&
	    object_getTaggedPointerClass(object) == [OFNumber class] &&
	    [object class] == [OFNumber class] &&
	    object_getTaggedPointerValue(object) == value &&
	    objc_createTaggedPointer(cid2, UINTPTR_MAX >> 4) != nil &&
	    objc_createTaggedPointer(cid2, (UINTPTR_MAX >> 4) + 1) == nil)
#endif

	objc_autoreleasePoolPop(pool);
}
@end
