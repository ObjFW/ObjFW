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

@interface OFMessagePackTests: OTTestCase
@end

@implementation OFMessagePackTests
- (void)testMessagePackRepresentationForNumber
{
	OTAssertEqualObjects([[OFNumber numberWithChar: -30]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xE2" count: 1]);

	OTAssertEqualObjects([[OFNumber numberWithChar: -33]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD0\xDF" count: 2]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedChar: 127]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\x7F" count: 1]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedChar: 128]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCC\x80" count: 2]);

	OTAssertEqualObjects([[OFNumber numberWithShort: -129]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD1\xFF\x7F" count: 3]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedShort: 256]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCD\x01\x00" count: 3]);

	OTAssertEqualObjects([[OFNumber numberWithLong: -32769]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD2\xFF\xFF\x7F\xFF" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedLong: 65536]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCE\x00\x01\x00\x00" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithLongLong: -2147483649]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xD3\xFF\xFF\xFF\xFF\x7F\xFF\xFF\xFF"
			    count: 9]);

	OTAssertEqualObjects([[OFNumber numberWithUnsignedLongLong: 4294967296]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCF\x00\x00\x00\x01\x00\x00\x00\x00"
			    count: 9]);

	OTAssertEqualObjects([[OFNumber numberWithFloat: 1.25f]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCA\x3F\xA0\x00\x00" count: 5]);

	OTAssertEqualObjects([[OFNumber numberWithDouble: 1.25]
	    messagePackRepresentation],
	    [OFData dataWithItems: "\xCB\x3F\xF4\x00\x00\x00\x00\x00\x00"
			    count: 9]);
}

- (void)testObjectByParsingMessagePackForNumber
{
	OTAssertEqualObjects([[OFData dataWithItems: "\xE2" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithChar: -30]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xD0\xDF" count: 2]
	    objectByParsingMessagePack],
	    [OFNumber numberWithChar: -33]);

	OTAssertEqualObjects([[OFData dataWithItems: "\x7F" count: 1]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedChar: 127]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xCC\x80" count: 2]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedChar: 128]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xD1\xFF\x7F" count: 3]
	    objectByParsingMessagePack],
	    [OFNumber numberWithShort: -129]);

	OTAssertEqualObjects([[OFData dataWithItems: "\xCD\x01\x00" count: 3]
	    objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedShort: 256]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD2\xFF\xFF\x7F\xFF"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithLong: -32769]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCE\x00\x01\x00\x00"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedLong: 65536]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xD3\xFF\xFF\xFF\xFF\x7F\xFF\xFF\xFF"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithLongLong: -2147483649]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCF\x00\x00\x00\x01\x00\x00\x00\x00"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithUnsignedLongLong: 4294967296]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCA\x3F\xA0\x00\x00"
			     count: 5] objectByParsingMessagePack],
	    [OFNumber numberWithFloat: 1.25f]);

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\xCB\x3F\xF4\x00\x00\x00\x00\x00\x00"
			     count: 9] objectByParsingMessagePack],
	    [OFNumber numberWithDouble: 1.25]);
}
@end
