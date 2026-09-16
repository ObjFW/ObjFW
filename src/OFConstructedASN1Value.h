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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);

/**
 * @brief A constructed ASN.1 value.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFConstructedASN1Value: OFASN1Value
{
	OFArray OF_GENERIC(OF_KINDOF(OFASN1Value *)) *_components;
}

/**
 * @brief The components of the constructed ASN.1 value.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OF_KINDOF(OFASN1Value *))
    *components;

/**
 * @brief Creates a constructed ASN.1 value with the specified components.
 *
 * @param components The components of the constructed ASN.1 value
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFConstructedASN1Value
 */
+ (instancetype)valueWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					 OFASN1Value *)) *)components
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated constructed ASN.1 value with the
 *	  specified components.
 *
 * @param components The components of the constructed ASN.1 value
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFConstructedASN1Value
 */
- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns the constructed ASN.1 value parsed as a value of the specified
 *	  class.
 *
 * @param class_ The class to parse the value as
 * @return The constructed ASN.1 value parsed as a value of the specified class
 */
- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class_;
@end

OF_ASSUME_NONNULL_END
