/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFData.h"
#import "OFASN1Boolean.h"
#import "OFASN1IA5String.h"
#import "OFASN1Integer.h"
#import "OFASN1Null.h"
#import "OFASN1OctetString.h"
#import "OFASN1UTF8String.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

static OFString *module = @"OFData+ASN1DERValue";

@implementation TestsAppDelegate (OFDataASN1DERValueTests)
- (void)dataASN1DERValueTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *array;

	TEST(@"Parsing of boolean",
	    ![[[OFData dataWithItems: "\x01\x01\x00"
			       count: 3] ASN1DERValue] booleanValue] &&
	    [[[OFData dataWithItems: "\x01\x01\xFF"
			      count: 3] ASN1DERValue] booleanValue])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #1",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x01\x01\x01"
						       count: 3] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #2",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x01\x02\x00\x00"
						       count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of invalid boolean #3",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x01\x00"
						       count: 2] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated boolean",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x01\x01"
						       count: 2] ASN1DERValue])

	TEST(@"Parsing of integer",
	    [[[OFData dataWithItems: "\x02\x00"
			      count: 2] ASN1DERValue] integerValue] == 0 &&
	    [[[OFData dataWithItems: "\x02\x01\x01"
			      count: 3] ASN1DERValue] integerValue] == 1 &&
	    [[[OFData dataWithItems: "\x02\x02\x01\x04"
			      count: 4] ASN1DERValue] integerValue] == 260 &&
	    [[[OFData dataWithItems: "\x02\x01\xFF"
			      count: 3] ASN1DERValue] integerValue] == -1 &&
	    [[[OFData dataWithItems: "\x02\x03\xFF\x00\x00"
			      count: 5] ASN1DERValue] integerValue] == -65536 &&
	    (uintmax_t)[[[OFData dataWithItems: "\x02\x09\x00\xFF\xFF\xFF\xFF"
						"\xFF\xFF\xFF\xFF"
					 count: 11] ASN1DERValue]
	    integerValue] == UINTMAX_MAX)

	EXPECT_EXCEPTION(@"Detecting of invalid integer #1",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x02\x02\x00\x00"
						       count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detecting of invalid integer #2",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x02\x02\x00\x7F"
						       count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detecting of invalid integer #3",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x02\x02\xFF\x80"
						       count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of out of range integer",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x02\x09\x01"
				    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
			     count: 11] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated integer",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x02\x02\x00"
						       count: 3] ASN1DERValue])

	TEST(@"Parsing of octet string",
	    [[[[OFData dataWithItems: "\x04\x0CHello World!"
			      count: 14] ASN1DERValue] octetStringValue]
	    isEqual: [OFData dataWithItems: "Hello World!"
				     count: 12]] &&
	    [[[[OFData dataWithItems: "\x04\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxx"
			      count: 131] ASN1DERValue] octetStringValue]
	    isEqual: [OFData dataWithItems: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
					    "xxxxxxxxxxxxxxxxxxxxxxxxxx"
				     count: 128]])

	EXPECT_EXCEPTION(@"Detection of out of range octet string",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x16\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated octet string",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x16\x01"
						       count: 2] ASN1DERValue])

	TEST(@"Parsing of NULL",
	    [[[OFData dataWithItems: "\x05\x00"
			      count: 2] ASN1DERValue]
	    isKindOfClass: [OFASN1Null class]])

	EXPECT_EXCEPTION(@"Detection of invalid NULL",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x05\x01\x00"
						       count: 3] ASN1DERValue])

	TEST(@"Parsing of UTF-8 string",
	    [[[[OFData dataWithItems: "\x0C\x0EHällo Wörld!"
			      count: 16] ASN1DERValue] UTF8StringValue]
	    isEqual: @"Hällo Wörld!"] &&
	    [[[[OFData dataWithItems: "\x0C\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxx"
			      count: 131] ASN1DERValue] UTF8StringValue]
	    isEqual: @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxx"])

	EXPECT_EXCEPTION(@"Detection of out of range UTF-8 string",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x0C\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated UTF-8 string",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x0C\x01"
						       count: 2] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated length",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x0C\x83\x01\x01"
						       count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of invalid / inefficient length #1",
	    OFInvalidFormatException, [[OFData dataWithItems: "\x0C\x81\x7F"
						       count: 3] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of invalid / inefficient length #2",
	    OFInvalidFormatException,
	    [[OFData dataWithItems: "\x0C\x82\x00\x80xxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				    "xxxxxxxxxxxxxxxxxx"
			     count: 132] ASN1DERValue])

	TEST(@"Parsing of sequence",
	    (array = [[OFData dataWithItems: "\x30\x00"
				      count: 2] ASN1DERValue]) &&
	    [array isKindOfClass: [OFArray class]] && [array count] == 0 &&
	    (array = [[OFData dataWithItems: "\x30\x09\x02\x01\x7B\x0C\x04Test"
				      count: 11] ASN1DERValue]) &&
	    [array isKindOfClass: [OFArray class]] && [array count] == 2 &&
	    [[array objectAtIndex: 0] integerValue] == 123 &&
	    [[[array objectAtIndex: 1] stringValue] isEqual: @"Test"])

	EXPECT_EXCEPTION(@"Parsing of truncated sequence #1",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x30\x01"
						       count: 2] ASN1DERValue])

	EXPECT_EXCEPTION(@"Parsing of truncated sequence #2",
	    OFTruncatedDataException,
	    [[OFData dataWithItems: "\x30\x04\x02\x01\x01\x00\x00"
			     count: 7] ASN1DERValue])

	TEST(@"Parsing of IA5String",
	    [[[[OFData dataWithItems: "\x16\x0CHello World!"
			      count: 14] ASN1DERValue] IA5StringValue]
	    isEqual: @"Hello World!"] &&
	    [[[[OFData dataWithItems: "\x16\x81\x80xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				      "xxxxxxxxxxxxxxxxxxxx"
			      count: 131] ASN1DERValue] IA5StringValue]
	    isEqual: @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		     @"xxxxxxxxxxxxxxxx"])

	EXPECT_EXCEPTION(@"Detection of invalid IA5String",
	    OFInvalidEncodingException,
	    [[OFData dataWithItems: "\x16\x02ä"
			     count: 4] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of out of range IA5String",
	    OFOutOfRangeException,
	    [[OFData dataWithItems: "\x16\x89"
				    "\x01\x01\x01\x01\x01\x01\x01\x01\x01"
			     count: 11] ASN1DERValue])

	EXPECT_EXCEPTION(@"Detection of truncated IA5String",
	    OFTruncatedDataException, [[OFData dataWithItems: "\x16\x01"
						       count: 2] ASN1DERValue])

	[pool drain];
}
@end
