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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief An ASN.1 Integer.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Integer: OFASN1Value
{
	OFData *_rawValue;
}

/**
 * @brief The int64 value of the Integer.
 *
 * @throws OFOutOfRangeException The Integer does not fit into an int64
 */
@property (readonly, nonatomic) int64_t int64Value;

/**
 * @brief The raw value of the Integer.
 */
@property (readonly, nonatomic) OFData *rawValue;

/**
 * @brief Creates an ASN.1 Integer with the specified int64.
 *
 * @param value The `int64_t` value of the Integer
 * @return A new, autoreleased OFASN1Integer
 */
+ (instancetype)integerWithInt64: (int64_t)value;

/**
 * @brief Creates an ASN.1 Integer with the specified int64.
 *
 * @param value The `int64_t` value of the Integer
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1Integer
 */
+ (instancetype)integerWithInt64: (int64_t)value
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Creates an ASN.1 Integer with the specified raw value.
 *
 * @param rawValue The raw value of the Integer
 * @return A new, autoreleased OFASN1Integer
 */
+ (instancetype)integerWithRawValue: (OFData *)rawValue;

/**
 * @brief Creates an ASN.1 Integer with the specified raw value.
 *
 * @param rawValue The raw value of the Integer
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1Integer
 */
+ (instancetype)integerWithRawValue: (OFData *)rawValue
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 Integer with the specified
 *	  int64.
 *
 * @param value The `int64_t` value of the Integer
 * @return An initialized OFASN1Integer
 */
- (instancetype)initWithInt64: (int64_t)value;

/**
 * @brief Initializes an already allocated ASN.1 Integer with the specified
 *	  int64 value.
 *
 * @param value The `int64_t` value of the Integer
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1Integer
 */
- (instancetype)initWithInt64: (int64_t)value
		     tagClass: (OFASN1TagClass)tagClass
		    tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 Integer with the specified
 *	  raw value.
 *
 * @param rawValue The raw value of the Integer
 * @return An initialized OFASN1Integer
 */
- (instancetype)initWithRawValue: (OFData *)rawValue;

/**
 * @brief Initializes an already allocated ASN.1 Integer with the specified
 *	  raw value.
 *
 * @param rawValue The raw value of the Integer
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1Integer
 */
- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
