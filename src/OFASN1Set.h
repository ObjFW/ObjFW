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

@class OFCountedSet OF_GENERIC(ObjectType);

/**
 * @brief An ASN.1 Set.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Set: OFASN1Value
{
	OFCountedSet OF_GENERIC(OF_KINDOF(OFASN1Value *)) *_components;
}

/**
 * @brief The components of the Set.
 */
@property (readonly, nonatomic) OFCountedSet OF_GENERIC(OF_KINDOF(
    OFASN1Value *)) *components;

/**
 * @brief Creates a Set with the specified components.
 *
 * @param components The components of the Set
 * @return A new, autoreleased OFASN1Set
 */
+ (instancetype)setWithComponents:
    (OFCountedSet OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)components;

/**
 * @brief Creates a Set with the specified components.
 *
 * @param components The components of the Set
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return A new, autoreleased OFASN1Set
 */
+ (instancetype)setWithComponents: (OFCountedSet OF_GENERIC(OF_KINDOF(
				       OFASN1Value *)) *)components
			 tagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated Set with the specified components.
 *
 * @param components The components of the Set
 * @return An initialized OFASN1Set
 */
- (instancetype)initWithComponents:
    (OFCountedSet OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)components;

/**
 * @brief Initializes an already allocated Set with the specified components.
 *
 * @param components The components of the Set
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1Set
 */
- (instancetype)initWithComponents: (OFCountedSet OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
