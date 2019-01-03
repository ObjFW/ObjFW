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

#import "OFString.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

#import "TestsAppDelegate.h"

#define PLIST(x)							\
	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"			\
	@"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "	\
	@"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"		\
	@"<plist version=\"1.0\">\n"					\
	x @"\n"								\
	@"</plist>"

static OFString *module = @"OFPropertyList";
static OFString *PLIST1 = PLIST(@"<string>Hello</string>");
static OFString *PLIST2 = PLIST(
    @"<array>"
    @" <string>Hello</string>"
    @" <data>V29ybGQh</data>"
    @" <date>2018-03-14T12:34:56Z</date>"
    @" <true/>"
    @" <false/>"
    @" <real>12.25</real>"
    @" <integer>-10</integer>"
    @"</array>");
static OFString *PLIST3 = PLIST(
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
    @"</dict>");

@implementation TestsAppDelegate (OFPLISTParser)
- (void)propertyListTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *array = [OFArray arrayWithObjects:
	    @"Hello",
	    [OFData dataWithItems: "World!"
			    count: 6],
	    [OFDate dateWithTimeIntervalSince1970: 1521030896],
	    [OFNumber numberWithBool: true],
	    [OFNumber numberWithBool: false],
	    [OFNumber numberWithFloat: 12.25],
	    [OFNumber numberWithInt: -10],
	    nil];

	TEST(@"-[propertyListValue:] #1",
	    [[PLIST1 propertyListValue] isEqual: @"Hello"])

	TEST(@"-[propertyListValue:] #2",
	    [[PLIST2 propertyListValue] isEqual: array])

	TEST(@"-[propertyListValue:] #3",
	    [[PLIST3 propertyListValue] isEqual:
	    [OFDictionary dictionaryWithKeysAndObjects:
	    @"array", array,
	    @"foo", @"bar",
	    nil]])

	EXPECT_EXCEPTION(@"-[propertyListValue] detecting unsupported version",
	    OFUnsupportedVersionException,
	    [[PLIST(@"<string/>") stringByReplacingOccurrencesOfString: @"1.0"
							    withString: @"1.1"]
	    propertyListValue])

	EXPECT_EXCEPTION(
	    @"-[propertyListValue] detecting invalid format #1",
	    OFInvalidFormatException,
	    [PLIST(@"<string x='b'/>") propertyListValue])

	EXPECT_EXCEPTION(
	    @"-[propertyListValue] detecting invalid format #2",
	    OFInvalidFormatException,
	    [PLIST(@"<string xmlns='foo'/>") propertyListValue])

	EXPECT_EXCEPTION(
	    @"-[propertyListValue] detecting invalid format #3",
	    OFInvalidFormatException,
	    [PLIST(@"<dict count='0'/>") propertyListValue])

	EXPECT_EXCEPTION(
	    @"-[propertyListValue] detecting invalid format #4",
	    OFInvalidFormatException,
	    [PLIST(@"<dict><key/><string/><key/></dict>") propertyListValue])

	EXPECT_EXCEPTION(
	    @"-[propertyListValue] detecting invalid format #5",
	    OFInvalidFormatException,
	    [PLIST(@"<dict><key x='x'/><string/></dict>") propertyListValue])

	[pool drain];
}
@end
