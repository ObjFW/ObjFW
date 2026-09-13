/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFASN1Integer.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

long long OF_VISIBILITY_INTERNAL
_OFASN1DERIntegerParse(const unsigned char *buffer, size_t length)
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
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithLongLong: value]);
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super init];

	_longLongValue = value;

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	long long value;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberInteger || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		value = _OFASN1DERIntegerParse(
		    DEREncodedContents.items, DEREncodedContents.count);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithLongLong: value];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFASN1TagClass)tagClass
{
	return OFASN1TagClassUniversal;
}

- (OFASN1TagNumber)tagNumber
{
	return OFASN1TagNumberInteger;
}

- (bool)isConstructed
{
	return false;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Integer: %lld>",
					   _longLongValue];
}
@end
