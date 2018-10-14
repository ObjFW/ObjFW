/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

/*! @file */

@class OFData;

/*!
 * @brief ASN.1 tag class.
 */
typedef enum {
	/*! Universal */
	OF_ASN1_TAG_CLASS_UNIVERSAL	   = 0x0,
	/*! Application */
	OF_ASN1_TAG_CLASS_APPLICATION	   = 0x1,
	/*! Context specific */
	OF_ASN1_TAG_CLASS_CONTEXT_SPECIFIC = 0x2,
	/*! Private */
	OF_ASN1_TAG_CLASS_PRIVATE	   = 0x3
} of_asn1_tag_class_t;

/*!
 * @brief ASN.1 tag number.
 */
typedef enum {
	/*! Boolean */
	OF_ASN1_TAG_NUMBER_BOOLEAN	    = 0x01,
	/*! Integer */
	OF_ASN1_TAG_NUMBER_INTEGER	    = 0x02,
	/*! Bit string */
	OF_ASN1_TAG_NUMBER_BIT_STRING	    = 0x03,
	/*! Octet string */
	OF_ASN1_TAG_NUMBER_OCTET_STRING	    = 0x04,
	/*! Null */
	OF_ASN1_TAG_NUMBER_NULL		    = 0x05,
	/*! Enumerated */
	OF_ASN1_TAG_NUMBER_ENUMERATED	    = 0x0A,
	/*! UTF-8 string */
	OF_ASN1_TAG_NUMBER_UTF8_STRING	    = 0x0C,
	/*! Sequence */
	OF_ASN1_TAG_NUMBER_SEQUENCE	    = 0x10,
	/*! Set */
	OF_ASN1_TAG_NUMBER_SET		    = 0x11,
	/*! NumericString */
	OF_ASN1_TAG_NUMBER_NUMERIC_STRING   = 0x12,
	/*! PrintableString */
	OF_ASN1_TAG_NUMBER_PRINTABLE_STRING = 0x13,
	/*! IA5String */
	OF_ASN1_TAG_NUMBER_IA5_STRING	    = 0x16
} of_asn1_tag_number_t;

/*!
 * @brief A class representing an ASN.1 value.
 */
@interface OFASN1Value: OFObject <OFCopying>
{
	of_asn1_tag_class_t _tagClass;
	of_asn1_tag_number_t _tagNumber;
	bool _constructed;
	OFData *_DEREncodedContents;
}

/*!
 * @brief The tag class of the value's type.
 */
@property (readonly, nonatomic) of_asn1_tag_class_t tagClass;

/*!
 * @brief The tag number of the value's type.
 */
@property (readonly, nonatomic) of_asn1_tag_number_t tagNumber;

/*!
 * @brief Whether the value if of a constructed type.
 */
@property (readonly, nonatomic, getter=isConstructed) bool constructed;

/*!
 * @brief The DER-encoded contents octets of the value.
 */
@property (readonly, nonatomic) OFData *DEREncodedContents;

/*!
 * @brief Creates a new ASN.1 value with the specified arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return A new ASN.1 value
 */
+ (instancetype)valueWithTagClass: (of_asn1_tag_class_t)tagClass
			tagNumber: (of_asn1_tag_number_t)tagNumber
		      constructed: (bool)constructed
	       DEREncodedContents: (OFData *)DEREncodedContents;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated ASN.1 value with the specified
 *	  arguments.
 *
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @param constructed Whether the value if of a constructed type
 * @param DEREncodedContents The DER-encoded contents octets of the value.
 * @return An initialized ASN.1 value
 */
- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
