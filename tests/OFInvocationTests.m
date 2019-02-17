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

#include <assert.h>
#include <string.h>

#if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
# include <complex.h>
#endif

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

- (void)invocationTestMethod2: (id)obj
{
	assert(obj == self);
}

- (int)invocationTestMethod3: (int)i1
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

- (double)invocationTestMethod4: (double)d1
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

- (float)invocationTestMethod5: (double)d1
			      : (float)f2
			      : (float)f3
			      : (float)f4
			      : (float)f5
			      : (float)f6
			      : (float)f7
			      : (float)f8
			      : (float)f9
			      : (double)d10
			      : (float)f11
			      : (float)f12
			      : (float)f13
			      : (float)f14
			      : (float)f15
			      : (float)f16
{
	return (float)((d1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + d10 + f11 +
	    f12 + f13 + f14 + f15 + f16) / 16);
}

- (long double)invocationTestMethod6: (long double)d1
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

#if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
- (complex double)invocationTestMethod7: (complex float)c1
				       : (complex double)c2
				       : (complex float)c3
				       : (complex double)c4
				       : (complex float)c5
				       : (complex double)c6
				       : (complex float)c7
				       : (complex double)c8
				       : (complex float)c9
				       : (complex double)c10
				       : (complex float)c11
				       : (complex double)c12
				       : (complex float)c13
				       : (complex double)c14
				       : (complex float)c15
				       : (complex double)c16
{
	OF_ENSURE(creal(c1) == 1.0 && cimag(c1) == 0.5);
	OF_ENSURE(creal(c2) == 2.0 && cimag(c2) == 1.0);
	OF_ENSURE(creal(c3) == 3.0 && cimag(c3) == 1.5);
	OF_ENSURE(creal(c4) == 4.0 && cimag(c4) == 2.0);
	OF_ENSURE(creal(c5) == 5.0 && cimag(c5) == 2.5);
	OF_ENSURE(creal(c6) == 6.0 && cimag(c6) == 3.0);
	OF_ENSURE(creal(c7) == 7.0 && cimag(c7) == 3.5);
	OF_ENSURE(creal(c8) == 8.0 && cimag(c8) == 4.0);
	OF_ENSURE(creal(c9) == 9.0 && cimag(c9) == 4.5);
	OF_ENSURE(creal(c10) == 10.0 && cimag(c10) == 5.0);
	OF_ENSURE(creal(c11) == 11.0 && cimag(c11) == 5.5);
	OF_ENSURE(creal(c12) == 12.0 && cimag(c12) == 6.0);
	OF_ENSURE(creal(c13) == 13.0 && cimag(c13) == 6.5);
	OF_ENSURE(creal(c14) == 14.0 && cimag(c14) == 7.0);
	OF_ENSURE(creal(c15) == 15.0 && cimag(c15) == 7.5);
	OF_ENSURE(creal(c16) == 16.0 && cimag(c16) == 8.0);

	return (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 +
	    c12 + c13 + c14 + c15 + c16) / 16;
}

- (complex long double)invocationTestMethod8: (complex double)c1
					    : (complex float)c2
					    : (complex long double)c3
					    : (complex double)c4
					    : (complex float)c5
					    : (complex long double)c6
					    : (complex double)c7
					    : (complex float)c8
					    : (complex long double)c9
					    : (complex double)c10
					    : (complex float)c11
					    : (complex long double)c12
					    : (complex double)c13
					    : (complex float)c14
					    : (complex long double)c15
					    : (complex double)c16
{
	OF_ENSURE(creal(c1) == 1.0 && cimag(c1) == 0.5);
	OF_ENSURE(creal(c2) == 2.0 && cimag(c2) == 1.0);
	OF_ENSURE(creal(c3) == 3.0 && cimag(c3) == 1.5);
	OF_ENSURE(creal(c4) == 4.0 && cimag(c4) == 2.0);
	OF_ENSURE(creal(c5) == 5.0 && cimag(c5) == 2.5);
	OF_ENSURE(creal(c6) == 6.0 && cimag(c6) == 3.0);
	OF_ENSURE(creal(c7) == 7.0 && cimag(c7) == 3.5);
	OF_ENSURE(creal(c8) == 8.0 && cimag(c8) == 4.0);
	OF_ENSURE(creal(c9) == 9.0 && cimag(c9) == 4.5);
	OF_ENSURE(creal(c10) == 10.0 && cimag(c10) == 5.0);
	OF_ENSURE(creal(c11) == 11.0 && cimag(c11) == 5.5);
	OF_ENSURE(creal(c12) == 12.0 && cimag(c12) == 6.0);
	OF_ENSURE(creal(c13) == 13.0 && cimag(c13) == 6.5);
	OF_ENSURE(creal(c14) == 14.0 && cimag(c14) == 7.0);
	OF_ENSURE(creal(c15) == 15.0 && cimag(c15) == 7.5);
	OF_ENSURE(creal(c16) == 16.0 && cimag(c16) == 8.0);

	return (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 +
	    c12 + c13 + c14 + c15 + c16) / 16;
}
#endif

#ifdef __SIZEOF_INT128__
__extension__
- (__int128)invocationTestMethod9: (int)i1
				 : (__int128)i2
				 : (__int128)i3
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
	OF_ENSURE(i3 == mask + 3);
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

	return ((i1 + (int)i2 + (int)i3 + (int)i4 + i5 + (int)i6 + (int)i7 +
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

#ifdef __clang_analyzer__
	assert(invocation != nil);
#endif

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
	selector = @selector(invocationTestMethod2:);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];
	[invocation setArgument: &self
			atIndex: 2];

	TEST(@"-[invoke] #1", R([invocation invoke]))

	/* -[invoke] #2 */
	selector = @selector(invocationTestMethod3::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int j = 1; j <= 16; j++)
		[invocation setArgument: &j
				atIndex: j + 1];

	int intResult;
	TEST(@"-[invoke] #2", R([invocation invoke]) &&
	    R([invocation getReturnValue: &intResult]) && intResult == 8)

	/* -[invoke] #3 */
	selector = @selector(invocationTestMethod4::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		double d = j;
		[invocation setArgument: &d
				atIndex: j + 1];
	}

	double doubleResult;
	TEST(@"-[invoke] #3", R([invocation invoke]) &&
	    R([invocation getReturnValue: &doubleResult]) &&
	    doubleResult == 8.5)

	/* -[invoke] #4 */
	selector = @selector(invocationTestMethod5::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		float f = j;
		double d = j;

		if (j == 1 || j == 10)
			[invocation setArgument: &d
					atIndex: j + 1];
		else
			[invocation setArgument: &f
					atIndex: j + 1];
	}

	float floatResult;
	TEST(@"-[invoke] #4", R([invocation invoke]) &&
	    R([invocation getReturnValue: &floatResult]) && floatResult == 8.5)

	/* Only when encoding long doubles is supported */
	if (strcmp(@encode(double), @encode(long double)) != 0) {
		/* -[invoke] #5 */
		selector = @selector(invocationTestMethod6::::::::::::::::);
		invocation = [OFInvocation invocationWithMethodSignature:
		    [self methodSignatureForSelector: selector]];

		[invocation setArgument: &self
				atIndex: 0];
		[invocation setArgument: &selector
				atIndex: 1];

		for (int j = 1; j <= 16; j++) {
			long double d = j;
			[invocation setArgument: &d
					atIndex: j + 1];
		}

		long double longDoubleResult;
		TEST(@"-[invoke] #5", R([invocation invoke]) &&
		    R([invocation getReturnValue: &longDoubleResult]) &&
		    longDoubleResult == 8.5)
	}

# if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
	/* -[invoke] #6 */
	selector = @selector(invocationTestMethod7::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		complex float cf = j + 0.5 * j * I;
		complex double cd = j + 0.5 * j * I;

		if (j & 1)
			[invocation setArgument: &cf
					atIndex: j + 1];
		else
			[invocation setArgument: &cd
					atIndex: j + 1];
	}

	complex double complexDoubleResult;
	TEST(@"-[invoke] #6", R([invocation invoke]) &&
	    R([invocation getReturnValue: &complexDoubleResult]) &&
	    complexDoubleResult == 8.5 + 4.25 * I)

	/* Only when encoding complex long doubles is supported */
	if (strcmp(@encode(complex double),
	    @encode(complex long double)) != 0) {
		/* -[invoke] #7 */
		selector = @selector(invocationTestMethod8::::::::::::::::);
		invocation = [OFInvocation invocationWithMethodSignature:
		    [self methodSignatureForSelector: selector]];

		[invocation setArgument: &self
				atIndex: 0];
		[invocation setArgument: &selector
				atIndex: 1];

		for (int j = 1; j <= 16; j++) {
			complex double cd = j + 0.5 * j * I;
			complex float cf = j + 0.5 * j * I;
			complex long double cld = j + 0.5 * j * I;

			switch (j % 3) {
			case 0:
				[invocation setArgument: &cld
						atIndex: j + 1];
				break;
			case 1:
				[invocation setArgument: &cd
						atIndex: j + 1];
				break;
			case 2:
				[invocation setArgument: &cf
						atIndex: j + 1];
				break;
			}
		}

		complex long double complexLongDoubleResult;
		TEST(@"-[invoke] #7", R([invocation invoke]) &&
		    R([invocation getReturnValue: &complexLongDoubleResult]) &&
		    complexLongDoubleResult == 8.5 + 4.25 * I)
	}
# endif

# ifdef __SIZEOF_INT128__
	/* -[invoke] #8 */
	selector = @selector(invocationTestMethod9::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self
			atIndex: 0];
	[invocation setArgument: &selector
			atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		__extension__ __int128 i128 = 0xFFFFFFFFFFFFFFFF;
		i128 <<= 64;
		i128 |= j;

		if (j == 1 || j == 5)
			[invocation setArgument: &j
					atIndex: j + 1];
		else
			[invocation setArgument: &i128
					atIndex: j + 1];
	}

	__extension__ __int128 int128Result;
	TEST(@"-[invoke] #8", R([invocation invoke]) &&
	    R([invocation getReturnValue: &int128Result]) &&
	    int128Result == __extension__ ((__int128)0xFFFFFFFFFFFFFFFF << 64) +
	    8)
# endif
#endif

	[pool drain];
}
@end
