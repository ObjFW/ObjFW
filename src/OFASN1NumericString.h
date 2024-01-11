/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
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
