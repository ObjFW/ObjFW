/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFThread.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "main.h"

static OFString *module = @"OFThread";

@interface TestThread: OFThread
@end

@implementation TestThread
- main
{
	if ([object isEqual: @"foo"])
		return @"success";

	return nil;
}
@end

void
thread_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TestThread *t;
	OFTLSKey *key;

	TEST(@"+[threadWithObject:]",
	    (t = [TestThread threadWithObject: @"foo"]))

	TEST(@"-[join]", [[t join] isEqual: @"success"])

	TEST(@"OFTLSKey's +[tlsKey]", (key = [OFTLSKey tlsKey]))

	TEST(@"+[setObject:forTLSKey:]", [OFThread setObject: @"foo"
						   forTLSKey: key])

	TEST(@"+[objectForTLSKey:]",
	    [[OFThread objectForTLSKey: key] isEqual: @"foo"])

	[pool release];
}
