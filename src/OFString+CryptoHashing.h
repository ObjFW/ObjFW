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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_CryptoHashing_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (CryptoHashing)
/*!
 * The MD5 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *MD5Hash;

/*!
 * The RIPEMD-160 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *RIPEMD160Hash;

/*!
 * The SHA-1 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *SHA1Hash;

/*!
 * The SHA-224 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *SHA224Hash;

/*!
 * The SHA-256 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *SHA256Hash;

/*!
 * The SHA-384 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *SHA384Hash;

/*!
 * The SHA-512 hash of the string as a string.
 */
@property (readonly, nonatomic) OFString *SHA512Hash;
@end

OF_ASSUME_NONNULL_END
