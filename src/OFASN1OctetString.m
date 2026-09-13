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

#import "OFASN1OctetString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1OctetString
@synthesize dataValue = _data;

+ (instancetype)octetStringWithData: (OFData *)data
{
	return objc_autoreleaseReturnValue([[self alloc] initWithData: data]);
}

- (instancetype)initWithData: (OFData *)data
{
	self = [super init];

	@try {
		_data = [data copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberOctetString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithData: DEREncodedContents];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_data);

	[super dealloc];
}

- (OFASN1TagClass)tagClass
{
	return OFASN1TagClassUniversal;
}

- (OFASN1TagNumber)tagNumber
{
	return OFASN1TagNumberOctetString;
}

- (bool)isConstructed
{
	return false;
}

- (OFData *)DERRepresentation
{
	size_t dataCount = _data.count;
	if (SIZE_MAX - dataCount < 2)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data = [OFMutableData dataWithCapacity: dataCount + 2];
	unsigned char tag = OFASN1TagNumberOctetString;
	[data addItem: &tag];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(dataCount, length)];

	[data addItems: _data.items count: dataCount];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1OctetString: %@>", _data];
}
@end
