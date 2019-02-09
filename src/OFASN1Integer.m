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

#import "OFASN1Integer.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

intmax_t
of_asn1_der_integer_parse(const unsigned char *buffer, size_t length)
{
	uintmax_t value = 0;

	/* TODO: Support for big numbers */
	if (length > sizeof(uintmax_t) &&
	    (length != sizeof(uintmax_t) + 1 || buffer[0] != 0))
		@throw [OFOutOfRangeException exception];

	if (length >= 2 && ((buffer[0] == 0 && !(buffer[1] & 0x80)) ||
	    (buffer[0] == 0xFF && buffer[1] & 0x80)))
		@throw [OFInvalidFormatException exception];

	if (length >= 1 && buffer[0] & 0x80)
		value = ~(uintmax_t)0;

	while (length--)
		value = (value << 8) | *buffer++;

	return value;
}

@implementation OFASN1Integer
@synthesize integerValue = _integerValue;

+ (instancetype)integerWithIntegerValue: (intmax_t)integerValue
{
	return [[[self alloc] initWithIntegerValue: integerValue] autorelease];
}

- (instancetype)initWithIntegerValue: (intmax_t)integerValue
{
	self = [super init];

	_integerValue = integerValue;

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	intmax_t integerValue;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_INTEGER || constructed)
			@throw [OFInvalidArgumentException exception];

		if ([DEREncodedContents itemSize] != 1)
			@throw [OFInvalidArgumentException exception];

		integerValue = of_asn1_der_integer_parse(
		    [DEREncodedContents items], [DEREncodedContents count]);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return [self initWithIntegerValue: integerValue];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (bool)isEqual: (id)object
{
	OFASN1Integer *integer;

	if (![object isKindOfClass: [OFASN1Integer class]])
		return false;

	integer = object;

	if (integer->_integerValue != _integerValue)
		return false;

	return true;
}

- (uint32_t)hash
{
	return (uint32_t)_integerValue;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Integer: %jd>",
					   _integerValue];
}
@end
