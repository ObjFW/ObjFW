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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class representing an primitive ASN.1 value.
 */
@interface OFPrimitiveASN1Value: OFASN1Value
{
	OFData *_rawValue;
	OF_RESERVE_IVARS(OFPrimitiveASN1Value, 4)
}

/**
 * @brief The raw value.
 */
@property (readonly, nonatomic) OFData *rawValue;

/**
 * @brief Initializes an already allocated primitive ASN.1 value with the
 *	  specified raw value.
 *
 * @param rawValue The raw value
 * @param tagClass The tag class of the value's type
 * @param tagNumber The tag number of the value's type
 * @return An initialized OFASN1PrimitiveValue
 */
- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
    OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Returns the primitive ASN.1 value parsed as a value of the specified
 *	  class.
 *
 * @param class_ The class to parse the value as
 * @return The primitive ASN.1 value parsed as a value of the specified class
 */
- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class_;
@end

OF_ASSUME_NONNULL_END
