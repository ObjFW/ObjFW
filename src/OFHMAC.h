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
#import "OFCryptoHash.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFHMAC OFHMAC.h ObjFW/OFHMAC.h
 *
 * @brief A class which provides methods to calculate an HMAC.
 */
@interface OFHMAC: OFObject
{
	Class <OFCryptoHash> _hashClass;
	id <OFCryptoHash> _outerHash, _innerHash;
	id <OFCryptoHash> _outerHashCopy, _innerHashCopy;
	bool _calculated;
}

/*! The class for the cryptographic hash used by the HMAC. */
@property (assign, readonly) Class <OFCryptoHash> hashClass;

/*!
 * @brief Returns a new OFHMAC with the specified hashing algorithm.
 *
 * @param class The class of the hashing algorithm
 * @return A new, autoreleased OFHMAC
 */
+ (instancetype)HMACWithHashClass: (Class <OFCryptoHash>)class;

/*!
 * @brief Initialized an already allocated OFHMAC with the specified hashing
 *	  algorithm.
 *
 * @param class The class of the hashing algorithm
 * @return An initialized OFHMAC
 */
- initWithHashClass: (Class <OFCryptoHash>)class;

/*!
 * @brief Sets the key for the HMAC.
 *
 * @note This resets the HMAC!
 *
 * @warning This invalidates any pointer previously returned by @ref digest. If
 *	    you are still interested in the previous digest, you need to memcpy
 *	    it yourself before calling @ref setKey:length:!
 *
 * @param key The key for the HMAC
 * @param length The length of the key for the HMAC
 */
- (void)setKey: (const void*)key
	length: (size_t)length;

/*!
 * @brief Adds a buffer to the HMAC to be calculated.
 *
 * @param buffer The buffer which should be included into the calculation
 * @param length The length of the buffer
 */
- (void)updateWithBuffer: (const void*)buffer
		  length: (size_t)length;

/*!
 * @brief Returns a buffer containing the HMAC.
 *
 * The size of the buffer depends on the hash used. The buffer is part of the
 * receiver's memory pool.
 *
 * @return A buffer containing the hash
 */
- (const unsigned char*)digest OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the size of the digest.
 *
 * @return The size of the digest.
 */
- (size_t)digestSize;

/*!
 * @brief Resets the HMAC so that it can be calculated for a new message.
 *
 * @note This does not reset the key so that a new HMAC with the same key can
 *	 be calculated efficiently. If you want to reset both, use
 *	 @ref setKey:length:.
 *
 * @warning This invalidates any pointer previously returned by @ref digest. If
 *	    you are still interested in the previous digest, you need to memcpy
 *	    it yourself before calling @ref reset!
 */
- (void)reset;
@end

OF_ASSUME_NONNULL_END
