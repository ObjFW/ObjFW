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

@class OFString;

/**
 * @brief A base class for ASN.1 text strings types (string types that are not
 *	  binary).
 */
@interface OFASN1TextString: OFPrimitiveASN1Value
{
	OF_RESERVE_IVARS(OFASN1TextString, 4)
}

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates an ASN.1 text string with the specified string value.
 *
 * @note You can only create instances of subclasses of OFASN1String!
 *
 * @param string The string value of the ASN.1 text string
 * @return A new, autoreleased ASN.1 text string
 */
+ (instancetype)stringWithString: (OFString *)string;

/**
 * @brief Creates an ASN.1 text string with the specified string value.
 *
 * @param string The string value of the ASN.1 text string
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased ASN.1 text string
 */
+ (instancetype)stringWithString: (OFString *)string
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 text string with the specified
 *	  string value.
 *
 * @param string The string value of the ASN.1 text string
 * @return An initialized ASN.1 text string
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated ASN.1 text string with the specified
 *	  string value.
 *
 * @param string The string value of the ASN.1 text string
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized ASN.1 text string
 */
- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;
@end

OF_ASSUME_NONNULL_END
