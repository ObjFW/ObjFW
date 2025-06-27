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

#import "OFObject.h"
#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @brief An ASN.1 NumericString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1NumericString: OFObject
{
	OFString *_numericStringValue;
}

/**
 * @brief The NumericString value.
 */
@property (readonly, nonatomic) OFString *numericStringValue;

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates an NumericString with the specified string value.
 *
 * @param string The string value of the NumericString
 * @return A new, autoreleased OFASN1NumericString
 */
+ (instancetype)stringWithString: (OFString *)string;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated NumericString with the specified
 *	  string value.
 *
 * @param string The string value of the NumericString
 * @return An initialized OFASN1NumericString
 */
- (instancetype)initWithString: (OFString *)string OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated ASN.1 NumericString with the
 *	  specified arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized ASN.1 NumericString
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents;
@end

OF_ASSUME_NONNULL_END
