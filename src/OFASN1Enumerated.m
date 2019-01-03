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

#import "OFASN1Enumerated.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

extern intmax_t of_asn1_integer_parse(const unsigned char *buffer,
    size_t length);

@implementation OFASN1Enumerated
@synthesize integerValue = _integerValue;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_ENUMERATED || constructed)
			@throw [OFInvalidArgumentException exception];

		if ([DEREncodedContents itemSize] != 1)
			@throw [OFInvalidArgumentException exception];

		_integerValue = of_asn1_integer_parse(
		    [DEREncodedContents items], [DEREncodedContents count]);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)isEqual: (id)object
{
	OFASN1Enumerated *enumerated;

	if (![object isKindOfClass: [OFASN1Enumerated class]])
		return false;

	enumerated = object;

	if (enumerated->_integerValue != _integerValue)
		return false;

	return true;
}

- (uint32_t)hash
{
	return (uint32_t)_integerValue;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Enumerated: %jd>",
					   _integerValue];
}
@end
