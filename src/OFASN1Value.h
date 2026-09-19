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
	/** UNIVERSAL */
	OFASN1TagClassUniversal	      = 0,
	/** APPLICATION */
	OFASN1TagClassApplication     = 1,
	/** Context-specific */
	OFASN1TagClassContextSpecific = 2,
	/** PRIVATE */
	OFASN1TagClassPrivate	      = 3
} OFASN1TagClass;

/**
 * @brief ASN.1 tag number.
 */
typedef enum {
	/** BOOLEAN */
	OFASN1TagNumberBoolean		=  1,
	/** INTEGER */
	OFASN1TagNumberInteger		=  2,
	/** BIT STRING */
	OFASN1TagNumberBitString	=  3,
	/** OCTET STRING */
	OFASN1TagNumberOctetString	=  4,
	/** NULL */
	OFASN1TagNumberNull		=  5,
	/** OBJECT IDENTIFIER */
	OFASN1TagNumberObjectIdentifier =  6,
	/** ObjectDescriptor */
	OFASN1TagNumberObjectDescriptor =  7,
	/** EXTERNAL */
	OFASN1TagNumberExternal         =  8,
	/** REAL */
	OFASN1TagNumberReal             =  9,
	/** ENUMERATED */
	OFASN1TagNumberEnumerated       = 10,
	/** EMBEDDED PDV */
	OFASN1TagNumberEmbeddedPDV      = 11,
	/** UTF8String */
	OFASN1TagNumberUTF8String       = 12,
	/** RELATIVE-OID */
	OFASN1TagNumberRelativeOID      = 13,
	/** TIME */
	OFASN1TagNumberTime             = 14,
	/** SEQUENCE */
	OFASN1TagNumberSequence         = 16,
	/** SET */
	OFASN1TagNumberSet              = 17,
	/** NumericString */
	OFASN1TagNumberNumericString    = 18,
	/** PrintableString */
	OFASN1TagNumberPrintableString  = 19,
	/** TeletexString */
	OFASN1TagNumberTeletexString    = 20,
	/** VideotexString */
	OFASN1TagNumberVideotexString   = 21,
	/** IA5String */
	OFASN1TagNumberIA5String        = 22,
	/** UTCTime */
	OFASN1TagNumberUTCTime          = 23,
	/** GeneralizedTime */
	OFASN1TagNumberGeneralizedTime  = 24,
	/** GraphicString */
	OFASN1TagNumberGraphicString    = 25,
	/** VisibleString */
	OFASN1TagNumberVisibleString    = 26,
	/** GeneralString */
	OFASN1TagNumberGeneralString    = 27,
	/** UniversalString */
	OFASN1TagNumberUniversalString  = 28,
	/** CHARACTER STRING */
	OFASN1TagNumberCharacterString  = 29,
	/** BMPString */
	OFASN1TagNumberBMPString        = 30,
	/** DATE */
	OFASN1TagNumberDate             = 31,
	/** TIME-OF-DAY */
	OFASN1TagNumberTimeOfDay        = 32,
	/** DATE-TIME */
	OFASN1TagNumberDateTime         = 33,
	/** DURATION */
	OFASN1TagNumberDuration         = 34
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
