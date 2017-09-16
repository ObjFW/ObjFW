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
- (struct test_struct)invocationTestMethod1: (unsigned char)c
					   : (unsigned int)i
					   : (struct test_struct *)ptr
					   : (struct test_struct)st
{
	return st;
}

- (int)invocationTestMethod2: (int)i1
			    : (int)i2
			    : (int)i3
			    : (int)i4
			    : (int)i5
			    : (int)i6
			    : (int)i7
			    : (int)i8
			    : (int)i9
			    : (int)i10
			    : (int)i11
			    : (int)i12
			    : (int)i13
			    : (int)i14
			    : (int)i15
			    : (int)i16
{
	return (i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + i10 + i11 +
	    i12 + i13 + i14 + i15 + i16) / 16;
}

- (double)invocationTestMethod3: (double)d1
			       : (double)d2
			       : (double)d3
			       : (double)d4
			       : (double)d5
			       : (double)d6
			       : (double)d7
			       : (double)d8
			       : (double)d9
			       : (double)d10
			       : (double)d11
			       : (double)d12
			       : (double)d13
			       : (double)d14
			       : (double)d15
			       : (double)d16
{
	return (d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8 + d9 + d10 + d11 +
	    d12 + d13 + d14 + d15 + d16) / 16;
}

- (long double)invocationTestMethod4: (long double)d1
				    : (long double)d2
				    : (long double)d3
				    : (long double)d4
				    : (long double)d5
				    : (long double)d6
				    : (long double)d7
				    : (long double)d8
				    : (long double)d9
				    : (long double)d10
				    : (long double)d11
				    : (long double)d12
				    : (long double)d13
				    : (long double)d14
				    : (long double)d15
				    : (long double)d16
{
	return (d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8 + d9 + d10 + d11 +
	    d12 + d13 + d14 + d15 + d16) / 16;
}

#ifdef __SIZEOF_INT128__
__extension__
- (__int128)invocationTestMethod5: (int)i1
				 : (__int128)i2
				 : (int)i3
				 : (__int128)i4
				 : (int)i5
				 : (__int128)i6
				 : (__int128)i7
				 : (__int128)i8
				 : (__int128)i9
				 : (__int128)i10
				 : (__int128)i11
				 : (__int128)i12
				 : (__int128)i13
				 : (__int128)i14
				 : (__int128)i15
				 : (__int128)i16
{
	__int128 mask = (__int128)0xFFFFFFFFFFFFFFFF << 64;

	OF_ENSURE(i1 == 1);
	OF_ENSURE(i2 == mask + 2);
	OF_ENSURE(i3 == 3);
	OF_ENSURE(i4 == mask + 4);
	OF_ENSURE(i5 == 5);
	OF_ENSURE(i6 == mask + 6);
	OF_ENSURE(i7 == mask + 7);
	OF_ENSURE(i8 == mask + 8);
	OF_ENSURE(i9 == mask + 9);
	OF_ENSURE(i10 == mask + 10);
	OF_ENSURE(i11 == mask + 11);
	OF_ENSURE(i12 == mask + 12);
	OF_ENSURE(i13 == mask + 13);
	OF_ENSURE(i14 == mask + 14);
	OF_ENSURE(i15 == mask + 15);
	OF_ENSURE(i16 == mask + 16);

	return ((i1 + (int)i2 + i3 + (int)i4 + i5 + (int)i6 + (int)i7 +
	    (int)i8 + (int)i9 + (int)i10 + (int)i11 + (int)i12 + (int)i13 +
	    (int)i14 + (int)i15 + (int)i16) / 16) + mask;
}
#endif

- (void)invocationTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	SEL selector = @selector(invocationTestMethod1::::);
	OFMethodSignature *sig = [self methodSignatureForSelector: selector];
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

#ifdef OF_INVOCATION_CAN_INVOKE
	/* -[invoke] #1 */
	selector = @selector(invocationTestMethod2::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int i = 1; i <= 16; i++)
		[invocation setArgument: &i
				atIndex: i + 1];

	int intResult;
	TEST(@"-[invoke] #1", R([invocation invoke]) &&
	    R([invocation getReturnValue: &intResult]) && intResult == 8)

	/* -[invoke] #2 */
	selector = @selector(invocationTestMethod3::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int i = 1; i <= 16; i++) {
		double d = i;
		[invocation setArgument: &d
				atIndex: i + 1];
	}

	double doubleResult;
	TEST(@"-[invoke] #2", R([invocation invoke]) &&
	    R([invocation getReturnValue: &doubleResult]) &&
	    doubleResult == 8.5)

	/* Only when encoding long doubles is supported */
	if (strcmp(@encode(double), @encode(long double)) != 0) {
		/* -[invoke] #3 */
		selector = @selector(invocationTestMethod4::::::::::::::::);
		invocation = [OFInvocation invocationWithMethodSignature:
		    [self methodSignatureForSelector: selector]];

		[invocation setArgument: &self
				atIndex: 0];
		[invocation setArgument: &selector
				atIndex: 1];

		for (int i = 1; i <= 16; i++) {
			long double d = i;
			[invocation setArgument: &d
					atIndex: i + 1];
		}

		long double longDoubleResult;
		TEST(@"-[invoke] #3", R([invocation invoke]) &&
		    R([invocation getReturnValue: &longDoubleResult]) &&
		    longDoubleResult == 8.5)
	}

# ifdef __SIZEOF_INT128__
	/* -[invoke] #4 */
	selector = @selector(invocationTestMethod5::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int i = 1; i <= 16; i++) {
		__extension__ __int128 i128 = 0xFFFFFFFFFFFFFFFF;
		i128 <<= 64;
		i128 |= i;

		if (i == 1 || i == 3 || i == 5)
			[invocation setArgument: &i
					atIndex: i + 1];
		else
			[invocation setArgument: &i128
					atIndex: i + 1];
	}

	__extension__ __int128 int128Result;
	TEST(@"-[invoke] #4", R([invocation invoke]) &&
	    R([invocation getReturnValue: &int128Result]) &&
	    int128Result == __extension__ ((__int128)0xFFFFFFFFFFFFFFFF << 64) +
	    8)
# endif
#endif

	[pool drain];
}
@end
