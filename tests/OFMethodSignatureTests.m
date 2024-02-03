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

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
# include <complex.h>
#endif

#import "TestsAppDelegate.h"

static OFString *const module = @"OFMethodSignature";

struct Test1Struct {
	char c;
	int i;
	char d;
};

struct Test2Struct {
	char c;
	struct {
		short s;
		int i;
	} st;
	union {
		char c;
		int i;
	} u;
	double d;
};

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
struct Test3Struct {
	char c;
	complex double cd;
};
#endif

union Test3Union {
	char c;
	int i;
	double d;
};

union Test4Union {
	char c;
	struct {
		short x, y;
	} st;
	int i;
	union {
		float f;
		double d;
	} u;
};

@implementation TestsAppDelegate (OFMethodSignatureTests)
- (void)methodSignatureTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMethodSignature *methodSignature;

	TEST(@"-[signatureWithObjCTypes:] #1",
	    (methodSignature = [OFMethodSignature signatureWithObjCTypes:
	    "i28@0:8S16*20"]) &&
	    methodSignature.numberOfArguments == 4 &&
	    strcmp(methodSignature.methodReturnType, "i") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 0], "@") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 1], ":") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 2], "S") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 3], "*") == 0 &&
	    methodSignature.frameLength == 28 &&
	    [methodSignature argumentOffsetAtIndex: 0] == 0 &&
	    [methodSignature argumentOffsetAtIndex: 1] == 8 &&
	    [methodSignature argumentOffsetAtIndex: 2] == 16 &&
	    [methodSignature argumentOffsetAtIndex: 3] == 20)

	TEST(@"-[signatureWithObjCTypes:] #2",
	    (methodSignature = [OFMethodSignature signatureWithObjCTypes:
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}24@0:8"
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}16"]) &&
	    methodSignature.numberOfArguments == 3 &&
	    strcmp(methodSignature.methodReturnType,
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 0], "@") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 1], ":") == 0 &&
	    strcmp([methodSignature argumentTypeAtIndex: 2],
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}") == 0 &&
	    methodSignature.frameLength == 24 &&
	    [methodSignature argumentOffsetAtIndex: 0] == 0 &&
	    [methodSignature argumentOffsetAtIndex: 1] == 8 &&
	    [methodSignature argumentOffsetAtIndex: 2] == 16)

	EXPECT_EXCEPTION(@"-[signatureWithObjCTypes:] #3",
	    OFInvalidFormatException,
	    [OFMethodSignature signatureWithObjCTypes: "{ii"])

	EXPECT_EXCEPTION(@"-[signatureWithObjCTypes:] #4",
	    OFInvalidFormatException,
	    [OFMethodSignature signatureWithObjCTypes: ""])

	EXPECT_EXCEPTION(@"-[signatureWithObjCTypes:] #5",
	    OFInvalidFormatException,
	    [OFMethodSignature signatureWithObjCTypes: "0"])

	EXPECT_EXCEPTION(@"-[signatureWithObjCTypes:] #6",
	    OFInvalidFormatException,
	    [OFMethodSignature signatureWithObjCTypes: "{{}0"])

	TEST(@"OFSizeOfTypeEncoding() #1",
	    OFSizeOfTypeEncoding(@encode(struct Test1Struct)) ==
	    sizeof(struct Test1Struct))

	TEST(@"OFSizeOfTypeEncoding() #2",
	    OFSizeOfTypeEncoding(@encode(struct Test2Struct)) ==
	    sizeof(struct Test2Struct))

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H) && \
    OF_GCC_VERSION >= 402
	TEST(@"OFSizeOfTypeEncoding() #3",
	    OFSizeOfTypeEncoding(@encode(struct Test3Struct)) ==
	    sizeof(struct Test3Struct))
#endif

	TEST(@"OFSizeOfTypeEncoding() #4",
	    OFSizeOfTypeEncoding(@encode(union Test3Union)) ==
	    sizeof(union Test3Union))

	TEST(@"OFSizeOfTypeEncoding() #5",
	    OFSizeOfTypeEncoding(@encode(union Test4Union)) ==
	    sizeof(union Test4Union))

	TEST(@"OFSizeOfTypeEncoding() #6",
	    OFSizeOfTypeEncoding(@encode(struct Test1Struct [5])) ==
	    sizeof(struct Test1Struct [5]))

	TEST(@"OFAlignmentOfTypeEncoding() #1",
	    OFAlignmentOfTypeEncoding(@encode(struct Test1Struct)) ==
	    OF_ALIGNOF(struct Test1Struct))

	TEST(@"OFAlignmentOfTypeEncoding() #2",
	    OFAlignmentOfTypeEncoding(@encode(struct Test2Struct)) ==
	    OF_ALIGNOF(struct Test2Struct))

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H) && \
    OF_GCC_VERSION >= 402
	TEST(@"OFAlignmentOfTypeEncoding() #3",
	    OFAlignmentOfTypeEncoding(@encode(struct Test3Struct)) ==
	    OF_ALIGNOF(struct Test3Struct))
#endif

	TEST(@"OFAlignmentOfTypeEncoding() #4",
	    OFAlignmentOfTypeEncoding(@encode(union Test3Union)) ==
	    OF_ALIGNOF(union Test3Union))

	TEST(@"OFAlignmentOfTypeEncoding() #5",
	    OFAlignmentOfTypeEncoding(@encode(union Test4Union)) ==
	    OF_ALIGNOF(union Test4Union))

	TEST(@"OFAlignmentOfTypeEncoding() #6",
	    OFAlignmentOfTypeEncoding(@encode(struct Test1Struct [5])) ==
	    OF_ALIGNOF(struct Test1Struct [5]))

	objc_autoreleasePoolPop(pool);
}
@end
