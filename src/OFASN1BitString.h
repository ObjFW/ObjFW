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
#import "OFASN1DERRepresentation.h"
#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @brief An ASN.1 BitString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1BitString: OFObject <OFASN1DERRepresentation>
{
	OFData *_bitStringValue;
	size_t _bitStringLength;
}

/**
 * @brief The BitString value.
 */
@property (readonly, nonatomic) OFData *bitStringValue;

/**
 * @brief The length of the BitString in bits.
 */
@property (readonly, nonatomic) size_t bitStringLength;

/**
 * @brief Creates an ASN.1 BitString with the specified BitString value and
 *	  length.
 *
 * @param bitString The value of the BitString
 * @param length The length of the BitString in bits
 * @return A new, autoreleased OFASN1BitString
 */
+ (instancetype)bitStringWithBitString: (OFData *)bitString
				length: (size_t)length;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 BitString with the specified
 *	  BitString value and length.
 *
 * @param bitString The value of the BitString
 * @param length The length of the BitString in bits
 * @return An initialized OFASN1BitString
 */
- (instancetype)initWithBitString: (OFData *)bitString
			   length: (size_t)length OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated ASN.1 BitString with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized OFASN1BitString
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents;
@end

OF_ASSUME_NONNULL_END
