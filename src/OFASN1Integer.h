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
	int64_t _int64Value;
}

/**
 * @brief The Integer value.
 */
@property (readonly, nonatomic) int64_t int64Value;

/**
 * @brief Creates an ASN.1 Integer with the specified integer value.
 *
 * @param value The `int64_t` value of the Integer
 * @return A new, autoreleased OFASN1Integer
 */
+ (instancetype)integerWithInt64: (int64_t)value;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 Integer with the specified
 *	  integer value.
 *
 * @param value The `int64_t` value of the Integer
 * @return An initialized OFASN1Integer
 */
- (instancetype)initWithInt64: (int64_t)value OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
