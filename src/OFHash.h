/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

/**
 * \brief A base class for classes providing hash functions.
 */
@interface OFHash: OFObject
{
	BOOL	 isCalculated;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) BOOL isCalculated;
#endif

/**
 * \brief Returns the digest size of the hash, in bytes.
 *
 * \return The digest size of the hash, in bytes
 */
+ (size_t)digestSize;

/**
 * \brief Returns the block size of the hash, in bytes.
 *
 * \return The block size of the hash, in bytes
 */
+ (size_t)blockSize;

/**
 * \brief Adds a buffer to the hash to be calculated.
 *
 * \param buf The buffer which should be included into the calculation.
 * \param length The length of the buffer
 */
- (void)updateWithBuffer: (const char*)buf
		  length: (size_t)length;

/**
 * \brief Returns a buffer containing the hash.
 *
 * The size of the buffer depends on the hash used. The buffer is part of the
 * receiver's memory pool.
 *
 * \return A buffer containing the hash
 */
- (uint8_t*)digest;

/**
 * \brief Returns a boolean whether the hash has already been calculated.
 *
 * \return A boolean whether the hash has already been calculated
 */
- (BOOL)isCalculated;
@end
