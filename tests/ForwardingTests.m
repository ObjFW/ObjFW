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

#include <string.h>

#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "macros.h"

#import "TestsAppDelegate.h"

static OFString *module = @"Forwarding";
static size_t forwardings = 0;
static bool success = false;
static id target = nil;

struct stret_test {
	char s[27];
};

@interface ForwardingTest: OFObject
@end

@interface ForwardingTest (Test)
+ (void)test;
- (void)test;
- (OFString*)forwardingTargetTest: (OFConstantString*)fmt, ...;
- (long double)forwardingTargetFPRetTest;
- (struct stret_test)forwardingTargetStRetTest;
@end

@interface ForwardingTarget: OFObject
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

- (id)forwardingTargetForSelector: (SEL)selector
{
	if (sel_isEqual(selector, @selector(forwardingTargetTest:)) ||
	    sel_isEqual(selector, @selector(forwardingTargetFPRetTest)) ||
	    sel_isEqual(selector, @selector(forwardingTargetStRetTest)))
		return target;

	return nil;
}
@end

@implementation ForwardingTarget
- (OFString*)forwardingTargetTest: (OFConstantString*)fmt, ...
{
	va_list args;
	OFString *ret;

	OF_ENSURE(self == target);

	va_start(args, fmt);
	ret = [[[OFString alloc] initWithFormat: fmt
				      arguments: args] autorelease];
	va_end(args);

	return ret;
}

- (long double)forwardingTargetFPRetTest
{
	OF_ENSURE(self == target);

	return 12345678.00006103515625;
}

- (struct stret_test)forwardingTargetStRetTest
{
	struct stret_test ret;

	OF_ENSURE(self == target);

	memcpy(ret.s, "abcdefghijklmnopqrstuvwxyz", 27);

	return ret;
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

#ifdef OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
	target = [[[ForwardingTarget alloc] init] autorelease];
	TEST(@"-[forwardingTargetForSelector:]",
	   [([t forwardingTargetTest: @"%@ %@ %@ %@ %@ %@ %@ %@ %@", @"1", @"2",
				     @"3", @"4", @"5", @"6", @"7", @"8", @"9"])
	   isEqual: @"1 2 3 4 5 6 7 8 9"])
	TEST(@"-[forwardingTargetForSelector:] with fp return",
	    [t forwardingTargetFPRetTest] == 12345678.00006103515625)
# ifdef OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
	TEST(@"-[forwardingTargetForSelector:] with struct return",
	    !memcmp([t forwardingTargetStRetTest].s,
	    "abcdefghijklmnopqrstuvwxyz", 27))
# endif
#endif

	[pool drain];
}
@end
