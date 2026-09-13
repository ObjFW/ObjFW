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
_OFASN1DERDecodeInteger(const unsigned char *buffer, size_t length)
{
	if (length == 0)
		@throw [OFInvalidFormatException exception];

	if (length > sizeof(long long))
		@throw [OFOutOfRangeException exception];

	unsigned long long unsignedValue = 0;
	if (buffer[0] & 0x80)
		unsignedValue = ~0ull;

	for (size_t i = 0; i < length; i++)
		unsignedValue = (unsignedValue << 8) | *buffer++;

	long long value = unsignedValue;
	size_t expectedLength;
	if (value >= -128 && value <= 127)
		expectedLength = 1;
	else if (value >= -32768 && value <= 32767)
		expectedLength = 2;
	else if (value >= -8388608 && value <= 8388607)
		expectedLength = 3;
	else if (value >= -2147483648 && value <= 2147483647)
		expectedLength = 4;
	else if (value >= -549755813888 && value <= 549755813887)
		expectedLength = 5;
	else if (value >= -140737488355328 && value <= 140737488355327)
		expectedLength = 6;
	else if (value >= -36028797018963968 && value <= 36028797018963967)
		expectedLength = 7;
	else
		expectedLength = 8;

	if (length != expectedLength)
		@throw [OFInvalidFormatException exception];

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
		/* TODO: Support for big numbers */

		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberInteger || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		value = _OFASN1DERDecodeInteger(
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
