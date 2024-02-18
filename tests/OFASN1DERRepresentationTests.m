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
