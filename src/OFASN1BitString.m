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
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1BitString
@synthesize bitStringValue = _bitStringValue;
@synthesize bitStringLength = _bitStringLength;

+ (instancetype)bitStringWithBitString: (OFData *)bitString
				length: (size_t)length
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithBitString: bitString length: length]);
}

- (instancetype)initWithBitString: (OFData *)bitString length: (size_t)length
{
	self = [super init];

	@try {
		if (bitString.count * bitString.itemSize !=
		    OFRoundUpToPowerOf2(8, length) / 8)
			@throw [OFInvalidFormatException exception];

		_bitStringValue = [bitString copy];
		_bitStringLength = length;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFData *bitString;
	size_t length;

	@try {
		unsigned char unusedBits;
		size_t count = DEREncodedContents.count;

		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberBitString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1 || count == 0)
			@throw [OFInvalidFormatException exception];

		unusedBits =
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

		length = (count - 1) * 8;
		bitString = [DEREncodedContents subdataWithRange:
		    OFMakeRange(1, count - 1)];

		if (unusedBits != 0)
			length -= unusedBits;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithBitString: bitString length: length];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_bitStringValue);

	[super dealloc];
}

- (OFData *)ASN1DERRepresentation
{
	size_t bitStringValueCount = _bitStringValue.count;
	size_t roundedUpLength = OFRoundUpToPowerOf2(8, _bitStringLength);
	unsigned char unusedBits = roundedUpLength - _bitStringLength;
	unsigned char header[] = {
		OFASN1TagNumberBitString,
		bitStringValueCount + 1,
		unusedBits
	};
	OFMutableData *data;

	if (bitStringValueCount + 1 > UINT8_MAX ||
	    bitStringValueCount != roundedUpLength / 8)
		@throw [OFInvalidFormatException exception];

	data = [OFMutableData
	    dataWithCapacity: sizeof(header) + bitStringValueCount];
	[data addItems: header count: sizeof(header)];
	[data addItems: _bitStringValue.items count: bitStringValueCount];

	[data makeImmutable];

	return data;
}

- (bool)isEqual: (id)object
{
	OFASN1BitString *bitString;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1BitString class]])
		return false;

	bitString = object;

	if (![bitString->_bitStringValue isEqual: _bitStringValue])
		return false;
	if (bitString->_bitStringLength != _bitStringLength)
		return false;

	return true;
}

- (unsigned long)hash
{
	return _bitStringValue.hash + (unsigned long)_bitStringLength;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1BitString: %@ (%zu bits)>",
					   _bitStringValue, _bitStringLength];
}
@end
