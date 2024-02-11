/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

- (void)setUp
{
	SEL selector = @selector(invocationTestMethod1::::);
	OFMethodSignature *signature =
	    [self methodSignatureForSelector: selector];

	_invocation = [[OFInvocation alloc] initWithMethodSignature: signature];
}

- (void)dealloc
{
	[_invocation release];

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
@end
