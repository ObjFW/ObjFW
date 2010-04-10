/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFThread.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFThread";

@interface TestThread: OFThread
@end

@implementation TestThread
- (id)run
{
	if ([object isEqual: @"foo"])
		return @"success";

	return nil;
}
@end

@implementation TestsAppDelegate (OFThreadTests)
- (void)threadTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TestThread *t;
	OFTLSKey *key;

	TEST(@"+[threadWithObject:]",
	    (t = [TestThread threadWithObject: @"foo"]))

	TEST(@"-[start]", [t start])

	TEST(@"-[join]", [[t join] isEqual: @"success"])

	TEST(@"OFTLSKey's +[tlsKey]", (key = [OFTLSKey tlsKey]))

	TEST(@"+[setObject:forTLSKey:]", [OFThread setObject: @"foo"
						   forTLSKey: key])

	TEST(@"+[objectForTLSKey:]",
	    [[OFThread objectForTLSKey: key] isEqual: @"foo"])

	[pool drain];
}
@end
