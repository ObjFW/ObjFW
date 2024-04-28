/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@class OFString;

/**
 * @class OFUUID OFUUID.h ObjFW/OFUUID.h
 *
 * @brief A UUID conforming to RFC 4122.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFUUID: OFObject <OFCopying, OFComparing>
{
	unsigned char _bytes[16];
}

/**
 * @brief The UUID as a string.
 */
@property (readonly, nonatomic) OFString *UUIDString;

/**
 * @brief Creates a new random UUID as per RFC 4122 version 4.
 *
 * @return A new, autoreleased OFUUID
 */
+ (instancetype)UUID;

/**
 * @brief Creates a new UUID with the specified bytes.
 *
 * @param bytes The bytes for the UUID
 * @return A new, autoreleased OFUUID
 */
+ (instancetype)UUIDWithUUIDBytes: (const unsigned char [_Nonnull 16])bytes;

/**
 * @brief Creates a new UUID with the specified UUID string.
 *
 * @param string The UUID string for the UUID
 * @return A new, autoreleased OFUUID
 * @throw OFInvalidFormatException The specified string is not a valid UUID
 *				   string
 */
+ (instancetype)UUIDWithUUIDString: (OFString *)string;

/**
 * @brief Initializes an already allocated OFUUID as a new random UUID as per
 *	  RFC 4122 version 4.
 *
 * @return An initialized OFUUID
 */
- (instancetype)init;

/**
 * @brief Initializes an already allocated OFUUID with the specified bytes.
 *
 * @param bytes The bytes to initialize the OFUUID with
 * @return An initialized OFUUID
 */
- (instancetype)initWithUUIDBytes: (const unsigned char [_Nonnull 16])bytes;

/**
 * @brief Initializes an already allocated OFUUID with the specified UUID
 *	  string.
 *
 * @param string The UUID string to initialize the OFUUID with
 * @return An initialized OFUUID
 * @throw OFInvalidFormatException The specified string is not a valid UUID
 *				   string
 */
- (instancetype)initWithUUIDString: (OFString *)string;

/**
 * @brief Compares the UUID to another UUID.
 *
 * @param UUID The UUID to compare to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (OFUUID *)UUID;

/**
 * @brief Gets the bytes of the UUID.
 *
 * @param bytes An array of 16 bytes into which to write the UUID
 */
- (void)getUUIDBytes: (unsigned char [_Nonnull 16])bytes;
@end

OF_ASSUME_NONNULL_END
