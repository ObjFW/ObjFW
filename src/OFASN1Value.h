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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFData;

/**
 * @brief ASN.1 tag class.
 */
typedef enum {
	/** Universal */
	OFASN1TagClassUniversal	      = 0,
	/** Application */
	OFASN1TagClassApplication     = 1,
	/** Context specific */
	OFASN1TagClassContextSpecific = 2,
	/** Private */
	OFASN1TagClassPrivate	      = 3
} OFASN1TagClass;

/**
 * @brief ASN.1 tag number.
 */
typedef enum {
	/** Boolean */
	OFASN1TagNumberBoolean		= 1,
	/** Integer */
	OFASN1TagNumberInteger		= 2,
	/** Bit string */
	OFASN1TagNumberBitString	= 3,
	/** Octet string */
	OFASN1TagNumberOctetString	= 4,
	/** Null */
	OFASN1TagNumberNull		= 5,
	/** Object Identifier */
	OFASN1TagNumberObjectIdentifier	= 6,
	/** Enumerated */
	OFASN1TagNumberEnumerated	= 10,
	/** UTF-8 string */
	OFASN1TagNumberUTF8String	= 12,
	/** Sequence */
	OFASN1TagNumberSequence		= 16,
	/** Set */
	OFASN1TagNumberSet		= 17,
	/** NumericString */
	OFASN1TagNumberNumericString	= 18,
	/** PrintableString */
	OFASN1TagNumberPrintableString	= 19,
	/** IA5String */
	OFASN1TagNumberIA5String	= 22,
	/** VisibleString */
	OFASN1TagNumberVisibleString    = 26,
	/** UniversalString */
	OFASN1TagNumberUniversalString  = 28,
	/** BMPString */
	OFASN1TagNumberBMPString        = 30
} OFASN1TagNumber;

/**
 * @brief A class representing an abstract ASN.1 value.
 */
@interface OFASN1Value: OFObject <OFComparing>
{
	OFASN1TagClass _tagClass;
	OFASN1TagNumber _tagNumber;
	OF_RESERVE_IVARS(OFASN1Value, 4)
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
 * @brief The object in DER representation.
 */
@property (readonly, nonatomic) OFData *DERRepresentation;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated ASN.1 value with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized ASN.1 value
 */
- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Compares the ASN.1 value to another ASN.1 value.
 *
 * @param value The ASN.1 value to compare to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (OFASN1Value *)value;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns a description for the specified @ref OFASN1TagClass.
 *
 * @param tagClass The tag class to return a description for
 * @return A description for the specified @ref OFASN1TagClass
 */
extern OFString *_Nonnull OFASN1TagClassDescription(OFASN1TagClass tagClass);

/**
 * @brief Returns a description for the specified @ref OFASN1TagNumber.
 *
 * @param tagClass The tag class to which the tag number belongs
 * @param tagNumber The tag number to return a description for
 * @return A description for the specified @ref OFASN1TagNumber
 */
extern OFString *_Nonnull OFASN1TagNumberDescription(OFASN1TagClass tagClass,
    OFASN1TagNumber tagNumber);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
