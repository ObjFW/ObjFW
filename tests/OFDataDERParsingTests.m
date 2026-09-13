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

@interface OFDataDERParsingTests: OTTestCase
@end

@implementation OFDataDERParsingTests
- (void)testBoolean
{
	OTAssertFalse(
	    [[[OFData dataWithItems: "\x01\x01\x00"
			      count: 3] objectByParsingDER] boolValue]);

	OTAssertTrue(
	    [[[OFData dataWithItems: "\x01\x01\xFF"
			      count: 3] objectByParsingDER] boolValue]);
}

- (void)testInvalidBooleanFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x01\x01"
			     count: 3] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x02\x00\x00"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x00"
			     count: 2] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testTruncatedBooleanFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testInteger
{
	OTAssertEqual([[[OFData dataWithItems: "\x02\x01\x00" count: 3]
	    objectByParsingDER] int64Value], 0);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x01\x01" count: 3]
	    objectByParsingDER] int64Value], 1);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x02\x01\x04" count: 4]
	    objectByParsingDER] int64Value], 260);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x01\xFF" count: 3]
	    objectByParsingDER] int64Value], -1);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x03\xFF\x00\x00" count: 5]
	    objectByParsingDER] int64Value], -65536);

	OTAssertEqual(
	    [[[OFData dataWithItems: "\x02\x08\x80\x00\x00\x00\x00\x00\x00\x00"
			      count: 10] objectByParsingDER] int64Value],
	    LLONG_MIN);
}

- (void)testInvalidIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x00"
			     count: 2] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00\x00"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00\x7F"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\xFF\x80"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x09"
				    "\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00"
			     count: 3] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testBitString
{
	OFASN1BitString *bitString;

	bitString = [[OFData dataWithItems: "\x03\x01\x00"
				     count: 3] objectByParsingDER];
	OTAssertEqualObjects(bitString.dataValue, [OFData data]);
	OTAssertEqual(bitString.bitLength, 0);

	bitString = [[OFData dataWithItems: "\x03\x0D\x01Hello World\x80"
				     count: 15] objectByParsingDER];
	OTAssertEqualObjects(bitString.dataValue,
	    [OFData dataWithItems: "Hello World\x80" count: 12]);
	OTAssertEqual(bitString.bitLength, 95);

	bitString = [[OFData dataWithItems: "\x03\x81\x80\x00xxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxx"
				     count: 131] objectByParsingDER];
	OTAssertEqualObjects(bitString.dataValue,
	    [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			    count: 127]);
	OTAssertEqual(bitString.bitLength, 127 * 8);
}

- (void)testInvalidBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x00"
			     count: 2] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x01\x01"
			     count: 3] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testOctetString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x04\x0CHello World!"
		    count: 14] objectByParsingDER] dataValue],
	    [OFData dataWithItems: "Hello World!" count: 12]);

	OTAssertEqualObjects(
	    [[[OFData dataWithItems: "\x04\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxx"
			      count: 131] objectByParsingDER] dataValue],
	    [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			    count: 128]);
}

- (void)testOutOfRangeOctetStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x04\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedOctetStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x04\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testNull
{
	OTAssertEqualObjects([[OFData dataWithItems: "\x05\x00" count: 2]
	    objectByParsingDER], [OFASN1Null null]);
}

- (void)testInvalidNullFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x05\x01\x00"
			     count: 3] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testObjectIdentifier
{
	OFArray *array;

	array = [[[OFData dataWithItems: "\x06\x01\x27" count: 3]
	    objectByParsingDER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 0);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 39);

	array = [[[OFData dataWithItems: "\x06\x01\x4F" count: 3]
	    objectByParsingDER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 1);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 39);

	array = [[[OFData dataWithItems: "\x06\x02\x88\x37" count: 4]
	    objectByParsingDER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 2);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 999);

	array = [[[OFData
	    dataWithItems: "\x06\x09\x2A\x86\x48\x86\xF7\x0D\x01\x01\x0B"
		    count: 11] objectByParsingDER] subidentifiers];
	OTAssertEqual(array.count, 7);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 1);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 2);
	OTAssertEqual([[array objectAtIndex: 2] unsignedLongLongValue], 840);
	OTAssertEqual([[array objectAtIndex: 3] unsignedLongLongValue], 113549);
	OTAssertEqual([[array objectAtIndex: 4] unsignedLongLongValue], 1);
	OTAssertEqual([[array objectAtIndex: 5] unsignedLongLongValue], 1);
	OTAssertEqual([[array objectAtIndex: 6] unsignedLongLongValue], 11);
}

- (void)testInvalidObjectIdentifierFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x01\x81"
			     count: 3] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x02\x80\x01"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeObjectIdentifier
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x0A\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
				    "\xFF\x7F"
			     count: 12] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedObjectIdentifierFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x02\x00"
			     count: 3] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testEnumerated
{
	OTAssertEqual([[[OFData dataWithItems: "\x0A\x01\x00" count: 3]
	    objectByParsingDER] int64Value], 0);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x01\x01" count: 3]
	    objectByParsingDER] int64Value], 1);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x02\x01\x04" count: 4]
	    objectByParsingDER] int64Value], 260);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x01\xFF" count: 3]
	    objectByParsingDER] int64Value], -1);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x03\xFF\x00\x00" count: 5]
	    objectByParsingDER] int64Value], -65536);

	OTAssertEqual(
	    [[[OFData dataWithItems: "\x0A\x08\x80\x00\x00\x00\x00\x00\x00\x00"
			      count: 10] objectByParsingDER] int64Value],
	    LLONG_MIN);
}

- (void)testInvalidEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x00"
			     count: 2] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00\x00"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00\x7F"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\xFF\x80"
			     count: 4] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x09"
				    "\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00"
			     count: 3] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testUTF8String
{
	OTAssertEqualObjects(
	    [[[OFData dataWithItems: "\x0C\x0EHällo Wörld!"
			      count: 16] objectByParsingDER] stringValue],
	    @"Hällo Wörld!");

	OTAssertEqualObjects(
	    [[[OFData dataWithItems: "\x0C\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxx"
			     count: 131] objectByParsingDER] stringValue],
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
}

- (void)testOutOfRangeUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x83\x01\x01"
			     count: 4] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testInvalidUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x81\x7F"
			     count: 3] objectByParsingDER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x82\x00\x80xxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxx"
			     count: 132] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testSequence
{
	OFArray *array;

	array = [[OFData dataWithItems: "\x30\x00"
				 count: 2] objectByParsingDER];
	OTAssertTrue([array isKindOfClass: [OFArray class]]);
	OTAssertEqual(array.count, 0);

	array = [[OFData dataWithItems: "\x30\x09\x02\x01\x7B\x0C\x04Test"
				 count: 11] objectByParsingDER];
	OTAssertTrue([array isKindOfClass: [OFArray class]]);
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] int64Value], 123);
	OTAssertEqualObjects([array objectAtIndex: 1],
	    [OFASN1UTF8String stringWithString: @"Test"]);
}

- (void)testTruncatedSequenceFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x30\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x30\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testSet
{
	OFSet *set;

	set = [[OFData dataWithItems: "\x31\x00"
			       count: 2] objectByParsingDER];
	OTAssertTrue([set isKindOfClass: [OFSet class]]);
	OTAssertEqual(set.count, 0);

	set = [[OFData dataWithItems: "\x31\x09\x02\x01\x7B\x0C\x04Test"
			       count: 11] objectByParsingDER];
	OTAssertTrue([set isKindOfClass: [OFSet class]]);
	OTAssertEqual(set.count, 2);

	OTAssertEqualObjects(set,
	    ([OFSet setWithObjects: [OFASN1Integer integerWithInt64: 123],
	    [OFASN1UTF8String stringWithString: @"Test"], nil]));
}

- (void)testInvalidSetFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x06\x02\x01\x02\x02\x01\x01"
			     count: 8] objectByParsingDER],
	    OFInvalidFormatException);
}

- (void)testTruncatedSetFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testNumericString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x12\x0B" "12345 67890"
		    count: 13] objectByParsingDER] stringValue],
	    @"12345 67890");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x12\x81\x80" "000000000000000000000000000000000000"
			   "000000000000000000000000000000000000000000000000000"
			   "00000000000000000000000000000000000000000"
		    count: 131] objectByParsingDER] stringValue],
	    @"00000000000000000000000000000000000000000000000000000000000000000"
	    @"000000000000000000000000000000000000000000000000000000000000000");
}

- (void)testInvalidNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x02."
			     count: 4] objectByParsingDER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangeNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testPrintableString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x13\x0CHello World."
		    count: 14] objectByParsingDER] stringValue],
	    @"Hello World.");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x13\x81\x80 '()+,-./:=?abcdefghijklmnopqrstuvwxyzA"
			   "BCDEFGHIJKLMNOPQRSTUVWXYZ '()+,-./:=?abcdefghijklmn"
			   "opqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		    count: 131] objectByParsingDER] stringValue],
	    @" '()+,-./:=?abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "
	    @"'()+,-./:=?abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
}

- (void)testInvalidPrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x02;"
			     count: 4] objectByParsingDER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangePrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedPrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}

- (void)testIA5String
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x16\x0CHello World!"
		    count: 14] objectByParsingDER] stringValue],
	    @"Hello World!");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x16\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		    count: 131] objectByParsingDER] stringValue],
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
}

- (void)testInvalidIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x02ä"
			     count: 4] objectByParsingDER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangeIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingDER],
	    OFOutOfRangeException);
}

- (void)testTruncatedIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x01"
			     count: 2] objectByParsingDER],
	    OFTruncatedDataException);
}
@end
