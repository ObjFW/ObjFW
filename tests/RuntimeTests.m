/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	RuntimeTest *rt = [[[RuntimeTest alloc] init] autorelease];
	OFString *t, *foo;

	EXPECT_EXCEPTION(@"Calling a non-existant method via super",
	    OFNotImplementedException, [rt superTest])

	TEST(@"Calling a method via a super with self == nil",
	    [rt nilSuperTest] == nil)

	t = [OFMutableString stringWithString: @"foo"];
	foo = @"foo";

	[rt setFoo: t];
	TEST(@"copy, nonatomic properties", [[rt foo] isEqual: foo] &&
	    [rt foo] != foo && [[rt foo] retainCount] == 1)

	[rt setBar: t];
	TEST(@"retain, atomic properties",
	    [rt bar] == t && [t retainCount] == 3)

	[pool drain];
}
@end
