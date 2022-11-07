/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

/**
 * @protocol OFCryptographicHash \
 *	     OFCryptographicHash.h ObjFW/OFCryptographicHash.h
 *
 * @brief A protocol for classes providing cryptographic hash functions.
 *
 * A cryptographic hash implementing this protocol can be copied. The entire
 * state is copied, allowing to calculate a new hash from there. This is
 * especially useful for generating many hashes with a common prefix.
 */
@protocol OFCryptographicHash <OFObject, OFCopying>
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) size_t digestSize;
@property (class, readonly, nonatomic) size_t blockSize;
#endif

/**
 * @brief The digest size of the cryptographic hash, in bytes.
 */
@property (readonly, nonatomic) size_t digestSize;

/**
 * @brief The block size of the cryptographic hash, in bytes.
 */
@property (readonly, nonatomic) size_t blockSize;

/**
 * @brief Whether data may be stored in swappable memory.
 */
@property (readonly, nonatomic) bool allowsSwappableMemory;

/**
 * @brief A boolean whether the hash has already been calculated.
 */
@property (readonly, nonatomic, getter=isCalculated) bool calculated;

/**
 * @brief A buffer containing the cryptographic hash.
 *
 * The size of the buffer depends on the hash used. The buffer is part of the
 * receiver's memory pool.
 *
 * @throw OFHashNotCalculatedException The hash hasn't been calculated yet
 */
@property (readonly, nonatomic) const unsigned char *digest
    OF_RETURNS_INNER_POINTER;

/**
 * @brief Creates a new cryptographic hash.
 *
 * @return A new autoreleased cryptographic hash
 */
+ (instancetype)hashWithAllowsSwappableMemory: (bool)allowsSwappableMemory;

/**
 * @brief Returns the digest size of the cryptographic hash, in bytes.
 *
 * @return The digest size of the cryptographic hash, in bytes
 */
+ (size_t)digestSize;

/**
 * @brief Returns the block size of the cryptographic hash, in bytes.
 *
 * @return The block size of the cryptographic hash, in bytes
 */
+ (size_t)blockSize;

/**
 * @brief Initializes an already allocated cryptographic hash.
 *
 * @return An initialized cryptographic hash
 */
- (instancetype)initWithAllowsSwappableMemory: (bool)allowsSwappableMemory;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Adds a buffer to the cryptographic hash to be calculated.
 *
 * @param buffer The buffer which should be included into the calculation
 * @param length The length of the buffer
 * @throw OFHashAlreadyCalculatedException The hash has already been calculated
 */
- (void)updateWithBuffer: (const void *)buffer length: (size_t)length;

/**
 * @brief Performs the final calculation of the cryptographic hash.
 *
 * @throw OFHashAlreadyCalculatedException The hash has already been calculated
 */
- (void)calculate;

/**
 * @brief Resets all state so that a new hash can be calculated.
 *
 * @warning This invalidates any pointer previously returned by @ref digest. If
 *	    you are still interested in the previous digest, you need to memcpy
 *	    it yourself before calling @ref reset!
 */
- (void)reset;
@end

OF_ASSUME_NONNULL_END
