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

#import "OFASN1Enumerated.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1Enumerated
@synthesize int64Value = _int64Value;

+ (instancetype)enumeratedWithInt64: (int64_t)value
{
	return objc_autoreleaseReturnValue([[self alloc] initWithInt64: value]);
}

- (instancetype)initWithInt64: (int64_t)value
{
	self = [super init];

	_int64Value = value;

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	int64_t value;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberEnumerated || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		value = _OFDERDecodeInteger(
		    DEREncodedContents.items, DEREncodedContents.count);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithInt64: value];
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
	return OFASN1TagNumberEnumerated;
}

- (bool)isConstructed
{
	return false;
}

- (OFData *)DERRepresentation
{
	OFMutableData *data = [OFMutableData dataWithCapacity: 10];
	unsigned char tag = OFASN1TagNumberEnumerated;
	[data addItem: &tag];

	unsigned char buffer[8];
	unsigned char length = _OFDEREncodeInteger(_int64Value, buffer);
	[data addItem: &length];

	[data addItems: buffer count: length];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Enumerated: %" @PRId64 @">",
					   _int64Value];
}
@end
