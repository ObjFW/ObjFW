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
#import "OFCharacterSet.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @brief An ASN.1 IA5String.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1IA5String: OFASN1Value
{
	OFString *_string;
}

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates an IA5String with the specified string value.
 *
 * @param string The string value of the IA5String
 * @return A new, autoreleased OFASN1IA5String
 */
+ (instancetype)stringWithString: (OFString *)string;

/**
 * @brief Creates an IA5String with the specified string value.
 *
 * @param string The string value of the IA5String
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1IA5String
 */
+ (instancetype)stringWithString: (OFString *)string
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated IA5String with the specified string
 *	  value.
 *
 * @param string The string value of the IA5String
 * @return An initialized OFASN1IA5String
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated IA5String with the specified string
 *	  value.
 *
 * @param string The string value of the IA5String
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1IA5String
 */
- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;
@end

@interface OFCharacterSet (ASN1IA5StringCharacterSet)
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFCharacterSet *ASN1IA5StringCharacterSet;
#endif

/**
 * @brief Returns the characters allowed in an OFASN1IA5String.
 *
 * @return The characters allowed in an OFASN1IA5String
 */
+ (OFCharacterSet *)ASN1IA5StringCharacterSet;
@end

OF_ASSUME_NONNULL_END
