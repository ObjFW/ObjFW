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

@interface OFJSONTests: OTTestCase
{
	OFDictionary *_dictionary;
}
@end

static OFString *string = @"{\"foo\"\t:'b\\na\\r', \"x\":/*foo*/ [.5\r,0xF,"
    @"null//bar\n,\"foo\",false]}";

@implementation OFJSONTests
- (void)setUp
{
	[super setUp];

	_dictionary = [[OTOrderedDictionary alloc] initWithKeysAndObjects:
	    @"foo", @"b\na\r",
	    @"x", [OFArray arrayWithObjects:
		[OFNumber numberWithFloat: .5f],
		[OFNumber numberWithInt: 0xF],
		[OFNull null],
		@"foo",
		[OFNumber numberWithBool: false],
		nil],
	    nil];
}

- (void)dealloc
{
	[_dictionary release];

	[super dealloc];
}

- (void)testObjectByParsingJSON
{
	OTAssertEqualObjects(string.objectByParsingJSON, _dictionary);
}

- (void)testJSONRepresentation
{
	OTAssert(_dictionary.JSONRepresentation,
	    @"{\"foo\":\"b\\na\\r\",\"x\":[0.5,15,null,\"foo\",false]}");
}

- (void)testPrettyJSONRepresentation
{
	OTAssertEqualObjects([_dictionary JSONRepresentationWithOptions:
	    OFJSONRepresentationOptionPretty],
	    @"{\n\t\"foo\": \"b\\na\\r\",\n\t\"x\": [\n\t\t0.5,\n\t\t15,"
	    @"\n\t\tnull,\n\t\t\"foo\",\n\t\tfalse\n\t]\n}");
}

- (void)testJSON5Representation
{
	OTAssertEqualObjects([_dictionary JSONRepresentationWithOptions:
	    OFJSONRepresentationOptionJSON5],
	    @"{foo:\"b\\\na\\r\",x:[0.5,15,null,\"foo\",false]}");
}

- (void)testObjectByParsingJSONFailsWithInvalidJSON
{
	OTAssertThrowsSpecific([@"{" objectByParsingJSON],
	    OFInvalidJSONException);

	OTAssertThrowsSpecific([@"]" objectByParsingJSON],
	    OFInvalidJSONException);

	OTAssertThrowsSpecific([@"bar" objectByParsingJSON],
	    OFInvalidJSONException);

	OTAssertThrowsSpecific([@"[\"a\" \"b\"]" objectByParsingJSON],
	    OFInvalidJSONException);
}

- (void)testObjectByParsingJSONWithDeepNesting
{
	OTAssertEqualObjects(
	    @"[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[{}]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]"
	    .objectByParsingJSON,
	    [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject: [OFArray arrayWithObject:
	    [OFArray arrayWithObject:
	    [OFDictionary dictionary]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]);
}

- (void)testObjectByParsingJSONFailsWithTooDeepNesting
{
	OTAssertThrowsSpecific(
	    [@"[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[{}]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]"
	    objectByParsingJSON],
	    OFInvalidJSONException);
}
@end
