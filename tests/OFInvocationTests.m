/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include <assert.h>
#include <string.h>

#if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
# include <complex.h>
#endif

#import "TestsAppDelegate.h"

static OFString *const module = @"OFInvocation";

struct TestStruct {
	unsigned char c;
	unsigned int i;
};

@implementation TestsAppDelegate (OFInvocationTests)
- (struct TestStruct)invocationTestMethod1: (unsigned char)c
					  : (unsigned int)i
					  : (struct TestStruct *)ptr
					  : (struct TestStruct)st
{
	return st;
}

- (void)invocationTests
{
	void *pool = objc_autoreleasePoolPush();
	SEL selector = @selector(invocationTestMethod1::::);
	OFMethodSignature *sig = [self methodSignatureForSelector: selector];
	OFInvocation *invocation;
	struct TestStruct st, st2, *stp = &st, *stp2;
	unsigned const char c = 0xAA;
	unsigned char c2;
	const unsigned int i = 0x55555555;
	unsigned int i2;

	memset(&st, '\xFF', sizeof(st));
	st.c = 0x55;
	st.i = 0xAAAAAAAA;

	TEST(@"+[invocationWithMethodSignature:]",
	    (invocation = [OFInvocation invocationWithMethodSignature: sig]))

#ifdef __clang_analyzer__
	assert(invocation != nil);
#endif

	TEST(@"-[setReturnValue]", R([invocation setReturnValue: &st]))

	TEST(@"-[getReturnValue]", R([invocation getReturnValue: &st2]) &&
	    memcmp(&st, &st2, sizeof(st)) == 0)

	memset(&st2, '\0', sizeof(st2));

	TEST(@"-[setArgument:atIndex:] #1",
	    R([invocation setArgument: &c atIndex: 2]))

	TEST(@"-[setArgument:atIndex:] #2",
	    R([invocation setArgument: &i atIndex: 3]))

	TEST(@"-[setArgument:atIndex:] #3",
	    R([invocation setArgument: &stp atIndex: 4]))

	TEST(@"-[setArgument:atIndex:] #4",
	    R([invocation setArgument: &st atIndex: 5]))

	TEST(@"-[getArgument:atIndex:] #1",
	    R([invocation getArgument: &c2 atIndex: 2]) && c == c2)

	TEST(@"-[getArgument:atIndex:] #2",
	    R([invocation getArgument: &i2 atIndex: 3]) && i == i2)

	TEST(@"-[getArgument:atIndex:] #3",
	    R([invocation getArgument: &stp2 atIndex: 4]) && stp == stp2)

	TEST(@"-[getArgument:atIndex:] #4",
	    R([invocation getArgument: &st2 atIndex: 5]) &&
	    memcmp(&st, &st2, sizeof(st)) == 0)

	objc_autoreleasePoolPop(pool);
}
@end
