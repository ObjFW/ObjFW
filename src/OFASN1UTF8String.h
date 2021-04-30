/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
 * @brief An ASN.1 UTF8String.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1UTF8String: OFObject
{
	OFString *_UTF8StringValue;
}

/**
 * @brief The UTF8String value.
 */
@property (readonly, nonatomic) OFString *UTF8StringValue;

/**
 * @brief The string value.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Creates a UTF8String with the specified string value.
 *
 * @param string The string value of the UTF8String
 * @return A new, autoreleased OFASN1UTF8String
 */
+ (instancetype)stringWithString: (OFString *)string;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated UTF8String with the specified
 *	  string value.
 *
 * @param string The string value of the UTF8String
 * @return An initialized OFASN1UTF8String
 */
- (instancetype)initWithString: (OFString *)string OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated ASN.1 UTF8String with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized OFASN1UTF8String
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents;
@end

OF_ASSUME_NONNULL_END
