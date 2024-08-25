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

#import "OFEmbeddedIRIHandler.h"

@interface OFINIFileTests: OTTestCase
{
	OFINIFile *_file;
}
@end

@implementation OFINIFileTests
- (void)setUp
{
	OFIRI *IRI;

	[super setUp];

	IRI = [OFIRI IRIWithString: @"embedded:testfile.ini"];
	_file = [[OFINIFile alloc] initWithIRI: IRI
				      encoding: OFStringEncodingISO8859_1];
}

- (void)dealloc
{
	[_file release];

	[super dealloc];
}

- (void)testCategoryForName
{
	OTAssertNotNil([_file categoryForName: @"tests"]);
	OTAssertNotNil([_file categoryForName: @"foobar"]);
	OTAssertNotNil([_file categoryForName: @"types"]);
}

- (void)testStringValueForKey
{
	OTAssertEqualObjects(
	    [[_file categoryForName: @"tests"] stringValueForKey: @"foo"],
	    @"bar");

	OTAssertEqualObjects([[_file categoryForName: @"foobar"]
	    stringValueForKey: @"quxquxqux"],
	    @"hello\"wörld");
}

- (void)testLongLongValueForKeyDefaultValue
{
	OTAssertEqual([[_file categoryForName: @"types"]
	    longLongValueForKey: @"integer"
		   defaultValue: 2],
	    0x20);
}

- (void)testBoolValueForKeyDefaultValue
{
	OTAssertTrue([[_file categoryForName: @"types"]
	    boolValueForKey: @"bool"
	       defaultValue: false]);
}

- (void)testFloatValueForKeyDefaultValue
{
	OTAssertEqual([[_file categoryForName: @"types"]
	    floatValueForKey: @"float"
		defaultValue: 1],
	    0.5f);
}

- (void)testDoubleValueForKeyDefaultValue
{
	OTAssertEqual([[_file categoryForName: @"types"]
	    doubleValueForKey: @"double"
		 defaultValue: 3],
	    0.25);
}

- (void)testArrayValueForKey
{
	OFINICategory *types = [_file categoryForName: @"types"];
	OFArray *array = [OFArray arrayWithObjects: @"1", @"2", nil];

	OTAssertEqualObjects([types arrayValueForKey: @"array1"], array);
	OTAssertEqualObjects([types arrayValueForKey: @"array2"], array);
	OTAssertEqualObjects([types arrayValueForKey: @"array3"],
	    [OFArray array]);
}

- (void)testWriteToIRIEncoding
{
	OFString *expectedOutput = @"; Comment in global category\r\n"
	    @"global=yes\r\n"
	    @"\r\n"
	    @"[tests]\r\n"
	    @"foo=baz\r\n"
	    @"foobar=baz\r\n"
	    @";comment\r\n"
	    @"new=new\r\n"
	    @"\r\n"
	    @"[foobar]\r\n"
	    @"#foobarcomment\r\n"
	    @"qux=\" asd\"\r\n"
	    @"quxquxqux=\"hello\\\"wörld\"\r\n"
	    @"qux2=\"a\\f\"\r\n"
	    @"\"asd=asd\"=foobar\r\n"
	    @"qux3=a\fb\r\n"
	    @"\r\n"
	    @"[types]\r\n"
	    @"integer=16\r\n"
	    @"bool=false\r\n"
	    @"float=0.25\r\n"
	    @"array1=foo\r\n"
	    @"array1=bar\r\n"
	    @"double=0.75\r\n";
	OFINICategory *tests = [_file categoryForName: @"tests"];
	OFINICategory *foobar = [_file categoryForName: @"foobar"];
	OFINICategory *types = [_file categoryForName: @"types"];
	OFArray *array = [OFArray arrayWithObjects: @"foo", @"bar", nil];
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	OFIRI *writeIRI;
#endif

	[tests setStringValue: @"baz" forKey: @"foo"];
	[tests setStringValue: @"new" forKey: @"new"];
	[foobar setStringValue: @"a\fb" forKey: @"qux3"];
	[types setLongLongValue: 0x10 forKey: @"integer"];
	[types setBoolValue: false forKey: @"bool"];
	[types setFloatValue: 0.25f forKey: @"float"];
	[types setDoubleValue: 0.75 forKey: @"double"];
	[types setArrayValue: array forKey: @"array1"];

	[foobar removeValueForKey: @"quxqux "];
	[types removeValueForKey: @"array2"];

	/* FIXME: Find a way to write files on Nintendo DS */
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	writeIRI = [OFSystemInfo temporaryDirectoryIRI];
	if (writeIRI == nil)
		writeIRI = [[OFFileManager defaultManager] currentDirectoryIRI];
	writeIRI = [writeIRI IRIByAppendingPathComponent: @"objfw-tests.ini"
					     isDirectory: false];

	[_file writeToIRI: writeIRI
		 encoding: OFStringEncodingISO8859_1];

	@try {
		OTAssertEqualObjects([OFString
		    stringWithContentsOfIRI: writeIRI
				   encoding: OFStringEncodingISO8859_1],
		    expectedOutput);
	} @finally {
		[[OFFileManager defaultManager] removeItemAtIRI: writeIRI];
	}
#else
	(void)expectedOutput;
#endif
}
@end
