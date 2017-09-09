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

#import "OFMethodSignature.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidFormatException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFMethodSignature";

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
	    strcmp([ms argumentTypeAtIndex: 3], "*") == 0)

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
	    "^{s0=csi(u1={s2=iii{s3=(u4=ic^v*)}})}") == 0)

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

	[pool drain];
}
@end
