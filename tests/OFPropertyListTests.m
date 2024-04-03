/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
	OTAssertThrowsSpecific(
	    [[PLIST(@"<string/>")
	    stringByReplacingOccurrencesOfString: @"1.0"
				      withString: @"1.1"]
	    objectByParsingPropertyList],
	    OFUnsupportedVersionException);
}

- (void)testDetectInvalidFormat
{
	OTAssertThrowsSpecific(
	    [PLIST(@"<string x='b'/>") objectByParsingPropertyList],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [PLIST(@"<string xmlns='foo'/>") objectByParsingPropertyList],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [PLIST(@"<dict count='0'/>") objectByParsingPropertyList],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [PLIST(@"<dict><key/><string/><key/></dict>")
	    objectByParsingPropertyList],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [PLIST(@"<dict><key x='x'/><string/></dict>")
	    objectByParsingPropertyList],
	    OFInvalidFormatException);
}
@end
