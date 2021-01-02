/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

long long
of_asn1_der_integer_parse(const unsigned char *buffer, size_t length)
{
	unsigned long long value = 0;

	/* TODO: Support for big numbers */
	if (length > sizeof(unsigned long long) &&
	    (length != sizeof(unsigned long long) + 1 || buffer[0] != 0))
		@throw [OFOutOfRangeException exception];

	if (length >= 2 && ((buffer[0] == 0 && !(buffer[1] & 0x80)) ||
	    (buffer[0] == 0xFF && buffer[1] & 0x80)))
		@throw [OFInvalidFormatException exception];

	if (length >= 1 && buffer[0] & 0x80)
		value = ~0ull;

	while (length--)
		value = (value << 8) | *buffer++;

	return value;
}

@implementation OFASN1Integer
@synthesize longLongValue = _longLongValue;

+ (instancetype)integerWithLongLong: (long long)value
{
	return [[[self alloc] initWithLongLong: value] autorelease];
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super init];

	_longLongValue = value;

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	long long value;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_INTEGER || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		value = of_asn1_der_integer_parse(
		    DEREncodedContents.items, DEREncodedContents.count);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return [self initWithLongLong: value];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (bool)isEqual: (id)object
{
	OFASN1Integer *integer;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1Integer class]])
		return false;

	integer = object;

	if (integer->_longLongValue != _longLongValue)
		return false;

	return true;
}

- (unsigned long)hash
{
	return (unsigned long)_longLongValue;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Integer: %lld>",
					   _longLongValue];
}
@end
