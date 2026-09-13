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
 * @brief An ASN.1 Boolean.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Boolean: OFASN1Value
{
	bool _boolValue;
}

/**
 * @brief The value of the Boolean.
 */
@property (readonly, nonatomic) bool boolValue;

/**
 * @brief Creates an ASN.1 Boolean with the specified Boolean value.
 *
 * @param bool_ The value of the Boolean
 * @return A new, autoreleased OFASN1Boolean
 */
+ (instancetype)booleanWithBool: (bool)bool_;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 Boolean with the specified
 *	  Boolean value.
 *
 * @param bool_ The value of the Boolean
 * @return An initialized OFASN1Boolean
 */
- (instancetype)initWithBool: (bool)bool_ OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
