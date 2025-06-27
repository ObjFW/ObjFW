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

@interface OFASN1DERParsingTests: OTTestCase
@end

@implementation OFASN1DERParsingTests
- (void)testBoolean
{
	OTAssertFalse(
	    [[[OFData dataWithItems: "\x01\x01\x00"
			      count: 3] objectByParsingASN1DER] boolValue]);

	OTAssertTrue(
	    [[[OFData dataWithItems: "\x01\x01\xFF"
			      count: 3] objectByParsingASN1DER] boolValue]);
}

- (void)testInvalidBooleanFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x01\x01"
			     count: 3] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x02\x00\x00"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x00"
			     count: 2] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testTruncatedBooleanFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x01\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testInteger
{
	OTAssertEqual([[[OFData dataWithItems: "\x02\x00" count: 2]
	    objectByParsingASN1DER] longLongValue], 0);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x01\x01" count: 3]
	    objectByParsingASN1DER] longLongValue], 1);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x02\x01\x04" count: 4]
	    objectByParsingASN1DER] longLongValue], 260);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x01\xFF" count: 3]
	    objectByParsingASN1DER] longLongValue], -1);

	OTAssertEqual([[[OFData dataWithItems: "\x02\x03\xFF\x00\x00" count: 5]
	    objectByParsingASN1DER] longLongValue], -65536);

	OTAssertEqual((unsigned long long)[[[OFData
	    dataWithItems: "\x02\x09\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
		    count: 11] objectByParsingASN1DER] longLongValue],
	    ULLONG_MAX);
}

- (void)testInvalidIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00\x00"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00\x7F"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\xFF\x80"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x09\x01"
				    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedIntegerFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x02\x02\x00"
			     count: 3] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testBitString
{
	OFASN1BitString *bitString;

	bitString = [[OFData dataWithItems: "\x03\x01\x00"
				     count: 3] objectByParsingASN1DER];
	OTAssertEqualObjects(bitString.bitStringValue, [OFData data]);
	OTAssertEqual(bitString.bitStringLength, 0);

	bitString = [[OFData dataWithItems: "\x03\x0D\x01Hello World\x80"
				     count: 15] objectByParsingASN1DER];
	OTAssertEqualObjects(bitString.bitStringValue,
	    [OFData dataWithItems: "Hello World\x80" count: 12]);
	OTAssertEqual(bitString.bitStringLength, 95);

	bitString = [[OFData dataWithItems: "\x03\x81\x80\x00xxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxx"
				     count: 131] objectByParsingASN1DER];
	OTAssertEqualObjects(bitString.bitStringValue,
	    [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			    count: 127]);
	OTAssertEqual(bitString.bitStringLength, 127 * 8);
}

- (void)testInvalidBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x00"
			     count: 2] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x01\x01"
			     count: 3] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedBitStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x03\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testOctetString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x04\x0CHello World!"
		    count: 14] objectByParsingASN1DER] octetStringValue],
	    [OFData dataWithItems: "Hello World!" count: 12]);

	OTAssertEqualObjects(
	    [[[OFData dataWithItems: "\x04\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxx"
			      count: 131] objectByParsingASN1DER]
	    octetStringValue],
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
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedOctetStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x04\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testNull
{
	OTAssertEqualObjects([[OFData dataWithItems: "\x05\x00" count: 2]
	    objectByParsingASN1DER], [OFNull null]);
}

- (void)testInvalidNullFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x05\x01\x00"
			     count: 3] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testObjectIdentifier
{
	OFArray *array;

	array = [[[OFData dataWithItems: "\x06\x01\x27" count: 3]
	    objectByParsingASN1DER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 0);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 39);

	array = [[[OFData dataWithItems: "\x06\x01\x4F" count: 3]
	    objectByParsingASN1DER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 1);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 39);

	array = [[[OFData dataWithItems: "\x06\x02\x88\x37" count: 4]
	    objectByParsingASN1DER] subidentifiers];
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] unsignedLongLongValue], 2);
	OTAssertEqual([[array objectAtIndex: 1] unsignedLongLongValue], 999);

	array = [[[OFData
	    dataWithItems: "\x06\x09\x2A\x86\x48\x86\xF7\x0D\x01\x01\x0B"
		    count: 11] objectByParsingASN1DER] subidentifiers];
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
			     count: 3] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x02\x80\x01"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeObjectIdentifier
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x0A\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
				    "\xFF\x7F"
			     count: 12] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedObjectIdentifierFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x06\x02\x00"
			     count: 3] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testEnumerated
{
	OTAssertEqual([[[OFData dataWithItems: "\x0A\x00" count: 2]
	    objectByParsingASN1DER] longLongValue], 0);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x01\x01" count: 3]
	    objectByParsingASN1DER] longLongValue], 1);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x02\x01\x04" count: 4]
	    objectByParsingASN1DER] longLongValue], 260);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x01\xFF" count: 3]
	    objectByParsingASN1DER] longLongValue], -1);

	OTAssertEqual([[[OFData dataWithItems: "\x0A\x03\xFF\x00\x00" count: 5]
	    objectByParsingASN1DER] longLongValue], -65536);

	OTAssertEqual((unsigned long long)[[[OFData
	    dataWithItems: "\x0A\x09\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
		    count: 11] objectByParsingASN1DER] longLongValue],
	    ULLONG_MAX);
}

- (void)testInvalidEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00\x00"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00\x7F"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\xFF\x80"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testOutOfRangeEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x09\x01"
				    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedEnumeratedFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0A\x02\x00"
			     count: 3] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testUTF8String
{
	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\x0C\x0EHällo Wörld!"
			     count: 16] objectByParsingASN1DER],
	    @"Hällo Wörld!");

	OTAssertEqualObjects(
	    [[OFData dataWithItems: "\x0C\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxx"
			     count: 131] objectByParsingASN1DER],
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
}

- (void)testOutOfRangeUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x83\x01\x01"
			     count: 4] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testInvalidUTF8StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x81\x7F"
			     count: 3] objectByParsingASN1DER],
	    OFInvalidFormatException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x0C\x82\x00\x80xxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxx"
			     count: 132] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testSequence
{
	OFArray *array;

	array = [[OFData dataWithItems: "\x30\x00"
				 count: 2] objectByParsingASN1DER];
	OTAssertTrue([array isKindOfClass: [OFArray class]]);
	OTAssertEqual(array.count, 0);

	array = [[OFData dataWithItems: "\x30\x09\x02\x01\x7B\x0C\x04Test"
				 count: 11] objectByParsingASN1DER];
	OTAssertTrue([array isKindOfClass: [OFArray class]]);
	OTAssertEqual(array.count, 2);
	OTAssertEqual([[array objectAtIndex: 0] longLongValue], 123);
	OTAssertEqualObjects([array objectAtIndex: 1], @"Test");
}

- (void)testTruncatedSequenceFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x30\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x30\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingASN1DER],
	    OFTruncatedDataException);
}
- (void)testSet
{
	OFSet *set;

	set = [[OFData dataWithItems: "\x31\x00"
			       count: 2] objectByParsingASN1DER];
	OTAssertTrue([set isKindOfClass: [OFSet class]]);
	OTAssertEqual(set.count, 0);

	set = [[OFData dataWithItems: "\x31\x09\x02\x01\x7B\x0C\x04Test"
			       count: 11] objectByParsingASN1DER];
	OTAssertTrue([set isKindOfClass: [OFSet class]]);
	OTAssertEqual(set.count, 2);

	OTAssertEqualObjects(set,
	    ([OFSet setWithObjects: [OFNumber numberWithLongLong: 123],
	    @"Test", nil]));
}

- (void)testInvalidSetFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x06\x02\x01\x02\x02\x01\x01"
			     count: 8] objectByParsingASN1DER],
	    OFInvalidFormatException);
}

- (void)testTruncatedSetFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);

	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x31\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testNumericString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x12\x0B" "12345 67890"
		    count: 13] objectByParsingASN1DER] numericStringValue],
	    @"12345 67890");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x12\x81\x80" "000000000000000000000000000000000000"
			   "000000000000000000000000000000000000000000000000000"
			   "00000000000000000000000000000000000000000"
		    count: 131] objectByParsingASN1DER] numericStringValue],
	    @"00000000000000000000000000000000000000000000000000000000000000000"
	    @"000000000000000000000000000000000000000000000000000000000000000");
}

- (void)testInvalidNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x02."
			     count: 4] objectByParsingASN1DER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangeNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedNumericStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x12\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testPrintableString
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x13\x0CHello World."
		    count: 14] objectByParsingASN1DER] printableStringValue],
	    @"Hello World.");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x13\x81\x80 '()+,-./:=?abcdefghijklmnopqrstuvwxyzA"
			   "BCDEFGHIJKLMNOPQRSTUVWXYZ '()+,-./:=?abcdefghijklmn"
			   "opqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		    count: 131] objectByParsingASN1DER] printableStringValue],
	    @" '()+,-./:=?abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "
	    @"'()+,-./:=?abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
}

- (void)testInvalidPrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x02;"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangePrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedPrintableStringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x13\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}

- (void)testIA5String
{
	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x16\x0CHello World!"
		    count: 14] objectByParsingASN1DER] IA5StringValue],
	    @"Hello World!");

	OTAssertEqualObjects([[[OFData
	    dataWithItems: "\x16\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		    count: 131] objectByParsingASN1DER] IA5StringValue],
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	    @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
}

- (void)testInvalidIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x02ä"
			     count: 4] objectByParsingASN1DER],
	    OFInvalidEncodingException);
}

- (void)testOutOfRangeIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER],
	    OFOutOfRangeException);
}

- (void)testTruncatedIA5StringFails
{
	OTAssertThrowsSpecific(
	    [[OFData dataWithItems: "\x16\x01"
			     count: 2] objectByParsingASN1DER],
	    OFTruncatedDataException);
}
@end
