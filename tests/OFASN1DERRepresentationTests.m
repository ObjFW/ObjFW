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

@interface OFASN1DERRepresentationTests: OTTestCase
@end

@implementation OFASN1DERRepresentationTests
- (void)testBitString
{
	OFData *data;

	data = [OFData dataWithItems: "\xFF\x00\xF8" count: 3];
	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBitString: data
			    length: 21] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x03\x04\x03\xFF\x00\xF8" count: 6]);

	data = [OFData dataWithItems: "abcdefäöü" count: 12];
	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBitString: data
			    length: 12 * 8] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x03\x0D\x00" "abcdefäöü" count: 15]);

	OTAssertEqualObjects([[OFASN1BitString
	    bitStringWithBitString: [OFData data]
			    length: 0] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x03\x01\x00" count: 3]);
}

- (void)testInteger
{
	OTAssertEqualObjects(
	    [[OFNumber numberWithBool: false] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x01\x01\x00" count: 3]);

	OTAssertEqualObjects(
	    [[OFNumber numberWithBool: true] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x01\x01\xFF" count: 3]);
}

- (void)testNull
{
	OTAssertEqualObjects([[OFNull null] ASN1DERRepresentation],
	    [OFData dataWithItems: "\x05\x00" count: 2]);
}
@end
