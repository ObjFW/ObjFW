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
@synthesize bits = _bits, bitsCount = _bitsCount;

+ (instancetype)bitStringWithBits: (OFData *)bits bitsCount: (size_t)bitsCount
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithBits: bits bitsCount: bitsCount]);
}

+ (instancetype)bitStringWithBits: (OFData *)bits
			bitsCount: (size_t)bitsCount
			 tagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithBits: bits
	       bitsCount: bitsCount
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

- (instancetype)initWithBits: (OFData *)bits bitsCount: (size_t)bitsCount
{
	return [self initWithBits: bits
			bitsCount: bitsCount
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberBitString];
}

- (instancetype)initWithBits: (OFData *)bits
		   bitsCount: (size_t)bitsCount
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (bits.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		if (bits.count != OFRoundUpToPowerOf2(8, bitsCount) / 8)
			@throw [OFInvalidFormatException exception];

		_bits = [bits copy];
		_bitsCount = bitsCount;
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

	OFData *bits;
	size_t bitsCount;
	@try {
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

		bits = [DEREncodedContents subdataWithRange:
		    OFMakeRange(1, count - 1)];
		bitsCount = (count - 1) * 8 - unusedBits;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithBits: bits
			bitsCount: bitsCount
			 tagClass: tagClass
			tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_bits);

	[super dealloc];
}

- (OFData *)DERRepresentation
{
	size_t bytesCount = _bits.count;
	if (SIZE_MAX - bytesCount < 3)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data = [OFMutableData dataWithCapacity: bytesCount + 3];
	unsigned char tag = _OFDEREncodeTag(_tagClass, _tagNumber, false);
	[data addItem: &tag];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(bytesCount + 1, length)];

	size_t roundedUpLength = OFRoundUpToPowerOf2(8, _bitsCount);
	unsigned char unusedBits = roundedUpLength - _bitsCount;

	if (bytesCount != roundedUpLength / 8)
		@throw [OFInvalidFormatException exception];

	[data addItem: &unusedBits];
	[data addItems: _bits.items count: bytesCount];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1BitString: %@ (%zu bits)>",
					   _bits, _bitsCount];
}
@end
