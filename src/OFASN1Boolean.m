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

#import "OFASN1Boolean.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Boolean
@synthesize booleanValue = _booleanValue;

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super initWithTagClass: tagClass
			     tagNumber: tagNumber
			   constructed: constructed
		    DEREncodedContents: DEREncodedContents];

	@try {
		unsigned char value;

		if (_tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    _tagNumber != OF_ASN1_TAG_NUMBER_BOOLEAN || _constructed)
			@throw [OFInvalidArgumentException exception];

		if ([_DEREncodedContents count] != 1)
			@throw [OFInvalidFormatException exception];

		value = *(unsigned char *)[_DEREncodedContents itemAtIndex: 0];

		if (value != 0 && value != 0xFF)
			@throw [OFInvalidFormatException exception];

		_booleanValue = value;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
@end
