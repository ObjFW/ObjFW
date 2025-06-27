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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFChecksumMismatchException OFChecksumMismatchException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a checksum did not match.
 */
@interface OFChecksumMismatchException: OFException
{
	OFString *_actualChecksum, *_expectedChecksum;
	OF_RESERVE_IVARS(OFChecksumMismatchException, 4)
}

/**
 * @brief The actual checksum calculated.
 */
@property (readonly, nonatomic) OFString *actualChecksum;

/**
 * @brief The expected checksum.
 */
@property (readonly, nonatomic) OFString *expectedChecksum;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased checksum mismatch exception.
 *
 * @param actualChecksum The actual checksum calculated
 * @param expectedChecksum The expected checksum
 * @return A new, autoreleased checksum mismatch exception.
 */
+ (instancetype)exceptionWithActualChecksum: (OFString *)actualChecksum
			   expectedChecksum: (OFString *)expectedChecksum;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated checksum mismatch exception.
 *
 * @param actualChecksum The actual checksum calculated
 * @param expectedChecksum The expected checksum
 * @return An initialized checksum mismatch exception.
 */
- (instancetype)initWithActualChecksum: (OFString *)actualChecksum
		      expectedChecksum: (OFString *)expectedChecksum
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
