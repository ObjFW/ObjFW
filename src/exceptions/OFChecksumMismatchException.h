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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFChecksumMismatchException \
 *	  OFChecksumMismatchException.h ObjFW/OFChecksumMismatchException.h
 *
 * @brief An exception indicating that a checksum did not match.
 */
@interface OFChecksumMismatchException: OFException
{
	OFString *_actualChecksum, *_expectedChecksum;
}

/*!
 * @brief The actual checksum calculated.
 */
@property (readonly, nonatomic) OFString *actualChecksum;

/*!
 * @brief The expected checksum.
 */
@property (readonly, nonatomic) OFString *expectedChecksum;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased checksum mismatch exception.
 *
 * @param actualChecksum The actual checksum calculated
 * @param expectedChecksum The expected checksum
 * @return A new, autoreleased checksum mismatch exception.
 */
+ (instancetype)exceptionWithActualChecksum: (OFString *)actualChecksum
			   expectedChecksum: (OFString *)expectedChecksum;

- (instancetype)init OF_UNAVAILABLE;

/*!
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
