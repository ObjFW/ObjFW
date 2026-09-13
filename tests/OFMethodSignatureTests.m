/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
# include <complex.h>
#endif

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFMethodSignatureTests: OTTestCase
@end

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

@implementation OFMethodSignatureTests
- (void)testSignatureWithObjCTypes
{
	OFMethodSignature *methodSignature;

	methodSignature =
	    [OFMethodSignature signatureWithObjCTypes: "i28@0:8S16*20"];
	OTAssertEqual(methodSignature.numberOfArguments, 4);
	OTAssertEqual(strcmp(methodSignature.methodReturnType, "i"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 0], "@"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 1], ":"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 2], "S"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 3], "*"), 0);
	OTAssertEqual(methodSignature.frameLength, 28);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 0], 0);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 1], 8);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 2], 16);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 3], 20);

	methodSignature = [OFMethodSignature signatureWithObjCTypes:
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}24@0:8"
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}16"];
	OTAssertEqual(methodSignature.numberOfArguments, 3);
	OTAssertEqual(strcmp(methodSignature.methodReturnType,
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 0], "@"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 1], ":"), 0);
	OTAssertEqual(strcmp([methodSignature argumentTypeAtIndex: 2],
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}"), 0);
	OTAssertEqual(methodSignature.frameLength, 24);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 0], 0);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 1], 8);
	OTAssertEqual([methodSignature argumentOffsetAtIndex: 2], 16);
}

- (void)testSignatureWithObjCTypesFailsWithInvalidFormat
{
	OTAssertThrowsSpecific(
	    [OFMethodSignature signatureWithObjCTypes: "{ii"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFMethodSignature signatureWithObjCTypes: ""],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific([OFMethodSignature signatureWithObjCTypes: "0"],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [OFMethodSignature signatureWithObjCTypes: "{{}0"],
	    OFInvalidFormatException);
}

- (void)testSizeOfTypeEncoding
{
	OTAssertEqual(OFSizeOfTypeEncoding(@encode(struct Test1Struct)),
	    sizeof(struct Test1Struct));

	OTAssertEqual(OFSizeOfTypeEncoding(@encode(struct Test2Struct)),
	    sizeof(struct Test2Struct));

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H) && \
    OF_GCC_VERSION >= 402
	OTAssertEqual(OFSizeOfTypeEncoding(@encode(struct Test3Struct)),
	    sizeof(struct Test3Struct));
#endif

	OTAssertEqual(OFSizeOfTypeEncoding(@encode(union Test3Union)),
	    sizeof(union Test3Union));

	OTAssertEqual(OFSizeOfTypeEncoding(@encode(union Test4Union)),
	    sizeof(union Test4Union));

	OTAssertEqual(OFSizeOfTypeEncoding(@encode(struct Test1Struct [5])),
	    sizeof(struct Test1Struct [5]));
}

- (void)testAlignmentOfTypeEncoding
{
	OTAssertEqual(OFAlignmentOfTypeEncoding(@encode(struct Test1Struct)),
	    OF_ALIGNOF(struct Test1Struct));

	OTAssertEqual(OFAlignmentOfTypeEncoding(@encode(struct Test2Struct)),
	    OF_ALIGNOF(struct Test2Struct));

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H) && \
    OF_GCC_VERSION >= 402
	OTAssertEqual(OFAlignmentOfTypeEncoding(@encode(struct Test3Struct)),
	    OF_ALIGNOF(struct Test3Struct));
#endif

	OTAssertEqual(OFAlignmentOfTypeEncoding(@encode(union Test3Union)),
	    OF_ALIGNOF(union Test3Union));

	OTAssertEqual(OFAlignmentOfTypeEncoding(@encode(union Test4Union)),
	    OF_ALIGNOF(union Test4Union));

	OTAssertEqual(
	    OFAlignmentOfTypeEncoding(@encode(struct Test1Struct [5])),
	    OF_ALIGNOF(struct Test1Struct [5]));
}
@end
