/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @protocol OFCryptoHash OFCryptoHash.h ObjFW/OFCryptoHash.h
 *
 * @brief A protocol for classes providing cryptographic hash functions.
 */
@protocol OFCryptoHash <OFObject>
/*!
 * A boolean whether the hash has already been calculated.
 */
@property (readonly, getter=isCalculated) bool calculated;

/*!
 * @brief Creates a new cryptographic hash.
 *
 * @return A new autoreleased OFCryptoHash
 */
+ (instancetype)cryptoHash;

/*!
 * @brief Returns the digest size of the cryptographic hash, in bytes.
 *
 * @return The digest size of the cryptographic hash, in bytes
 */
+ (size_t)digestSize;

/*!
 * @brief Returns the block size of the cryptographic hash, in bytes.
 *
 * @return The block size of the cryptographic hash, in bytes
 */
+ (size_t)blockSize;

/*!
 * @brief Adds a buffer to the cryptographic hash to be calculated.
 *
 * @param buffer The buffer which should be included into the calculation
 * @param length The length of the buffer
 */
- (void)updateWithBuffer: (const void*)buffer
		  length: (size_t)length;

/*!
 * @brief Returns a buffer containing the cryptographic hash.
 *
 * The size of the buffer depends on the hash used. The buffer is part of the
 * receiver's memory pool.
 *
 * @return A buffer containing the hash
 */
- (const unsigned char*)digest OF_RETURNS_INNER_POINTER;

/*!
 * @brief Resets all state so that a new hash can be calculated.
 *
 * @warning This invalidates any pointer previously returned by @ref digest. If
 *	    you are still interested in the previous digest, you need to memcpy
 *	    it yourself before calling @ref reset!
 */
- (void)reset;
@end

OF_ASSUME_NONNULL_END
