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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFPropertyListTests: OTTestCase
@end

#define PLIST(x)							\
	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"			\
	@"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "	\
	@"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"		\
	@"<plist version=\"1.0\">\n"					\
	x @"\n"								\
	@"</plist>"

@implementation OFPropertyListTests
- (void)testObjectByParsingPropertyList
{
	OFArray *array = [OFArray arrayWithObjects:
	    @"Hello",
	    [OFData dataWithItems: "World!" count: 6],
	    [OFDate dateWithTimeIntervalSince1970: 1521030896],
	    [OFNumber numberWithBool: true],
	    [OFNumber numberWithBool: false],
	    [OFNumber numberWithFloat: 12.25f],
	    [OFNumber numberWithInt: -10],
	    nil];

	OTAssertEqualObjects([PLIST(
	    @"<string>Hello</string>") objectByParsingPropertyList],
	    @"Hello");
	OTAssertEqualObjects([PLIST(
	    @"<array>"
	    @" <string>Hello</string>"
	    @" <data>V29ybGQh</data>"
	    @" <date>2018-03-14T12:34:56Z</date>"
	    @" <true/>"
	    @" <false/>"
	    @" <real>12.25</real>"
	    @" <integer>-10</integer>"
	    @"</array>") objectByParsingPropertyList],
	    array);
	OTAssertEqualObjects([PLIST(
	    @"<dict>"
	    @" <key>array</key>"
	    @" <array>"
	    @"  <string>Hello</string>"
	    @"  <data>V29ybGQh</data>"
	    @"  <date>2018-03-14T12:34:56Z</date>"
	    @"  <true/>"
	    @"  <false/>"
	    @"  <real>12.25</real>"
	    @"  <integer>-10</integer>"
	    @" </array>"
	    @" <key>foo</key>"
	    @" <string>bar</string>"
	    @"</dict>") objectByParsingPropertyList],
	    ([OFDictionary dictionaryWithKeysAndObjects:
	    @"array", array,
	    @"foo", @"bar",
	    nil]));
}

- (void)testDetectUnsupportedVersion
{
	bool caught = false;
	@try {
		[[PLIST(@"<string/>")
		    stringByReplacingOccurrencesOfString: @"1.0"
					      withString: @"1.1"]
		objectByParsingPropertyList];
	} @catch (OFUnsupportedVersionException *e) {
		caught = true;
	}
	OTAssertTrue(caught);
}

- (void)testDetectInvalidFormat
{
	bool caught;

	caught = false;
	@try {
		[PLIST(@"<string x='b'/>") objectByParsingPropertyList];
	} @catch (OFInvalidFormatException *e) {
		caught = true;
	}
	OTAssertTrue(caught);

	caught = false;
	@try {
		[PLIST(@"<string xmlns='foo'/>") objectByParsingPropertyList];
	} @catch (OFInvalidFormatException *e) {
		caught = true;
	}
	OTAssertTrue(caught);

	caught = false;
	@try {
		[PLIST(@"<dict count='0'/>") objectByParsingPropertyList];
	} @catch (OFInvalidFormatException *e) {
		caught = true;
	}
	OTAssertTrue(caught);

	caught = false;
	@try {
		[PLIST(@"<dict><key/><string/><key/></dict>")
		    objectByParsingPropertyList];
	} @catch (OFInvalidFormatException *e) {
		caught = true;
	}
	OTAssertTrue(caught);

	caught = false;
	@try {
		[PLIST(@"<dict><key x='x'/><string/></dict>")
		    objectByParsingPropertyList];
	} @catch (OFInvalidFormatException *e) {
		caught = true;
	}
	OTAssertTrue(caught);
}
@end
