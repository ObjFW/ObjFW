/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFData.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFOutOfRangeException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFData";
const char *str = "Hello!";

@implementation TestsAppDelegate (OFDataTests)
- (void)dataTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMutableData *mutable;
	OFData *immutable;
	void *raw[2];

	TEST(@"+[dataWithItemSize:]",
	    (mutable = [OFMutableData dataWithItemSize: 4096]))

	OFObject *tmp = [[[OFObject alloc] init] autorelease];
	raw[0] = [tmp allocMemoryWithSize: 4096];
	raw[1] = [tmp allocMemoryWithSize: 4096];
	memset(raw[0], 0xFF, 4096);
	memset(raw[1], 0x42, 4096);

	TEST(@"-[addItem:]", R([mutable addItem: raw[0]]) &&
	    R([mutable addItem: raw[1]]))

	TEST(@"-[itemAtIndex:]",
	    memcmp([mutable itemAtIndex: 0], raw[0], 4096) == 0 &&
	    memcmp([mutable itemAtIndex: 1], raw[1], 4096) == 0)

	TEST(@"-[lastItem]", memcmp([mutable lastItem], raw[1], 4096) == 0)

	TEST(@"-[count]", [mutable count] == 2)

	TEST(@"-[isEqual:]",
	    (immutable = [OFData dataWithItems: [mutable items]
				      itemSize: [mutable itemSize]
					 count: [mutable count]]) &&
	    [immutable isEqual: mutable] &&
	    R([mutable removeLastItem]) && ![mutable isEqual: immutable])

	TEST(@"-[mutableCopy]",
	    (mutable = [[immutable mutableCopy] autorelease]) &&
	    [mutable isEqual: immutable])

	TEST(@"-[compare]", [mutable compare: immutable] == 0 &&
	    R([mutable removeLastItem]) &&
	    [immutable compare: mutable] == OF_ORDERED_DESCENDING &&
	    [mutable compare: immutable] == OF_ORDERED_ASCENDING &&
	    [[OFData dataWithItems: "aa"
			     count: 2] compare:
	    [OFData dataWithItems: "z"
			    count: 1]] == OF_ORDERED_ASCENDING)

	TEST(@"-[hash]", [immutable hash] == 0x634A529F)

	mutable = [OFMutableData dataWithItems: "abcdef"
					 count: 6];

	TEST(@"-[removeLastItem]", R([mutable removeLastItem]) &&
	    [mutable count] == 5 &&
	    memcmp([mutable items], "abcde", 5) == 0)

	TEST(@"-[removeItemsInRange:]",
	    R([mutable removeItemsInRange: of_range(1, 2)]) &&
	    [mutable count] == 3 && memcmp([mutable items], "ade", 3) == 0)

	TEST(@"-[insertItems:atIndex:count:]",
	    R([mutable insertItems: "bc"
			   atIndex: 1
			     count: 2]) && [mutable count] == 5 &&
	    memcmp([mutable items], "abcde", 5) == 0)

	TEST(@"-[MD5Hash]", [[mutable MD5Hash] isEqual: [@"abcde" MD5Hash]])

	TEST(@"-[RIPEMD160Hash]", [[mutable RIPEMD160Hash]
	    isEqual: [@"abcde" RIPEMD160Hash]])

	TEST(@"-[SHA1Hash]", [[mutable SHA1Hash] isEqual: [@"abcde" SHA1Hash]])

	TEST(@"-[SHA224Hash]", [[mutable SHA224Hash]
	    isEqual: [@"abcde" SHA224Hash]])

	TEST(@"-[SHA256Hash]", [[mutable SHA256Hash]
	    isEqual: [@"abcde" SHA256Hash]])

	TEST(@"-[SHA384Hash]", [[mutable SHA384Hash]
	    isEqual: [@"abcde" SHA384Hash]])

	TEST(@"-[SHA512Hash]", [[mutable SHA512Hash]
	    isEqual: [@"abcde" SHA512Hash]])

	TEST(@"-[stringByBase64Encoding]",
	    [[mutable stringByBase64Encoding] isEqual: @"YWJjZGU="])

	TEST(@"+[dataWithBase64EncodedString:]",
	    memcmp([[OFData dataWithBase64EncodedString: @"YWJjZGU="]
	    items], "abcde", 5) == 0)

	TEST(@"Building strings",
	    (mutable = [OFMutableData dataWithItems: str
					       count: 6]) &&
	    R([mutable addItem: ""]) &&
	    strcmp([mutable items], str) == 0)

	EXPECT_EXCEPTION(@"Detect out of range in -[itemAtIndex:]",
	    OFOutOfRangeException, [mutable itemAtIndex: [mutable count]])

	EXPECT_EXCEPTION(@"Detect out of range in -[addItems:count:]",
	    OFOutOfRangeException, [mutable addItems: raw[0]
					       count: SIZE_MAX])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeItemsInRange:]",
	    OFOutOfRangeException,
	    [mutable removeItemsInRange: of_range([mutable count], 1)])

	[pool drain];
}
@end
