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

#import "TestsAppDelegate.h"

static OFString *module = @"OFData+ASN1DERParsing";

@implementation TestsAppDelegate (OFASN1DERParsingTests)
- (void)ASN1DERParsingTests
{
	void *pool = objc_autoreleasePoolPush();
	OFASN1BitString *bitString;
	OFArray *array;
	OFSet *set;
	OFEnumerator *enumerator;

	/* Boolean */
	TEST(@"Parsing of boolean",
	    ![[[OFData dataWithItems: "\x01\x01\x00"
			       count: 3] objectByParsingASN1DER] boolValue] &&
	    [[[OFData dataWithItems: "\x01\x01\xFF"
			      count: 3] objectByParsingASN1DER] boolValue])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x01\x01\x01"
			     count: 3] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x01\x02\x00\x00"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #3",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x01\x00"
			     count: 2] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated boolean",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x01\x01"
			     count: 2] objectByParsingASN1DER])

	/* Integer */
	TEST(@"Parsing of integer",
	    [[[OFData dataWithItems: "\x02\x00"
			      count: 2] objectByParsingASN1DER]
	    longLongValue] == 0 &&
	    [[[OFData dataWithItems: "\x02\x01\x01"
			      count: 3] objectByParsingASN1DER]
	    longLongValue] == 1 &&
	    [[[OFData dataWithItems: "\x02\x02\x01\x04"
			      count: 4] objectByParsingASN1DER]
	    longLongValue] == 260 &&
	    [[[OFData dataWithItems: "\x02\x01\xFF"
			      count: 3] objectByParsingASN1DER]
	    longLongValue] == -1 &&
	    [[[OFData dataWithItems: "\x02\x03\xFF\x00\x00"
			      count: 5] objectByParsingASN1DER]
	    longLongValue] == -65536 &&
	    (unsigned long long)[[[OFData dataWithItems: "\x02\x09\x00\xFF\xFF"
							 "\xFF\xFF\xFF\xFF\xFF"
							 "\xFF"
						  count: 11]
	    objectByParsingASN1DER] longLongValue] == ULLONG_MAX)

	EXPECT_EXCEPTION(@"Detection of invalid integer #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x02\x02\x00\x00"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid integer #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x02\x02\x00\x7F"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid integer #3",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x02\x02\xFF\x80"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range integer",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x02\x09\x01"
				    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated integer",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x02\x02\x00"
			     count: 3] objectByParsingASN1DER])

	/* Bit string */
	TEST(@"Parsing of bit string",
	    (bitString = [[OFData dataWithItems: "\x03\x01\x00"
					  count: 3] objectByParsingASN1DER]) &&
	    [bitString.bitStringValue isEqual: [OFData dataWithItems: ""
							       count: 0]] &&
	    bitString.bitStringLength == 0 &&
	    (bitString = [[OFData dataWithItems: "\x03\x0D\x01Hello World\x80"
					  count: 15] objectByParsingASN1DER]) &&
	    [bitString.bitStringValue
	    isEqual: [OFData dataWithItems: "Hello World\x80"
				     count: 12]] &&
	    bitString.bitStringLength == 95 &&
	    (bitString = [[OFData dataWithItems: "\x03\x81\x80\x00xxxxxxxxxxxxx"
						 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
						 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
						 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
						 "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
					 count: 131] objectByParsingASN1DER]) &&
	    [bitString.bitStringValue
	    isEqual: [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxx"
				     count: 127]] &&
	    bitString.bitStringLength == 127 * 8)

	EXPECT_EXCEPTION(@"Detection of invalid bit string #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x03\x00"
			     count: 2] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid bit string #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x03\x01\x01"
			     count: 3] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range bit string",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x03\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated bit string",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x03\x01"
			     count: 2] objectByParsingASN1DER])

	/* Octet string */
	TEST(@"Parsing of octet string",
	    [[[[OFData dataWithItems: "\x04\x0CHello World!"
			       count: 14] objectByParsingASN1DER]
	    octetStringValue] isEqual: [OFData dataWithItems: "Hello World!"
						       count: 12]] &&
	    [[[[OFData dataWithItems: "\x04\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxx"
			       count: 131] objectByParsingASN1DER]
	    octetStringValue] isEqual:
	    [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				   "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
			    count: 128]])

	EXPECT_EXCEPTION(@"Detection of out of range octet string",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x04\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated octet string",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x04\x01"
			     count: 2] objectByParsingASN1DER])

	/* Null */
	TEST(@"Parsing of null",
	    [[[OFData dataWithItems: "\x05\x00"
			      count: 2] objectByParsingASN1DER]
	    isEqual: [OFNull null]])

	EXPECT_EXCEPTION(@"Detection of invalid null",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x05\x01\x00"
			     count: 3] objectByParsingASN1DER])

	/* Object Identifier */
	TEST(@"Parsing of Object Identifier",
	    (array = [[[OFData dataWithItems: "\x06\x01\x27"
				       count: 3] objectByParsingASN1DER]
	    subidentifiers]) && array.count == 2 &&
	    [[array objectAtIndex: 0] unsignedLongLongValue] == 0 &&
	    [[array objectAtIndex: 1] unsignedLongLongValue] == 39 &&
	    (array = [[[OFData dataWithItems: "\x06\x01\x4F"
				       count: 3] objectByParsingASN1DER]
	    subidentifiers]) && array.count == 2 &&
	    [[array objectAtIndex: 0] unsignedLongLongValue] == 1 &&
	    [[array objectAtIndex: 1] unsignedLongLongValue] == 39 &&
	    (array = [[[OFData dataWithItems: "\x06\x02\x88\x37"
				       count: 4] objectByParsingASN1DER]
	    subidentifiers]) && array.count == 2 &&
	    [[array objectAtIndex: 0] unsignedLongLongValue] == 2 &&
	    [[array objectAtIndex: 1] unsignedLongLongValue] == 999 &&
	    (array = [[[OFData dataWithItems: "\x06\x09\x2A\x86\x48\x86\xF7\x0D"
					      "\x01\x01\x0B"
				       count: 11] objectByParsingASN1DER]
	    subidentifiers]) && array.count == 7 &&
	    [[array objectAtIndex: 0] unsignedLongLongValue] == 1 &&
	    [[array objectAtIndex: 1] unsignedLongLongValue] == 2 &&
	    [[array objectAtIndex: 2] unsignedLongLongValue] == 840 &&
	    [[array objectAtIndex: 3] unsignedLongLongValue] == 113549 &&
	    [[array objectAtIndex: 4] unsignedLongLongValue] == 1 &&
	    [[array objectAtIndex: 5] unsignedLongLongValue] == 1 &&
	    [[array objectAtIndex: 6] unsignedLongLongValue] == 11)

	EXPECT_EXCEPTION(@"Detection of invalid Object Identifier #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x06\x01\x81"
			     count: 3] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid Object Identifier #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x06\x02\x80\x01"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range Object Identifier",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x06\x0A\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
				    "\xFF\x7F"
			     count: 12] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated Object Identifier",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x06\x02\x00"
			     count: 3] objectByParsingASN1DER])

	/* Enumerated */
	TEST(@"Parsing of enumerated",
	    [[[OFData dataWithItems: "\x0A\x00"
			     count: 2] objectByParsingASN1DER] longLongValue] ==
	    0 &&
	    [[[OFData dataWithItems: "\x0A\x01\x01"
			     count: 3] objectByParsingASN1DER] longLongValue] ==
	    1 &&
	    [[[OFData dataWithItems: "\x0A\x02\x01\x04"
			     count: 4] objectByParsingASN1DER] longLongValue] ==
	    260 &&
	    [[[OFData dataWithItems: "\x0A\x01\xFF"
			     count: 3] objectByParsingASN1DER] longLongValue] ==
	    -1 &&
	    [[[OFData dataWithItems: "\x0A\x03\xFF\x00\x00"
			     count: 5] objectByParsingASN1DER] longLongValue] ==
	    -65536 &&
	    (unsigned long long)[[[OFData dataWithItems: "\x0A\x09\x00\xFF\xFF"
							 "\xFF\xFF\xFF\xFF\xFF"
							 "\xFF"
						  count: 11]
	    objectByParsingASN1DER] longLongValue] == ULLONG_MAX)

	EXPECT_EXCEPTION(@"Detection of invalid enumerated #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0A\x02\x00\x00"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid enumerated #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0A\x02\x00\x7F"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid enumerated #3",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0A\x02\xFF\x80"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range enumerated",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x0A\x09\x01"
				    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated enumerated",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x0A\x02\x00"
			     count: 3] objectByParsingASN1DER])

	/* UTF-8 string */
	TEST(@"Parsing of UTF-8 string",
	    [[[OFData dataWithItems: "\x0C\x0EHällo Wörld!"
			       count: 16] objectByParsingASN1DER]
	    isEqual: @"Hällo Wörld!"] &&
	    [[[OFData dataWithItems: "\x0C\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     "xxxxxxxxxxxxxxxxx"
			      count: 131] objectByParsingASN1DER]
	    isEqual: @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxx"])

	EXPECT_EXCEPTION(@"Detection of out of range UTF-8 string",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x0C\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated UTF-8 string",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x0C\x01"
			     count: 2] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated length",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x0C\x83\x01\x01"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid / inefficient length #1",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0C\x81\x7F"
			     count: 3] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of invalid / inefficient length #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0C\x82\x00\x80xxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxx"
			     count: 132] objectByParsingASN1DER])

	/* Sequence */
	TEST(@"Parsing of sequence",
	    (array = [[OFData dataWithItems: "\x30\x00"
				      count: 2] objectByParsingASN1DER]) &&
	    [array isKindOfClass: [OFArray class]] && array.count == 0 &&
	    (array = [[OFData dataWithItems: "\x30\x09\x02\x01\x7B\x0C\x04Test"
				      count: 11] objectByParsingASN1DER]) &&
	    [array isKindOfClass: [OFArray class]] && array.count == 2 &&
	    [[array objectAtIndex: 0] longLongValue] == 123 &&
	    [[array objectAtIndex: 1] isEqual: @"Test"])

	EXPECT_EXCEPTION(@"Detection of truncated sequence #1",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x30\x01"
			     count: 2] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated sequence #2",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x30\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingASN1DER])

	/* Set */
	TEST(@"Parsing of set",
	    (set = [[OFData dataWithItems: "\x31\x00"
				    count: 2] objectByParsingASN1DER]) &&
	    [set isKindOfClass: [OFSet class]] && set.count == 0 &&
	    (set = [[OFData dataWithItems: "\x31\x09\x02\x01\x7B\x0C\x04Test"
				    count: 11] objectByParsingASN1DER]) &&
	    [set isKindOfClass: [OFSet class]] && set.count == 2 &&
	    (enumerator = [set objectEnumerator]) &&
	    [[enumerator nextObject] longLongValue] == 123 &&
	    [[enumerator nextObject] isEqual: @"Test"])

	EXPECT_EXCEPTION(@"Detection of invalid set",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x31\x06\x02\x01\x02\x02\x01\x01"
			     count: 8] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated set #1",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x31\x01"
			     count: 2] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated set #2",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x31\x04\x02\x01\x01\x00\x00"
			     count: 7] objectByParsingASN1DER])

	/* NumericString */
	TEST(@"Parsing of NumericString",
	    [[[[OFData dataWithItems: "\x12\x0B" "12345 67890"
			       count: 13] objectByParsingASN1DER]
	    numericStringValue] isEqual: @"12345 67890"] &&
	    [[[[OFData dataWithItems: "\x12\x81\x80" "0000000000000000000000000"
				      "0000000000000000000000000000000000000000"
				      "0000000000000000000000000000000000000000"
				      "00000000000000000000000"
			       count: 131] objectByParsingASN1DER]
	    numericStringValue] isEqual: @"000000000000000000000000000000000000"
					 @"000000000000000000000000000000000000"
					 @"000000000000000000000000000000000000"
					 @"00000000000000000000"])

	EXPECT_EXCEPTION(@"Detection of invalid NumericString",
	    OFInvalidEncodingException,
	    [[OFData dataWithItems: "\x12\x02."
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range NumericString",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x12\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated NumericString",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x12\x01"
			     count: 2] objectByParsingASN1DER])

	/* PrintableString */
	TEST(@"Parsing of PrintableString",
	    [[[[OFData dataWithItems: "\x13\x0CHello World."
			       count: 14] objectByParsingASN1DER]
	    printableStringValue] isEqual: @"Hello World."] &&
	    [[[[OFData dataWithItems: "\x13\x81\x80 '()+,-./:=?abcdefghijklmnop"
				      "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '()"
				      "+,-./:=?abcdefghijklmnopqrstuvwxyzABCDEF"
				      "GHIJKLMNOPQRSTUVWXYZ"
			       count: 131] objectByParsingASN1DER]
	    printableStringValue] isEqual: @" '()+,-./:=?abcdefghijklmnopqrstuv"
					   @"wxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '()"
					   @"+,-./:=?abcdefghijklmnopqrstuvwxyz"
					   @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"])

	EXPECT_EXCEPTION(@"Detection of invalid PrintableString",
	    OFInvalidEncodingException,
	    [[OFData dataWithItems: "\x13\x02;"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range PrintableString",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x13\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated PrintableString",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x13\x01"
			     count: 2] objectByParsingASN1DER])

	/* IA5String */
	TEST(@"Parsing of IA5String",
	    [[[[OFData dataWithItems: "\x16\x0CHello World!"
			       count: 14] objectByParsingASN1DER]
	    IA5StringValue] isEqual: @"Hello World!"] &&
	    [[[[OFData dataWithItems: "\x16\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxx"
			       count: 131] objectByParsingASN1DER]
	    IA5StringValue] isEqual: @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				     @"xxxxxxxx"])

	EXPECT_EXCEPTION(@"Detection of invalid IA5String",
	    OFInvalidEncodingException,
	    [[OFData dataWithItems: "\x16\x02ä"
			     count: 4] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of out of range IA5String",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x16\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] objectByParsingASN1DER])

	EXPECT_EXCEPTION(@"Detection of truncated IA5String",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x16\x01"
			     count: 2] objectByParsingASN1DER])

	objc_autoreleasePoolPop(pool);
}
@end
