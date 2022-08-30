/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFData";

@implementation TestsAppDelegate (OFDataTests)
- (void)dataTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *mutableData;
	OFData *data;
	void *raw[2];
	OFRange range;

	TEST(@"+[dataWithItemSize:]",
	    (mutableData = [OFMutableData dataWithItemSize: 4096]))

	raw[0] = OFAllocMemory(1, 4096);
	raw[1] = OFAllocMemory(1, 4096);
	memset(raw[0], 0xFF, 4096);
	memset(raw[1], 0x42, 4096);

	TEST(@"-[addItem:]", R([mutableData addItem: raw[0]]) &&
	    R([mutableData addItem: raw[1]]))

	TEST(@"-[itemAtIndex:]",
	    memcmp([mutableData itemAtIndex: 0], raw[0], 4096) == 0 &&
	    memcmp([mutableData itemAtIndex: 1], raw[1], 4096) == 0)

	TEST(@"-[lastItem]", memcmp(mutableData.lastItem, raw[1], 4096) == 0)

	TEST(@"-[count]", mutableData.count == 2)

	TEST(@"-[isEqual:]",
	    (data = [OFData dataWithItems: mutableData.items
				    count: mutableData.count
				 itemSize: mutableData.itemSize]) &&
	    [data isEqual: mutableData] &&
	    R([mutableData removeLastItem]) && ![mutableData isEqual: data])

	TEST(@"-[mutableCopy]",
	    (mutableData = [[data mutableCopy] autorelease]) &&
	    [mutableData isEqual: data])

	TEST(@"-[compare]", [mutableData compare: data] == 0 &&
	    R([mutableData removeLastItem]) &&
	    [data compare: mutableData] == OFOrderedDescending &&
	    [mutableData compare: data] == OFOrderedAscending &&
	    [[OFData dataWithItems: "aa" count: 2] compare:
	    [OFData dataWithItems: "z" count: 1]] == OFOrderedAscending)

	TEST(@"-[hash]", data.hash == 0x634A529F)

	mutableData = [OFMutableData dataWithItems: "abcdef" count: 6];

	TEST(@"-[removeLastItem]",
	    R([mutableData removeLastItem]) && mutableData.count == 5 &&
	    memcmp(mutableData.items, "abcde", 5) == 0)

	TEST(@"-[removeItemsInRange:]",
	    R([mutableData removeItemsInRange: OFMakeRange(1, 2)]) &&
	    mutableData.count == 3 && memcmp(mutableData.items, "ade", 3) == 0)

	TEST(@"-[insertItems:atIndex:count:]",
	    R([mutableData insertItems: "bc" atIndex: 1 count: 2]) &&
	    mutableData.count == 5 &&
	    memcmp(mutableData.items, "abcde", 5) == 0)

	data = [OFData dataWithItems: "aaabaccdacaabb" count: 7 itemSize: 2];

	range = [data rangeOfData: [OFData dataWithItems: "aa"
						   count: 1
						itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #1",
	    range.location == 0 && range.length == 1)

	range = [data rangeOfData: [OFData dataWithItems: "aa"
						   count: 1
						itemSize: 2]
			  options: OFDataSearchBackwards
			    range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #2",
	    range.location == 5 && range.length == 1)

	range = [data rangeOfData: [OFData dataWithItems: "ac"
						   count: 1
						itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #3",
	    range.location == 2 && range.length == 1)

	range = [data rangeOfData: [OFData dataWithItems: "aabb"
						   count: 2
						itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #4",
	    range.location == 5 && range.length == 2)

	TEST(@"-[rangeOfData:options:range:] #5",
	    R(range = [data rangeOfData: [OFData dataWithItems: "aa"
							 count: 1
						      itemSize: 2]
				options: 0
				  range: OFMakeRange(1, 6)]) &&
	    range.location == 5 && range.length == 1)

	range = [data rangeOfData: [OFData dataWithItems: "aa"
						   count: 1
						itemSize: 2]
			  options: OFDataSearchBackwards
			    range: OFMakeRange(0, 5)];
	TEST(@"-[rangeOfData:options:range:] #6",
	    range.location == 0 && range.length == 1)

	EXPECT_EXCEPTION(
	    @"-[rangeOfData:options:range:] failing on different itemSize",
	    OFInvalidArgumentException,
	    [data rangeOfData: [OFData dataWithItems: "aaa"
					       count: 1
					    itemSize: 3]
		      options: 0
			range: OFMakeRange(0, 1)])

	EXPECT_EXCEPTION(
	    @"-[rangeOfData:options:range:] failing on out of range",
	    OFOutOfRangeException,
	    [data rangeOfData: [OFData dataWithItems: "" count: 0 itemSize: 2]
		      options: 0
			range: OFMakeRange(8, 1)])

	TEST(@"-[subdataWithRange:]",
	    [[data subdataWithRange: OFMakeRange(2, 4)]
	    isEqual: [OFData dataWithItems: "accdacaa" count: 4 itemSize: 2]] &&
	    [[mutableData subdataWithRange: OFMakeRange(2, 3)]
	    isEqual: [OFData dataWithItems: "cde" count: 3]])

	EXPECT_EXCEPTION(@"-[subdataWithRange:] failing on out of range #1",
	    OFOutOfRangeException,
	    [data subdataWithRange: OFMakeRange(7, 1)])

	EXPECT_EXCEPTION(@"-[subdataWithRange:] failing on out of range #2",
	    OFOutOfRangeException,
	    [mutableData subdataWithRange: OFMakeRange(6, 1)])

	TEST(@"-[stringByMD5Hashing]",
	    [mutableData.stringByMD5Hashing
	    isEqual: @"ab56b4d92b40713acc5af89985d4b786"])

	TEST(@"-[stringByRIPEMD160Hashing]",
	    [mutableData.stringByRIPEMD160Hashing
	    isEqual: @"973398b6e6c6cfa6b5e6a5173f195ce3274bf828"])

	TEST(@"-[stringBySHA1Hashing]",
	    [mutableData.stringBySHA1Hashing
	    isEqual: @"03de6c570bfe24bfc328ccd7ca46b76eadaf4334"])

	TEST(@"-[stringBySHA224Hashing]",
	    [mutableData.stringBySHA224Hashing
	    isEqual: @"bdd03d560993e675516ba5a50638b6531ac2ac3d5847c61916cfced6"
	    ])

	TEST(@"-[stringBySHA256Hashing]",
	    [mutableData.stringBySHA256Hashing
	    isEqual: @"36bbe50ed96841d10443bcb670d6554f0a34b761be67ec9c4a8ad2c0"
		     @"c44ca42c"])

	TEST(@"-[stringBySHA384Hashing]",
	    [mutableData.stringBySHA384Hashing
	    isEqual: @"4c525cbeac729eaf4b4665815bc5db0c84fe6300068a727cf74e2813"
		     @"521565abc0ec57a37ee4d8be89d097c0d2ad52f0"])

	TEST(@"-[stringBySHA512Hashing]",
	    [mutableData.stringBySHA512Hashing
	    isEqual: @"878ae65a92e86cac011a570d4c30a7eaec442b85ce8eca0c2952b5e3"
		     @"cc0628c2e79d889ad4d5c7c626986d452dd86374b6ffaa7cd8b67665"
		     @"bef2289a5c70b0a1"])

	TEST(@"-[stringByBase64Encoding]",
	    [mutableData.stringByBase64Encoding isEqual: @"YWJjZGU="])

	TEST(@"+[dataWithBase64EncodedString:]",
	    memcmp([[OFData dataWithBase64EncodedString: @"YWJjZGU="] items],
	    "abcde", 5) == 0)

	TEST(@"Building strings",
	    (mutableData = [OFMutableData dataWithItems: "Hello!" count: 6]) &&
	    R([mutableData addItem: ""]) &&
	    strcmp(mutableData.items, "Hello!") == 0)

	EXPECT_EXCEPTION(@"Detect out of range in -[itemAtIndex:]",
	    OFOutOfRangeException, [mutableData itemAtIndex: mutableData.count])

	EXPECT_EXCEPTION(@"Detect out of range in -[addItems:count:]",
	    OFOutOfRangeException,
	    [mutableData addItems: raw[0] count: SIZE_MAX])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeItemsInRange:]",
	    OFOutOfRangeException,
	    [mutableData removeItemsInRange: OFMakeRange(mutableData.count, 1)])

	OFFreeMemory(raw[0]);
	OFFreeMemory(raw[1]);

	objc_autoreleasePoolPop(pool);
}
@end
