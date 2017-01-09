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

#import "OFDataArray.h"
#import "OFBigDataArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFOutOfRangeException.h"

#import "TestsAppDelegate.h"

static OFString *module;
const char *str = "Hello!";

@implementation TestsAppDelegate (OFDataArrayTests)
- (void)dataArrayTestsWithClass: (Class)class
{
	OFDataArray *array[4];
	void *data[2];
	Class other;

	TEST(@"+[dataArrayWithItemSize:]",
	    (array[0] = [class dataArrayWithItemSize: 4096]))

	data[0] = [array[0] allocMemoryWithSize: 4096];
	data[1] = [array[0] allocMemoryWithSize: 4096];
	memset(data[0], 0xFF, 4096);
	memset(data[1], 0x42, 4096);

	TEST(@"-[addItem:]", R([array[0] addItem: data[0]]) &&
	    R([array[0] addItem: data[1]]))

	TEST(@"-[itemAtIndex:]",
	    !memcmp([array[0] itemAtIndex: 0], data[0], 4096) &&
	    !memcmp([array[0] itemAtIndex: 1], data[1], 4096))

	TEST(@"-[lastItem]", !memcmp([array[0] lastItem], data[1], 4096))

	TEST(@"-[count]", [array[0] count] == 2)

	other = (class == [OFDataArray class]
	    ? [OFBigDataArray class]
	    : [OFDataArray class]);
	TEST(@"-[isEqual:]", (array[1] = [other dataArrayWithItemSize: 4096]) &&
	    R([array[1] addItems: [array[0] items]
			   count: [array[0] count]]) &&
	    [array[1] isEqual: array[0]] &&
	    R([array[1] removeLastItem]) && ![array[0] isEqual: array[1]])

	TEST(@"-[copy]", (array[1] = [[array[0] copy] autorelease]) &&
	    [array[0] isEqual: array[1]])

	array[2] = [OFDataArray dataArray];
	array[3] = [OFDataArray dataArray];
	[array[2] addItem: "a"];
	[array[2] addItem: "a"];
	[array[3] addItem: "z"];
	TEST(@"-[compare]", [array[0] compare: array[1]] == 0 &&
	    R([array[1] removeLastItem]) &&
	    [array[0] compare: array[1]] == OF_ORDERED_DESCENDING &&
	    [array[1] compare: array[0]] == OF_ORDERED_ASCENDING &&
	    [array[2] compare: array[3]] == OF_ORDERED_ASCENDING)

	TEST(@"-[hash]", [array[0] hash] == 0x634A529F)

	array[0] = [class dataArray];
	[array[0] addItems: "abcdef"
		     count: 6];

	TEST(@"-[removeLastItem]", R([array[0] removeLastItem]) &&
	    [array[0] count] == 5 &&
	    !memcmp([array[0] items], "abcde", 5))

	TEST(@"-[removeItemsInRange:]",
	    R([array[0] removeItemsInRange: of_range(1, 2)]) &&
	    [array[0] count] == 3 && !memcmp([array[0] items], "ade", 3))

	TEST(@"-[insertItems:atIndex:count:]",
	    R([array[0] insertItems: "bc"
			    atIndex: 1
			      count: 2]) && [array[0] count] == 5 &&
	    !memcmp([array[0] items], "abcde", 5))

	TEST(@"-[MD5Hash]", [[array[0] MD5Hash] isEqual: [@"abcde" MD5Hash]])

	TEST(@"-[RIPEMD160Hash]", [[array[0] RIPEMD160Hash]
	    isEqual: [@"abcde" RIPEMD160Hash]])

	TEST(@"-[SHA1Hash]", [[array[0] SHA1Hash] isEqual: [@"abcde" SHA1Hash]])

	TEST(@"-[SHA224Hash]", [[array[0] SHA224Hash]
	    isEqual: [@"abcde" SHA224Hash]])

	TEST(@"-[SHA256Hash]", [[array[0] SHA256Hash]
	    isEqual: [@"abcde" SHA256Hash]])

	TEST(@"-[SHA384Hash]", [[array[0] SHA384Hash]
	    isEqual: [@"abcde" SHA384Hash]])

	TEST(@"-[SHA512Hash]", [[array[0] SHA512Hash]
	    isEqual: [@"abcde" SHA512Hash]])

	TEST(@"-[stringByBase64Encoding]",
	    [[array[0] stringByBase64Encoding] isEqual: @"YWJjZGU="])

	TEST(@"+[dataArrayWithBase64EncodedString:]",
	    !memcmp([[class dataArrayWithBase64EncodedString: @"YWJjZGU="]
	    items], "abcde", 5))

	TEST(@"Building strings",
	    (array[0] = [class dataArray]) &&
	    R([array[0] addItems: (void*)str
			   count: 6]) && R([array[0] addItem: ""]) &&
	    !strcmp([array[0] items], str))

	EXPECT_EXCEPTION(@"Detect out of range in -[itemAtIndex:]",
	    OFOutOfRangeException, [array[0] itemAtIndex: [array[0] count]])

	EXPECT_EXCEPTION(@"Detect out of range in -[addItems:count:]",
	    OFOutOfRangeException, [array[0] addItems: data[0]
						count: SIZE_MAX])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeItemsInRange:]",
	    OFOutOfRangeException,
	    [array[0] removeItemsInRange: of_range([array[0] count], 1)])
}

- (void)dataArrayTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	module = @"OFDataArray";
	[self dataArrayTestsWithClass: [OFDataArray class]];

	module = @"OFBigDataArray";
	[self dataArrayTestsWithClass: [OFBigDataArray class]];

	[pool drain];
}
@end
