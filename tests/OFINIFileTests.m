/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
	objc_release(_file);

	[super dealloc];
}

- (void)testSectionForName
{
	OTAssertNotNil([_file sectionForName: @"tests"]);
	OTAssertNotNil([_file sectionForName: @"foobar"]);
	OTAssertNotNil([_file sectionForName: @"types"]);
}

- (void)testStringValueForKey
{
	OTAssertEqualObjects(
	    [[_file sectionForName: @"tests"] stringValueForKey: @"foo"],
	    @"bar");

	OTAssertEqualObjects([[_file sectionForName: @"foobar"]
	    stringValueForKey: @"quxquxqux"],
	    @"hello\"wörld");
}

- (void)testLongLongValueForKeyDefaultValue
{
	OTAssertEqual([[_file sectionForName: @"types"]
	    longLongValueForKey: @"integer"
		   defaultValue: 2],
	    -0x20);
}

- (void)testUnsignedLongLongValueForKeyDefaultValue
{
	OTAssertEqual([[_file sectionForName: @"types"]
	    unsignedLongLongValueForKey: @"unsigned"
			   defaultValue: 2],
	    0x20);
}

- (void)testUnsignedLongLongValueThrowsForNegative
{
	OTAssertThrowsSpecific([[_file sectionForName: @"types"]
	    unsignedLongLongValueForKey: @"integer"
			   defaultValue: 2],
	    OFOutOfRangeException);
}

- (void)testBoolValueForKeyDefaultValue
{
	OTAssertTrue([[_file sectionForName: @"types"]
	    boolValueForKey: @"bool"
	       defaultValue: false]);
}

- (void)testFloatValueForKeyDefaultValue
{
	OTAssertEqual([[_file sectionForName: @"types"]
	    floatValueForKey: @"float"
		defaultValue: 1],
	    0.5f);
}

- (void)testDoubleValueForKeyDefaultValue
{
	OTAssertEqual([[_file sectionForName: @"types"]
	    doubleValueForKey: @"double"
		 defaultValue: 3],
	    0.25);
}

- (void)testArrayValueForKey
{
	OFINISection *types = [_file sectionForName: @"types"];
	OFArray *array = [OFArray arrayWithObjects: @"1", @"2", nil];

	OTAssertEqualObjects([types arrayValueForKey: @"array1"], array);
	OTAssertEqualObjects([types arrayValueForKey: @"array2"], array);
	OTAssertEqualObjects([types arrayValueForKey: @"array3"],
	    [OFArray array]);
}

- (void)testWriteToIRIEncoding
{
	OFString *expectedOutput = @"; Comment in global section\r\n"
	    @"global=yes\r\n"
	    @"\r\n"
	    @"[tests]\r\n"
	    @"foo=baz\r\n"
	    @"foobar=baz\r\n"
	    @";comment\r\n"
	    @"new=new\r\n"
	    @"\"#quoted\"=\";comment\"\r\n"
	    @"\r\n"
	    @"[foobar]\r\n"
	    @"#foobarcomment\r\n"
	    @"qux=\" asd\"\r\n"
	    @"quxquxqux=\"hello\\\"wörld\"\r\n"
	    @"qux2=\"a\\n\"\r\n"
	    @"\"asd=asd\"=foobar\r\n"
	    @"qux3=\"a\\fb\"\r\n"
	    @"\r\n"
	    @"[types]\r\n"
	    @"integer=-16\r\n"
	    @"unsigned=16\r\n"
	    @"bool=false\r\n"
	    @"float=0.25\r\n"
	    @"array1=foo\r\n"
	    @"array1=bar\r\n"
	    @"double=0.75\r\n";
	OFINISection *tests = [_file sectionForName: @"tests"];
	OFINISection *foobar = [_file sectionForName: @"foobar"];
	OFINISection *types = [_file sectionForName: @"types"];
	OFArray *array = [OFArray arrayWithObjects: @"foo", @"bar", nil];
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	OFIRI *writeIRI;
#endif

	[tests setStringValue: @"baz" forKey: @"foo"];
	[tests setStringValue: @"new" forKey: @"new"];
	[tests setStringValue: @";comment" forKey: @"#quoted"];
	[foobar setStringValue: @"a\fb" forKey: @"qux3"];
	[types setLongLongValue: -0x10 forKey: @"integer"];
	[types setUnsignedLongLongValue: 0x10 forKey: @"unsigned"];
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
