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

#import "OFPrimitiveASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class representing an ASN.1 Null.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Null: OFPrimitiveASN1Value
/**
 * @brief Creates an ASN.1 Null.
 *
 * @return A new, autoreleased OFASN1Null
 */
+ (instancetype)null;

/**
 * @brief Creates an ASN.1 Null.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1Null
 */
+ (instancetype)nullWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 Null.
 *
 * @return An initialized OFASN1Null
 */
- (instancetype)init;

/**
 * @brief Initializes an already allocated ASN.1 Null.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1Null
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber;
@end

OF_ASSUME_NONNULL_END
