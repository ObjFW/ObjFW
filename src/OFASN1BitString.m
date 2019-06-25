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

#import "OFASN1BitString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1BitString
@synthesize bitStringValue = _bitStringValue;
@synthesize bitStringLength = _bitStringLength;

+ (instancetype)bitStringWithBitStringValue: (OFData *)bitStringValue
			    bitStringLength: (size_t)bitStringLength
{
	return [[[self alloc]
	    initWithBitStringValue: bitStringValue
		   bitStringLength: bitStringLength] autorelease];
}

- (instancetype)initWithBitStringValue: (OFData *)bitStringValue
		       bitStringLength: (size_t)bitStringLength
{
	self = [super init];

	@try {
		if (bitStringValue.count * bitStringValue.itemSize !=
		    OF_ROUND_UP_POW2(8, bitStringLength) / 8)
			@throw [OFInvalidFormatException exception];

		_bitStringValue = [bitStringValue copy];
		_bitStringLength = bitStringLength;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFData *bitStringValue;
	size_t bitStringLength;

	@try {
		unsigned char unusedBits;
		size_t count = DEREncodedContents.count;

		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_BIT_STRING || constructed)
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

		bitStringLength = (count - 1) * 8;
		bitStringValue = [[DEREncodedContents
		    subdataWithRange: of_range(1, count - 1)] copy];

		if (unusedBits != 0)
			bitStringLength -= unusedBits;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithBitStringValue: bitStringValue
			    bitStringLength: bitStringLength];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_bitStringValue release];

	[super dealloc];
}

- (OFData *)ASN1DERRepresentation
{
	size_t bitStringValueCount = [_bitStringValue count];
	size_t roundedUpLength = OF_ROUND_UP_POW2(8, _bitStringLength);
	unsigned char unusedBits = roundedUpLength - _bitStringLength;
	unsigned char header[] = {
		OF_ASN1_TAG_NUMBER_BIT_STRING,
		bitStringValueCount + 1,
		unusedBits
	};
	OFMutableData *data;

	if (bitStringValueCount + 1 > UINT8_MAX ||
	    bitStringValueCount != roundedUpLength / 8)
		@throw [OFInvalidFormatException exception];

	data = [OFMutableData
	    dataWithCapacity: sizeof(header) + bitStringValueCount];
	[data addItems: header
		 count: sizeof(header)];
	[data addItems: [_bitStringValue items]
		 count: bitStringValueCount];

	[data makeImmutable];

	return data;
}

- (bool)isEqual: (id)object
{
	OFASN1BitString *bitString;

	if (![object isKindOfClass: [OFASN1BitString class]])
		return false;

	bitString = object;

	if (![bitString->_bitStringValue isEqual: _bitStringValue])
		return false;
	if (bitString->_bitStringLength != _bitStringLength)
		return false;

	return true;
}

- (uint32_t)hash
{
	return _bitStringValue.hash + (uint32_t)_bitStringLength;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1BitString: %@ (%zu bits)>",
					   _bitStringValue, _bitStringLength];
}
@end
