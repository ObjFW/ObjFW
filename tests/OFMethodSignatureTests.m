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

#include <string.h>

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
# include <complex.h>
#endif

#import "TestsAppDelegate.h"

static OFString *module = @"OFMethodSignature";

struct test1_struct {
	char c;
	int i;
	char d;
};

struct test2_struct {
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
struct test3_struct {
	char c;
	complex double cd;
};
#endif

union test3_union {
	char c;
	int i;
	double d;
};

union test4_union {
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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMethodSignature *ms;

	TEST(@"-[:signatureWithObjCTypes:] #1",
	    (ms = [OFMethodSignature signatureWithObjCTypes:
	    "i28@0:8S16*20"]) && [ms numberOfArguments] == 4 &&
	    strcmp([ms methodReturnType], "i") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 0], "@") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 1], ":") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 2], "S") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 3], "*") == 0 &&
	    [ms frameLength] == 28 && [ms argumentOffsetAtIndex: 0] == 0 &&
	    [ms argumentOffsetAtIndex: 1] == 8 &&
	    [ms argumentOffsetAtIndex: 2] == 16 &&
	    [ms argumentOffsetAtIndex: 3] == 20)

	TEST(@"-[signatureWithObjCTypes:] #2",
	    (ms = [OFMethodSignature signatureWithObjCTypes:
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}24@0:8"
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}16"]) &&
	    [ms numberOfArguments] == 3 &&
	    strcmp([ms methodReturnType],
	    "{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 0], "@") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 1], ":") == 0 &&
	    strcmp([ms argumentTypeAtIndex: 2],
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}") == 0 &&
	    [ms frameLength] == 24 && [ms argumentOffsetAtIndex: 0] == 0 &&
	    [ms argumentOffsetAtIndex: 1] == 8 &&
	    [ms argumentOffsetAtIndex: 2] == 16)

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

	TEST(@"of_sizeof_type_encoding() #1",
	    of_sizeof_type_encoding(@encode(struct test1_struct)) ==
	    sizeof(struct test1_struct))

	TEST(@"of_sizeof_type_encoding() #2",
	    of_sizeof_type_encoding(@encode(struct test2_struct)) ==
	    sizeof(struct test2_struct))

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
	TEST(@"of_sizeof_type_encoding() #3",
	    of_sizeof_type_encoding(@encode(struct test3_struct)) ==
	    sizeof(struct test3_struct))
#endif

	TEST(@"of_sizeof_type_encoding() #4",
	    of_sizeof_type_encoding(@encode(union test3_union)) ==
	    sizeof(union test3_union))

	TEST(@"of_sizeof_type_encoding() #5",
	    of_sizeof_type_encoding(@encode(union test4_union)) ==
	    sizeof(union test4_union))

	TEST(@"of_sizeof_type_encoding() #6",
	    of_sizeof_type_encoding(@encode(struct test1_struct [5])) ==
	    sizeof(struct test1_struct [5]))

	TEST(@"of_alignof_type_encoding() #1",
	    of_alignof_type_encoding(@encode(struct test1_struct)) ==
	    OF_ALIGNOF(struct test1_struct))

	TEST(@"of_alignof_type_encoding() #2",
	    of_alignof_type_encoding(@encode(struct test2_struct)) ==
	    OF_ALIGNOF(struct test2_struct))

#if !defined(__STDC_NO_COMPLEX__) && defined(HAVE_COMPLEX_H)
	TEST(@"of_alignof_type_encoding() #3",
	    of_alignof_type_encoding(@encode(struct test3_struct)) ==
	    OF_ALIGNOF(struct test3_struct))
#endif

	TEST(@"of_alignof_type_encoding() #4",
	    of_alignof_type_encoding(@encode(union test3_union)) ==
	    OF_ALIGNOF(union test3_union))

	TEST(@"of_alignof_type_encoding() #5",
	    of_alignof_type_encoding(@encode(union test4_union)) ==
	    OF_ALIGNOF(union test4_union))

	TEST(@"of_alignof_type_encoding() #6",
	    of_alignof_type_encoding(@encode(struct test1_struct [5])) ==
	    OF_ALIGNOF(struct test1_struct [5]))

	[pool drain];
}
@end
