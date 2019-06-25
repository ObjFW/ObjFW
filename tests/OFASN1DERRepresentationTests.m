/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "TestsAppDelegate.h"

static OFString *module;

@implementation TestsAppDelegate (OFASN1DERRepresentationTests)
- (void)ASN1DERRepresentationTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFData *data;

	module = @"OFASN1BitString";
	TEST(@"-[ASN1DERRepresentation]",
	    (data = [OFData dataWithItems: "\xFF\x00\xF8"
				    count: 3]) &&
	    [[[OFASN1BitString bitStringWithBitStringValue: data
					   bitStringLength: 21]
	    ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x03\x04\x03\xFF\x00\xF8"
			    count: 6]] &&
	    (data = [OFData dataWithItems: "abcdefäöü"
				    count: 12]) &&
	    [[[OFASN1BitString bitStringWithBitStringValue: data
					   bitStringLength: 12 * 8]
	    ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x03\x0D\x00" "abcdefäöü"
			    count: 15]] &&
	    (data = [OFData dataWithItems: ""
				    count: 0]) &&
	    [[[OFASN1BitString bitStringWithBitStringValue: data
					   bitStringLength: 0]
	    ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x03\x01\x00"
			    count: 3]])

	module = @"OFASN1Boolean";
	TEST(@"-[ASN1DERRepresentation]",
	    [[[OFASN1Boolean booleanWithBooleanValue: false]
	    ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x01\x01\x00"
			    count: 3]] &&
	    [[[OFASN1Boolean booleanWithBooleanValue: true]
	    ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x01\x01\xFF"
			    count: 3]])

	module = @"OFNull";
	TEST(@"-[OFASN1DERRepresentation]",
	    [[[OFNull null] ASN1DERRepresentation] isEqual:
	    [OFData dataWithItems: "\x05\x00"
			    count: 2]])

	[pool drain];
}
@end
