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
	OFData *_data;
	size_t _bitLength;
}

/**
 * @brief The BitString value.
 */
@property (readonly, nonatomic) OFData *data;

/**
 * @brief The length of the BitString in bits.
 */
@property (readonly, nonatomic) size_t bitLength;

/**
 * @brief Creates an ASN.1 BitString with the specified BitString value and
 *	  length.
 *
 * @param data The value of the BitString
 * @param bitLength The length of the BitString in bits
 * @return A new, autoreleased OFASN1BitString
 */
+ (instancetype)bitStringWithData: (OFData *)data bitLength: (size_t)bitLength;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 BitString with the specified
 *	  BitString value and length.
 *
 * @param data The value of the BitString
 * @param bitLength The length of the BitString in bits
 * @return An initialized OFASN1BitString
 */
- (instancetype)initWithData: (OFData *)data
		   bitLength: (size_t)bitLength OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
