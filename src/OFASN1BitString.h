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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @brief An ASN.1 BitString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1BitString: OFASN1Value
{
	OFData *_bits;
	size_t _bitsCount;
}

/**
 * @brief The BitString value.
 */
@property (readonly, nonatomic) OFData *bits;

/**
 * @brief The number of bits in the BitString.
 */
@property (readonly, nonatomic) size_t bitsCount;

/**
 * @brief Creates an ASN.1 BitString with the specified BitString value and
 *	  length.
 *
 * @param bits The value of the BitString
 * @param bitsCount The number of bits in the BitString
 * @return A new, autoreleased OFASN1BitString
 */
+ (instancetype)bitStringWithBits: (OFData *)bits bitsCount: (size_t)bitsCount;

/**
 * @brief Creates an ASN.1 BitString with the specified BitString value and
 *	  length.
 *
 * @param bits The value of the BitString
 * @param bitsCount The number of bits in the BitString
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1BitString
 */
+ (instancetype)bitStringWithBits: (OFData *)bits
			bitsCount: (size_t)bitsCount
			 tagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 BitString with the specified
 *	  BitString value and length.
 *
 * @param bits The value of the BitString
 * @param bitsCount The number of bits in the BitString
 * @return An initialized OFASN1BitString
 */
- (instancetype)initWithBits: (OFData *)bits bitsCount: (size_t)bitsCount;

/**
 * @brief Initializes an already allocated ASN.1 BitString with the specified
 *	  BitString value and length.
 *
 * @param bits The value of the BitString
 * @param bitsCount The number of bits in the BitString
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1BitString
 */
- (instancetype)initWithBits: (OFData *)bits
		   bitsCount: (size_t)bitsCount
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
