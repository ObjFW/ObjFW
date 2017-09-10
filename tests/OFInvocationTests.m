/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <string.h>

#import "OFInvocation.h"
#import "OFMethodSignature.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFInvocation";

struct test_struct {
	unsigned char c;
	unsigned int i;
};

@implementation TestsAppDelegate (OFInvocationTests)
- (struct test_struct)invocationTestMethod: (unsigned char)c
					  : (unsigned int)i
					  : (struct test_struct *)ptr
					  : (struct test_struct)st
{
	return st;
}

- (void)invocationTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMethodSignature *sig = [self methodSignatureForSelector:
	    @selector(invocationTestMethod::::)];
	OFInvocation *invocation;
	struct test_struct st, st2, *stp = &st, *stp2;
	unsigned const char c = 0xAA;
	unsigned char c2;
	const unsigned int i = 0x55555555;
	unsigned int i2;

	memset(&st, '\xFF', sizeof(st));
	st.c = 0x55;
	st.i = 0xAAAAAAAA;

	TEST(@"+[invocationWithMethodSignature:]",
	    (invocation = [OFInvocation invocationWithMethodSignature: sig]))

	TEST(@"-[setReturnValue]", R([invocation setReturnValue: &st]))

	TEST(@"-[getReturnValue]", R([invocation getReturnValue: &st2]) &&
	    memcmp(&st, &st2, sizeof(st)) == 0)

	memset(&st2, '\0', sizeof(st2));

	TEST(@"-[setArgument:atIndex:] #1", R([invocation setArgument: &c
							      atIndex: 2]))

	TEST(@"-[setArgument:atIndex:] #2", R([invocation setArgument: &i
							      atIndex: 3]))

	TEST(@"-[setArgument:atIndex:] #3", R([invocation setArgument: &stp
							      atIndex: 4]))

	TEST(@"-[setArgument:atIndex:] #4", R([invocation setArgument: &st
							      atIndex: 5]))

	TEST(@"-[getArgument:atIndex:] #1", R([invocation getArgument: &c2
							      atIndex: 2]) &&
	    c == c2)

	TEST(@"-[getArgument:atIndex:] #2", R([invocation getArgument: &i2
							      atIndex: 3]) &&
	    i == i2)

	TEST(@"-[getArgument:atIndex:] #3", R([invocation getArgument: &stp2
							      atIndex: 4]) &&
	    stp == stp2)

	TEST(@"-[getArgument:atIndex:] #4", R([invocation getArgument: &st2
							      atIndex: 5]) &&
	    memcmp(&st, &st2, sizeof(st)) == 0)

	[pool drain];
}
@end
