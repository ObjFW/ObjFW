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

@interface OFDERRepresentationTests: OTTestCase
@end

@implementation OFDERRepresentationTests
- (void)testBoolean
{
	OTAssertEqualObjects(
	    [[OFASN1Boolean booleanWithBool: false] DERRepresentation],
	    [OFData dataWithItems: "\x01\x01\x00" count: 3]);

	OTAssertEqualObjects(
	    [[OFASN1Boolean booleanWithBool: true] DERRepresentation],
	    [OFData dataWithItems: "\x01\x01\xFF" count: 3]);
}

- (void)testInteger
{
	OTAssertEqualObjects(
	    [[OFASN1Integer integerWithLongLong: INT64_MIN] DERRepresentation],
	    [OFData dataWithItems: "\x02\x08\x80\x00\x00\x00\x00\x00\x00\x00"
			    count: 10]);
}

- (void)testBitString
{
	OFData *bits = [OFData dataWithItems: "\xFF\x00\xF8" count: 3];
	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBits: bits
		    bitsCount: 21] DERRepresentation],
	    [OFData dataWithItems: "\x03\x04\x03\xFF\x00\xF8" count: 6]);

	bits = [OFData dataWithItems: "abcdefäöü" count: 12];
	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBits: bits
		    bitsCount: 12 * 8] DERRepresentation],
	    [OFData dataWithItems: "\x03\x0D\x00" "abcdefäöü" count: 15]);

	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBits: [OFData data]
		    bitsCount: 0] DERRepresentation],
	    [OFData dataWithItems: "\x03\x01\x00" count: 3]);
}

- (void)testOctetString
{
	OFData *octets = [OFData dataWithItems: "\xFF\x00\xF8" count: 3];
	OTAssertEqualObjects([[OFASN1OctetString
	    octetStringWithOctets: octets] DERRepresentation],
	    [OFData dataWithItems: "\x04\x03\xFF\x00\xF8" count: 5]);

	octets = [OFData dataWithItems: "abcdefäöü" count: 12];
	OTAssertEqualObjects([[OFASN1OctetString
	    octetStringWithOctets: octets] DERRepresentation],
	    [OFData dataWithItems: "\x04\x0C" "abcdefäöü" count: 14]);

	OTAssertEqualObjects([[OFASN1OctetString
	    octetStringWithOctets: [OFData data]] DERRepresentation],
	    [OFData dataWithItems: "\x04\x00" count: 2]);
}

- (void)testNull
{
	OTAssertEqualObjects([[OFASN1Null null] DERRepresentation],
	    [OFData dataWithItems: "\x05\x00" count: 2]);
}

- (void)testEnumerated
{
	OTAssertEqualObjects([[OFASN1Enumerated
	    enumeratedWithLongLong: INT64_MIN] DERRepresentation],
	    [OFData dataWithItems: "\x0A\x08\x80\x00\x00\x00\x00\x00\x00\x00"
			    count: 10]);
}

- (void)testUTF8String
{
	OTAssertEqualObjects([[OFASN1UTF8String
	    stringWithString: @"abcdefäöü"] DERRepresentation],
	    [OFData dataWithItems: "\x0C\x0C" "abcdefäöü" count: 14]);
}

- (void)testNumericString
{
	OTAssertEqualObjects([[OFASN1NumericString
	    stringWithString: @"012 34"] DERRepresentation],
	    [OFData dataWithItems: "\x12\x06" "012 34" count: 8]);
}

- (void)testPrintableString
{
	OTAssertEqualObjects([[OFASN1PrintableString
	    stringWithString: @"abcdef"] DERRepresentation],
	    [OFData dataWithItems: "\x13\x06" "abcdef" count: 8]);
}

- (void)testIA5String
{
	OTAssertEqualObjects([[OFASN1IA5String
	    stringWithString: @"abcdef"] DERRepresentation],
	    [OFData dataWithItems: "\x16\x06" "abcdef" count: 8]);
}
@end
