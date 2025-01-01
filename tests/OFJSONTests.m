/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

@interface OFJSONTests: OTTestCase
{
	OFDictionary *_dictionary;
}
@end

static OFString *string = @"{\"f\\0o\x6f\"\t:'b\\na\\r', \"x\":/*foo*/ [.5\r,"
    @"0xF,null//bar\n,\"f\\x6F\\u0000o\",false]}";

@implementation OFJSONTests
- (void)setUp
{
	[super setUp];

	_dictionary = [[OTOrderedDictionary alloc] initWithKeysAndObjects:
	    @"f\0oo", @"b\na\r",
	    @"x", [OFArray arrayWithObjects:
		[OFNumber numberWithFloat: .5f],
		[OFNumber numberWithInt: 0xF],
		[OFNull null],
		@"fo\0o",
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
	    @"{\"f\\u0000oo\":\"b\\na\\r\",\"x\":[0.5,15,null,\"fo\\u0000o\","
	    @"false]}");
}

- (void)testSortedJSONRepresentation
{
	OTAssertEqualObjects(
	    [([OFDictionary dictionaryWithKeysAndObjects:
	    @"b", @"a", @"a", @"b", nil])
	    JSONRepresentationWithOptions: OFJSONRepresentationOptionSorted],
	    @"{\"a\":\"b\",\"b\":\"a\"}");
}

- (void)testPrettyJSONRepresentation
{
	OTAssertEqualObjects([_dictionary JSONRepresentationWithOptions:
	    OFJSONRepresentationOptionPretty],
	    @"{\n\t\"f\\u0000oo\": \"b\\na\\r\",\n\t\"x\": [\n\t\t0.5,\n\t\t15,"
	    @"\n\t\tnull,\n\t\t\"fo\\u0000o\",\n\t\tfalse\n\t]\n}");
}

- (void)testJSON5Representation
{
	OTAssertEqualObjects([_dictionary JSONRepresentationWithOptions:
	    OFJSONRepresentationOptionJSON5],
	    @"{\"f\\0oo\":\"b\\\na\\r\",x:[0.5,15,null,\"fo\\0o\",false]}");
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
