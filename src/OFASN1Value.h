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

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFData;

/**
 * @brief ASN.1 tag class.
 */
typedef enum {
	/** Universal */
	OFASN1TagClassUniversal	      = 0x0,
	/** Application */
	OFASN1TagClassApplication     = 0x1,
	/** Context specific */
	OFASN1TagClassContextSpecific = 0x2,
	/** Private */
	OFASN1TagClassPrivate	      = 0x3
} OFASN1TagClass;

/**
 * @brief ASN.1 tag number.
 */
typedef enum {
	/** Boolean */
	OFASN1TagNumberBoolean		= 0x01,
	/** Integer */
	OFASN1TagNumberInteger		= 0x02,
	/** Bit string */
	OFASN1TagNumberBitString	= 0x03,
	/** Octet string */
	OFASN1TagNumberOctetString	= 0x04,
	/** Null */
	OFASN1TagNumberNull		= 0x05,
	/** Object Identifier */
	OFASN1TagNumberObjectIdentifier	= 0x06,
	/** Enumerated */
	OFASN1TagNumberEnumerated	= 0x0A,
	/** UTF-8 string */
	OFASN1TagNumberUTF8String	= 0x0C,
	/** Sequence */
	OFASN1TagNumberSequence		= 0x10,
	/** Set */
	OFASN1TagNumberSet		= 0x11,
	/** NumericString */
	OFASN1TagNumberNumericString	= 0x12,
	/** PrintableString */
	OFASN1TagNumberPrintableString	= 0x13,
	/** IA5String */
	OFASN1TagNumberIA5String	= 0x16
} OFASN1TagNumber;

/**
 * @brief A class representing an ASN.1 value.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Value: OFObject
{
	OFASN1TagClass _tagClass;
	OFASN1TagNumber _tagNumber;
	bool _constructed;
	OFData *_DEREncodedContents;
}

/**
 * @brief The tag class of the value's type.
 */
@property (readonly, nonatomic) OFASN1TagClass tagClass;

/**
 * @brief The tag number of the value's type.
 */
@property (readonly, nonatomic) OFASN1TagNumber tagNumber;

/**
 * @brief Whether the value if of a constructed type.
 */
@property (readonly, nonatomic, getter=isConstructed) bool constructed;

/**
 * @brief The DER-encoded contents octets of the value.
 */
@property (readonly, nonatomic) OFData *DEREncodedContents;

/**
 * @brief Creates a new ASN.1 value with the specified arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return A new ASN.1 value
 */
+ (instancetype)valueWithTagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber
		      constructed: (bool)constructed
	       DEREncodedContents: (OFData *)DEREncodedContents;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 value with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized ASN.1 value
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
