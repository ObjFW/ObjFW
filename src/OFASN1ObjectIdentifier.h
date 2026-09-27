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

@class OFArray OF_GENERIC(ObjetType);
@class OFNumber;

/**
 * @brief An ASN.1 OBJECT IDENTIFIER.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1ObjectIdentifier: OFPrimitiveASN1Value
/**
 * @brief The arcs of the OBJECT IDENTIFIER.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFNumber *) *arcs;

/**
 * @brief The string value of the OBJECT IDENTIFIER.
 */
@property (readonly, nonatomic) OFString *stringValue;

/**
 * @brief Registers the specified name for identifiers with the specified
 *	  OBJECT IDENTIFIER string value.
 *
 * @param name The name to register for identifiers with the specified OBJECT
 *	       IDENTIFIER string value
 * @param stringValue The string value for which to register the name
 */
+ (void)registerName: (OFString *)name forStringValue: (OFString *)stringValue;

/**
 * @brief Returns the name for identifiers with the specified OBJECT IDENTIFIER
 *	  string value.
 *
 * @return The name for identifiers with the specified OBJECT IDENTIFIER string
 *	   value.
 */
+ (nullable OFString *)nameForStringValue: (OFString *)stringValue;

/**
 * @brief Creates an ASN.1 OBJECT IDENTIFIER with the specified arcs.
 *
 * @param arcs The arcs of the ASN.1 OBJECT IDENTIFIER
 * @return A new, autoreleased OFASN1ObjectIdentifier
 */
+ (instancetype)identifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs;

/**
 * @brief Creates an ASN.1 OBJECT IDENTIFIER with the specified arcs.
 *
 * @param arcs The arcs of the ASN.1 OBJECT IDENTIFIER
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1ObjectIdentifier
 */
+ (instancetype)identifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Creates an ASN.1 OBJECT IDENTIFIER with the specified string.
 *
 * @param string The string value of the ASN.1 OBJECT IDENTIFIER
 * @return A new, autoreleased OFASN1ObjectIdentifier
 */
+ (instancetype)identifierWithString: (OFString *)string;

/**
 * @brief Creates an ASN.1 OBJECT IDENTIFIER with the specified string.
 *
 * @param string The string value of the ASN.1 OBJECT IDENTIFIER
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1ObjectIdentifier
 */
+ (instancetype)identifierWithString: (OFString *)string
			    tagClass: (OFASN1TagClass)tagClass
			   tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 OBJECT IDENTIFIER with the
 *	  specified arcs.
 *
 * @param arcs The arcs of the ASN.1 OBJECT IDENTIFIER
 * @return An initialized OFASN1ObjectIdentifier
 */
- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs;

/**
 * @brief Initializes an already allocated ASN.1 OBJECT IDENTIFIER with the
 *	  specified arcs.
 *
 * @param arcs The arcs of the ASN.1 OBJECT IDENTIFIER
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1ObjectIdentifier
 */
- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber;

/**
 * @brief Initializes an already allocated ASN.1 OBJECT IDENTIFIER with the
 *	  specified string.
 *
 * @param string The string value of the ASN.1 OBJECT IDENTIFIER
 * @return An initialized OFASN1ObjectIdentifier
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated ASN.1 OBJECT IDENTIFIER with the
 *	  specified string.
 *
 * @param string The string value of the ASN.1 OBJECT IDENTIFIER
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1ObjectIdentifier
 */
- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber;
@end

OF_ASSUME_NONNULL_END
