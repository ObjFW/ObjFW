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

#import "OFASN1BitString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1BitString
@synthesize data = _data, bitLength = _bitLength;

+ (instancetype)bitStringWithData: (OFData *)data bitLength: (size_t)bitLength
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithData: data bitLength: bitLength]);
}

- (instancetype)initWithData: (OFData *)data bitLength: (size_t)bitLength
{
	self = [super init];

	@try {
		if (data.count * data.itemSize !=
		    OFRoundUpToPowerOf2(8, bitLength) / 8)
			@throw [OFInvalidFormatException exception];

		_data = [data copy];
		_bitLength = bitLength;
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
	void *pool = objc_autoreleasePoolPush();
	OFData *data;
	size_t bitLength;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberBitString || constructed)
			@throw [OFInvalidArgumentException exception];

		size_t count = DEREncodedContents.count;

		if (DEREncodedContents.itemSize != 1 || count == 0)
			@throw [OFInvalidFormatException exception];

		unsigned char unusedBits =
		    *(unsigned char *)[DEREncodedContents itemAtIndex: 0];

		if (unusedBits > 7)
			@throw [OFInvalidFormatException exception];

		/*
		 * Can't have any bits of the last byte unused if we have no
		 * byte.
		 */
		if (count == 1 && unusedBits != 0)
			@throw [OFInvalidFormatException exception];

		if (SIZE_MAX / 8 < count - 1)
			@throw [OFOutOfRangeException exception];

		bitLength = (count - 1) * 8;
		data = [DEREncodedContents subdataWithRange:
		    OFMakeRange(1, count - 1)];

		if (unusedBits != 0)
			bitLength -= unusedBits;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithData: data bitLength: bitLength];

	objc_autoreleasePoolPop(pool);

	return self;
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
	return OFASN1TagNumberBitString;
}

- (bool)isConstructed
{
	return false;
}

- (OFData *)DERRepresentation
{
	size_t dataCount = _data.count;
	if (SIZE_MAX - dataCount < 3)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data = [OFMutableData dataWithCapacity: dataCount + 3];
	unsigned char tag = OFASN1TagNumberBitString;
	[data addItem: &tag];

	unsigned char length[9];
	[data addItems: length
		 count: _OFASN1DEREncodeLength(dataCount + 1, length)];

	size_t roundedUpLength = OFRoundUpToPowerOf2(8, _bitLength);
	unsigned char unusedBits = roundedUpLength - _bitLength;

	if (dataCount != roundedUpLength / 8)
		@throw [OFInvalidFormatException exception];

	[data addItem: &unusedBits];
	[data addItems: _data.items count: dataCount];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1BitString: %@ (%zu bits)>",
					   _data, _bitLength];
}
@end
