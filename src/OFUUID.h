/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFUUID OFUUID.h ObjFW/OFUUID.h
 *
 * @brief A UUID conforming to RFC 4122.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFUUID: OFObject <OFCopying, OFComparing, OFSerialization>
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
