/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

static OFString *module = @"OFData";
const char *str = "Hello!";

@implementation TestsAppDelegate (OFDataTests)
- (void)dataTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *mutable;
	OFData *immutable;
	void *raw[2];
	OFRange range;

	TEST(@"+[dataWithItemSize:]",
	    (mutable = [OFMutableData dataWithItemSize: 4096]))

	raw[0] = of_alloc(1, 4096);
	raw[1] = of_alloc(1, 4096);
	memset(raw[0], 0xFF, 4096);
	memset(raw[1], 0x42, 4096);

	TEST(@"-[addItem:]", R([mutable addItem: raw[0]]) &&
	    R([mutable addItem: raw[1]]))

	TEST(@"-[itemAtIndex:]",
	    memcmp([mutable itemAtIndex: 0], raw[0], 4096) == 0 &&
	    memcmp([mutable itemAtIndex: 1], raw[1], 4096) == 0)

	TEST(@"-[lastItem]", memcmp(mutable.lastItem, raw[1], 4096) == 0)

	TEST(@"-[count]", mutable.count == 2)

	TEST(@"-[isEqual:]",
	    (immutable = [OFData dataWithItems: mutable.items
					 count: mutable.count
				      itemSize: mutable.itemSize]) &&
	    [immutable isEqual: mutable] &&
	    R([mutable removeLastItem]) && ![mutable isEqual: immutable])

	TEST(@"-[mutableCopy]",
	    (mutable = [[immutable mutableCopy] autorelease]) &&
	    [mutable isEqual: immutable])

	TEST(@"-[compare]", [mutable compare: immutable] == 0 &&
	    R([mutable removeLastItem]) &&
	    [immutable compare: mutable] == OFOrderedDescending &&
	    [mutable compare: immutable] == OFOrderedAscending &&
	    [[OFData dataWithItems: "aa" count: 2] compare:
	    [OFData dataWithItems: "z" count: 1]] == OFOrderedAscending)

	TEST(@"-[hash]", immutable.hash == 0x634A529F)

	mutable = [OFMutableData dataWithItems: "abcdef" count: 6];

	TEST(@"-[removeLastItem]", R([mutable removeLastItem]) &&
	    mutable.count == 5 && memcmp(mutable.items, "abcde", 5) == 0)

	TEST(@"-[removeItemsInRange:]",
	    R([mutable removeItemsInRange: OFMakeRange(1, 2)]) &&
	    mutable.count == 3 && memcmp(mutable.items, "ade", 3) == 0)

	TEST(@"-[insertItems:atIndex:count:]",
	    R([mutable insertItems: "bc" atIndex: 1 count: 2]) &&
	    mutable.count == 5 && memcmp(mutable.items, "abcde", 5) == 0)

	immutable = [OFData dataWithItems: "aaabaccdacaabb"
				    count: 7
				 itemSize: 2];

	range = [immutable rangeOfData: [OFData dataWithItems: "aa"
							count: 1
						     itemSize: 2]
			       options: 0
				 range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #1",
	    range.location == 0 && range.length == 1)

	range = [immutable rangeOfData: [OFData dataWithItems: "aa"
							count: 1
						     itemSize: 2]
			       options: OFDataSearchBackwards
				 range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #2",
	    range.location == 5 && range.length == 1)

	range = [immutable rangeOfData: [OFData dataWithItems: "ac"
							count: 1
						     itemSize: 2]
			       options: 0
				 range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #3",
	    range.location == 2 && range.length == 1)

	range = [immutable rangeOfData: [OFData dataWithItems: "aabb"
							count: 2
						     itemSize: 2]
			       options: 0
				 range: OFMakeRange(0, 7)];
	TEST(@"-[rangeOfData:options:range:] #4",
	    range.location == 5 && range.length == 2)

	TEST(@"-[rangeOfData:options:range:] #5",
	    R(range = [immutable rangeOfData: [OFData dataWithItems: "aa"
							      count: 1
							   itemSize: 2]
				     options: 0
				       range: OFMakeRange(1, 6)]) &&
	    range.location == 5 && range.length == 1)

	range = [immutable rangeOfData: [OFData dataWithItems: "aa"
							count: 1
						     itemSize: 2]
			       options: OFDataSearchBackwards
				 range: OFMakeRange(0, 5)];
	TEST(@"-[rangeOfData:options:range:] #6",
	    range.location == 0 && range.length == 1)

	EXPECT_EXCEPTION(
	    @"-[rangeOfData:options:range:] failing on different itemSize",
	    OFInvalidArgumentException,
	    [immutable rangeOfData: [OFData dataWithItems: "aaa"
						    count: 1
						 itemSize: 3]
			   options: 0
			     range: OFMakeRange(0, 1)])

	EXPECT_EXCEPTION(
	    @"-[rangeOfData:options:range:] failing on out of range",
	    OFOutOfRangeException,
	    [immutable rangeOfData: [OFData dataWithItems: ""
						    count: 0
						 itemSize: 2]
			   options: 0
			     range: OFMakeRange(8, 1)])

	TEST(@"-[subdataWithRange:]",
	    [[immutable subdataWithRange: OFMakeRange(2, 4)]
	    isEqual: [OFData dataWithItems: "accdacaa"
				     count: 4
				  itemSize: 2]] &&
	    [[mutable subdataWithRange: OFMakeRange(2, 3)]
	    isEqual: [OFData dataWithItems: "cde"
				     count: 3]])

	EXPECT_EXCEPTION(@"-[subdataWithRange:] failing on out of range #1",
	    OFOutOfRangeException,
	    [immutable subdataWithRange: OFMakeRange(7, 1)])

	EXPECT_EXCEPTION(@"-[subdataWithRange:] failing on out of range #2",
	    OFOutOfRangeException,
	    [mutable subdataWithRange: OFMakeRange(6, 1)])

	TEST(@"-[stringByMD5Hashing]", [mutable.stringByMD5Hashing
	    isEqual: @"ab56b4d92b40713acc5af89985d4b786"])

	TEST(@"-[stringByRIPEMD160Hashing]", [mutable.stringByRIPEMD160Hashing
	    isEqual: @"973398b6e6c6cfa6b5e6a5173f195ce3274bf828"])

	TEST(@"-[stringBySHA1Hashing]", [mutable.stringBySHA1Hashing
	    isEqual: @"03de6c570bfe24bfc328ccd7ca46b76eadaf4334"])

	TEST(@"-[stringBySHA224Hashing]", [mutable.stringBySHA224Hashing
	    isEqual: @"bdd03d560993e675516ba5a50638b6531ac2ac3d5847c61916cfced6"
	    ])

	TEST(@"-[stringBySHA256Hashing]", [mutable.stringBySHA256Hashing
	    isEqual: @"36bbe50ed96841d10443bcb670d6554f0a34b761be67ec9c4a8ad2c0"
		     @"c44ca42c"])

	TEST(@"-[stringBySHA384Hashing]", [mutable.stringBySHA384Hashing
	    isEqual: @"4c525cbeac729eaf4b4665815bc5db0c84fe6300068a727cf74e2813"
		     @"521565abc0ec57a37ee4d8be89d097c0d2ad52f0"])

	TEST(@"-[stringBySHA512Hashing]", [mutable.stringBySHA512Hashing
	    isEqual: @"878ae65a92e86cac011a570d4c30a7eaec442b85ce8eca0c2952b5e3"
		     @"cc0628c2e79d889ad4d5c7c626986d452dd86374b6ffaa7cd8b67665"
		     @"bef2289a5c70b0a1"])

	TEST(@"-[stringByBase64Encoding]",
	    [mutable.stringByBase64Encoding isEqual: @"YWJjZGU="])

	TEST(@"+[dataWithBase64EncodedString:]",
	    memcmp([[OFData dataWithBase64EncodedString: @"YWJjZGU="]
	    items], "abcde", 5) == 0)

	TEST(@"Building strings",
	    (mutable = [OFMutableData dataWithItems: str count: 6]) &&
	    R([mutable addItem: ""]) &&
	    strcmp(mutable.items, str) == 0)

	EXPECT_EXCEPTION(@"Detect out of range in -[itemAtIndex:]",
	    OFOutOfRangeException, [mutable itemAtIndex: mutable.count])

	EXPECT_EXCEPTION(@"Detect out of range in -[addItems:count:]",
	    OFOutOfRangeException, [mutable addItems: raw[0] count: SIZE_MAX])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeItemsInRange:]",
	    OFOutOfRangeException,
	    [mutable removeItemsInRange: OFMakeRange(mutable.count, 1)])

	free(raw[0]);
	free(raw[1]);

	objc_autoreleasePoolPop(pool);
}
@end
