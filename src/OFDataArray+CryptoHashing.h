/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFDataArray.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFDataArray_CryptoHashing_reference;
#ifdef __cplusplus
}
#endif

@interface OFDataArray (CryptoHashing)
/*!
 * @brief Returns the MD5 hash of the data array as an autoreleased OFString.
 *
 * @return The MD5 hash of the data array as an autoreleased OFString
 */
- (OFString *)MD5Hash;

/*!
 * @brief Returns the RIPEMD-160 hash of the data array as an autoreleased
 *	  OFString.
 *
 * @return The RIPEMD-160 hash of the data array as an autoreleased OFString
 */
- (OFString *)RIPEMD160Hash;

/*!
 * @brief Returns the SHA-1 hash of the data array as an autoreleased OFString.
 *
 * @return The SHA-1 hash of the data array as an autoreleased OFString
 */
- (OFString *)SHA1Hash;

/*!
 * @brief Returns the SHA-224 hash of the data array as an autoreleased
 *	  OFString.
 *
 * @return The SHA-224 hash of the data array as an autoreleased OFString
 */
- (OFString *)SHA224Hash;

/*!
 * @brief Returns the SHA-256 hash of the data array as an autoreleased
 *	  OFString.
 *
 * @return The SHA-256 hash of the data array as an autoreleased OFString
 */
- (OFString *)SHA256Hash;

/*!
 * @brief Returns the SHA-384 hash of the data array as an autoreleased
 *	  OFString.
 *
 * @return The SHA-384 hash of the data array as an autoreleased OFString
 */
- (OFString *)SHA384Hash;

/*!
 * @brief Returns the SHA-512 hash of the data array as an autoreleased
 *	  OFString.
 *
 * @return The SHA-512 hash of the data array as an autoreleased OFString
 */
- (OFString *)SHA512Hash;
@end

OF_ASSUME_NONNULL_END
