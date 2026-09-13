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

@class OFData;

/**
 * @brief An ASN.1 OctetString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1OctetString: OFASN1Value
{
	OFData *_data;
}

/**
 * @brief The OctetString value.
 */
@property (readonly, nonatomic) OFData *dataValue;

/**
 * @brief Creates an OctetString with the specified value.
 *
 * @param data The OctetString value
 * @return A new, autoreleased OFASN1OctetString
 */
+ (instancetype)octetStringWithData: (OFData *)data;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OctetString with the specified
 *	  value.
 *
 * @param data The OctetString value
 * @return An initialized OFASN1OctetString
 */
- (instancetype)initWithData: (OFData *)data OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
