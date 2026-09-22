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

#import "OFASN1BitString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1BitString
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
	void *pool = objc_autoreleasePoolPush();

	OFMutableData *DEREncodedContents;
	@try {
		if (bits.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		size_t roundedUpLength = OFRoundUpToPowerOf2(8, bitsCount);
		unsigned char unusedBits = roundedUpLength - bitsCount;

		size_t bytesCount = bits.count;
		if (bytesCount != roundedUpLength / 8)
			@throw [OFInvalidFormatException exception];

		DEREncodedContents = [OFMutableData
		    dataWithCapacity: bytesCount + 1];
		[DEREncodedContents addItem: &unusedBits];
		[DEREncodedContents addItems: bits.items count: bytesCount];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: tagClass
				      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];

	@try {
		size_t count = DEREncodedContents.count;
		if (count == 0)
			@throw [OFInvalidFormatException exception];

		unsigned char unusedBits =
		    *(unsigned char *)[DEREncodedContents itemAtIndex: 0];

		if (unusedBits > 7)
			@throw [OFInvalidFormatException exception];

		/*
		 * Can't have any bits of the last byte unused if we have no
		 * byte.
		 */
		if (count == 1 && unusedBits > 0)
			@throw [OFInvalidFormatException exception];

		/* Check that all unused bits are 0 */
		if (count > 1 && unusedBits > 0 && *(unsigned char *)
		    [DEREncodedContents itemAtIndex: count - 1] &
		    ((1 << unusedBits) - 1))
			@throw [OFInvalidFormatException exception];

		if (SIZE_MAX / 8 < count - 1)
			@throw [OFOutOfRangeException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFData *)bits
{
	return [_DEREncodedContents subdataWithRange:
	    OFMakeRange(1, _DEREncodedContents.count - 1)];
}

- (size_t)bitsCount
{
	unsigned char unusedBits =
	    *(unsigned char *)[_DEREncodedContents itemAtIndex: 0];
	return (_DEREncodedContents.count - 1) * 8 - unusedBits;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tBits count = %zu\n"
	    @"\tBits = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), self.bitsCount,
	    self.bits];
}
@end
