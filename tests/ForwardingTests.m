/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "TestsAppDelegate.h"

static OFString *module = @"Forwarding";
static size_t forwardings = 0;
static bool success = false;

@interface ForwardingTest: OFObject
@end

@interface ForwardingTest (Test)
+ (void)test;
- (void)test;
@end

static void
test(id self, SEL _cmd)
{
	success = true;
}

@implementation ForwardingTest
+ (bool)resolveClassMethod: (SEL)selector
{
	forwardings++;

	if (sel_isEqual(selector, @selector(test))) {
		[self replaceClassMethod: @selector(test)
		      withImplementation: (IMP)test
			    typeEncoding: "v#:"];
		return true;
	}

	return false;
}

+ (bool)resolveInstanceMethod: (SEL)selector
{
	forwardings++;

	if (sel_isEqual(selector, @selector(test))) {
		[self replaceInstanceMethod: @selector(test)
			 withImplementation: (IMP)test
			       typeEncoding: "v@:"];
		return true;
	}

	return false;
}
@end

@implementation TestsAppDelegate (ForwardingTests)
- (void)forwardingTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	TEST(@"Forwarding a message and adding a class method",
	    R([ForwardingTest test]) && success &&
	    R([ForwardingTest test]) && forwardings == 1);

	ForwardingTest *t = [[[ForwardingTest alloc] init] autorelease];

	success = false;
	forwardings = 0;

	TEST(@"Forwarding a message and adding an instance method",
	    R([t test]) && success && R([t test]) && forwardings == 1);

	[pool drain];
}
@end
