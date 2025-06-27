/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
# include <complex.h>
#endif

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFInvocationTests: OTTestCase
{
	OFInvocation *_invocation;
}
@end

struct TestStruct {
	unsigned char c;
	unsigned int i;
};

@implementation OFInvocationTests
- (struct TestStruct)invocationTestMethod1: (unsigned char)c
					  : (unsigned int)i
					  : (struct TestStruct *)testStructPtr
					  : (struct TestStruct)testStruct
{
	return testStruct;
}

#ifdef OF_INVOCATION_CAN_INVOKE
- (void)invocationTestMethod2: (id)obj
{
	OTAssertEqual(obj, self);
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

# if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
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
	OFEnsure(creal(c1) == 1.0 && cimag(c1) == 0.5);
	OFEnsure(creal(c2) == 2.0 && cimag(c2) == 1.0);
	OFEnsure(creal(c3) == 3.0 && cimag(c3) == 1.5);
	OFEnsure(creal(c4) == 4.0 && cimag(c4) == 2.0);
	OFEnsure(creal(c5) == 5.0 && cimag(c5) == 2.5);
	OFEnsure(creal(c6) == 6.0 && cimag(c6) == 3.0);
	OFEnsure(creal(c7) == 7.0 && cimag(c7) == 3.5);
	OFEnsure(creal(c8) == 8.0 && cimag(c8) == 4.0);
	OFEnsure(creal(c9) == 9.0 && cimag(c9) == 4.5);
	OFEnsure(creal(c10) == 10.0 && cimag(c10) == 5.0);
	OFEnsure(creal(c11) == 11.0 && cimag(c11) == 5.5);
	OFEnsure(creal(c12) == 12.0 && cimag(c12) == 6.0);
	OFEnsure(creal(c13) == 13.0 && cimag(c13) == 6.5);
	OFEnsure(creal(c14) == 14.0 && cimag(c14) == 7.0);
	OFEnsure(creal(c15) == 15.0 && cimag(c15) == 7.5);
	OFEnsure(creal(c16) == 16.0 && cimag(c16) == 8.0);

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
	OTAssertEqual(creal(c1), 1.0);
	OTAssertEqual(cimag(c1), 0.5);

	OTAssertEqual(creal(c2), 2.0);
	OTAssertEqual(cimag(c2), 1.0);

	OTAssertEqual(creal(c3), 3.0);
	OTAssertEqual(cimag(c3), 1.5);

	OTAssertEqual(creal(c4), 4.0);
	OTAssertEqual(cimag(c4), 2.0);

	OTAssertEqual(creal(c5), 5.0);
	OTAssertEqual(cimag(c5), 2.5);

	OTAssertEqual(creal(c6), 6.0);
	OTAssertEqual(cimag(c6), 3.0);

	OTAssertEqual(creal(c7), 7.0);
	OTAssertEqual(cimag(c7), 3.5);

	OTAssertEqual(creal(c8), 8.0);
	OTAssertEqual(cimag(c8), 4.0);

	OTAssertEqual(creal(c9), 9.0);
	OTAssertEqual(cimag(c9), 4.5);

	OTAssertEqual(creal(c10), 10.0);
	OTAssertEqual(cimag(c10), 5.0);

	OTAssertEqual(creal(c11), 11.0);
	OTAssertEqual(cimag(c11), 5.5);

	OTAssertEqual(creal(c12), 12.0);
	OTAssertEqual(cimag(c12), 6.0);

	OTAssertEqual(creal(c13), 13.0);
	OTAssertEqual(cimag(c13), 6.5);

	OTAssertEqual(creal(c14), 14.0);
	OTAssertEqual(cimag(c14), 7.0);

	OTAssertEqual(creal(c15), 15.0);
	OTAssertEqual(cimag(c15), 7.5);

	OTAssertEqual(creal(c16), 16.0);
	OTAssertEqual(cimag(c16), 8.0);

	return (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 +
	    c12 + c13 + c14 + c15 + c16) / 16;
}
# endif

# ifdef __SIZEOF_INT128__
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

	OTAssertEqual(i1, 1);
	OTAssertEqual(i2, mask + 2);
	OTAssertEqual(i3, mask + 3);
	OTAssertEqual(i4, mask + 4);
	OTAssertEqual(i5, 5);
	OTAssertEqual(i6, mask + 6);
	OTAssertEqual(i7, mask + 7);
	OTAssertEqual(i8, mask + 8);
	OTAssertEqual(i9, mask + 9);
	OTAssertEqual(i10, mask + 10);
	OTAssertEqual(i11, mask + 11);
	OTAssertEqual(i12, mask + 12);
	OTAssertEqual(i13, mask + 13);
	OTAssertEqual(i14, mask + 14);
	OTAssertEqual(i15, mask + 15);
	OTAssertEqual(i16, mask + 16);

	return ((i1 + (int)i2 + (int)i3 + (int)i4 + i5 + (int)i6 + (int)i7 +
	    (int)i8 + (int)i9 + (int)i10 + (int)i11 + (int)i12 + (int)i13 +
	    (int)i14 + (int)i15 + (int)i16) / 16) + mask;
}
# endif
#endif

- (void)setUp
{
	[super setUp];

	SEL selector = @selector(invocationTestMethod1::::);
	OFMethodSignature *signature =
	    [self methodSignatureForSelector: selector];

	_invocation = [[OFInvocation alloc] initWithMethodSignature: signature];
}

- (void)dealloc
{
	objc_release(_invocation);

	[super dealloc];
}

- (void)testSetAndGetReturnValue
{
	struct TestStruct testStruct, testStruct2;

	memset(&testStruct, 0xFF, sizeof(testStruct));
	testStruct.c = 0x55;
	testStruct.i = 0xAAAAAAAA;

	[_invocation setReturnValue: &testStruct];
	[_invocation getReturnValue: &testStruct2];
	OTAssertEqual(memcmp(&testStruct, &testStruct2, sizeof(testStruct)), 0);
}

- (void)testSetAndGetArgumentAtIndex
{
	struct TestStruct testStruct, testStruct2;
	struct TestStruct *testStructPtr = &testStruct, *testStructPtr2;
	unsigned const char c = 0xAA;
	unsigned char c2;
	const unsigned int i = 0x55555555;
	unsigned int i2;

	memset(&testStruct, 0xFF, sizeof(testStruct));
	testStruct.c = 0x55;
	testStruct.i = 0xAAAAAAAA;

	memset(&testStruct2, 0, sizeof(testStruct2));

	[_invocation setArgument: &c atIndex: 2];
	[_invocation setArgument: &i atIndex: 3];
	[_invocation setArgument: &testStructPtr atIndex: 4];
	[_invocation setArgument: &testStruct atIndex: 5];

	[_invocation getArgument: &c2 atIndex: 2];
	OTAssertEqual(c, c2);

	[_invocation getArgument: &i2 atIndex: 3];
	OTAssertEqual(i, i2);

	[_invocation getArgument: &testStructPtr2 atIndex: 4];
	OTAssertEqual(testStructPtr, testStructPtr2);

	[_invocation getArgument: &testStruct2 atIndex: 5];
	OTAssertEqual(memcmp(&testStruct, &testStruct2, sizeof(testStruct)), 0);
}

#ifdef OF_INVOCATION_CAN_INVOKE
- (void)testInvoke1
{
	SEL selector = @selector(invocationTestMethod2:);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];
	[invocation setArgument: &self atIndex: 2];

	[invocation invoke];
}

- (void)testInvoke2
{
	SEL selector = @selector(invocationTestMethod3::::::::::::::::);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];
	int result;

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++)
		[invocation setArgument: &j atIndex: j + 1];

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8);
}

- (void)testInvoke3
{
	SEL selector = @selector(invocationTestMethod4::::::::::::::::);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];
	double result;

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		double d = j;
		[invocation setArgument: &d atIndex: j + 1];
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8.5);
}

- (void)testInvoke4
{
	SEL selector = @selector(invocationTestMethod5::::::::::::::::);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];
	float result;

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		float f = j;
		double d = j;

		if (j == 1 || j == 10)
			[invocation setArgument: &d atIndex: j + 1];
		else
			[invocation setArgument: &f atIndex: j + 1];
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8.5);
}

- (void)testInvoke5
{
	SEL selector;
	OFInvocation *invocation;
	long double result;

	if (strcmp(@encode(double), @encode(long double)) == 0)
		OTSkip(@"Encoding long double not supported");

	selector = @selector(invocationTestMethod6::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		long double d = j;
		[invocation setArgument: &d atIndex: j + 1];
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8.5);
}

# if defined(HAVE_COMPLEX_H) && !defined(__STDC_NO_COMPLEX__)
- (void)testInvoke6
{
	SEL selector = @selector(invocationTestMethod7::::::::::::::::);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];
	complex double result;

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		complex float cf = j + 0.5 * j * I;
		complex double cd = j + 0.5 * j * I;

		if (j & 1)
			[invocation setArgument: &cf atIndex: j + 1];
		else
			[invocation setArgument: &cd atIndex: j + 1];
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8.5 + 4.25 * I);
}

- (void)testInvoke7
{
	SEL selector;
	OFInvocation *invocation;
	complex long double result;

	if (strcmp(@encode(complex double), @encode(complex long double)) == 0)
		OTSkip(@"Encoding complex long double not supported");

	selector = @selector(invocationTestMethod8::::::::::::::::);
	invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		complex double cd = j + 0.5 * j * I;
		complex float cf = j + 0.5 * j * I;
		complex long double cld = j + 0.5 * j * I;

		switch (j % 3) {
		case 0:
			[invocation setArgument: &cld atIndex: j + 1];
			break;
		case 1:
			[invocation setArgument: &cd atIndex: j + 1];
			break;
		case 2:
			[invocation setArgument: &cf atIndex: j + 1];
			break;
		}
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result, 8.5 + 4.25 * I);
}
# endif

/* Currently broken. */
# if 0 && defined(__SIZEOF_INT128__)
- (void)testInvoke8
{
	SEL selector = @selector(invocationTestMethod9::::::::::::::::);
	OFInvocation *invocation = [OFInvocation invocationWithMethodSignature:
	    [self methodSignatureForSelector: selector]];
	__extension__ __int128 result;

	[invocation setArgument: &self atIndex: 0];
	[invocation setArgument: &selector atIndex: 1];

	for (int j = 1; j <= 16; j++) {
		__extension__ __int128 i128 = 0xFFFFFFFFFFFFFFFF;
		i128 <<= 64;
		i128 |= j;

		if (j == 1 || j == 5)
			[invocation setArgument: &j atIndex: j + 1];
		else
			[invocation setArgument: &i128 atIndex: j + 1];
	}

	[invocation invoke];
	[invocation getReturnValue: &result];
	OTAssertEqual(result,
	    __extension__ ((__int128)0xFFFFFFFFFFFFFFFF << 64) + 8);
}
# endif
#endif
@end
