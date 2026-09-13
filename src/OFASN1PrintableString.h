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

@class OFString;

/**
 * @brief An ASN.1 PrintableString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1PrintableString: OFASN1Value
{
	OFString *_string;
}

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates a PrintableString with the specified string value.
 *
 * @param string The string value of the PrintableString
 * @return A new, autoreleased OFASN1PrintableString
 */
+ (instancetype)stringWithString: (OFString *)string;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated PrintableString with the specified
 *	  string value.
 *
 * @param string The string value of the PrintableString
 * @return An initialized OFASN1PrintableString
 */
- (instancetype)initWithString: (OFString *)string OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
