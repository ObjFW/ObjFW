/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_CryptographicHashing_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

@interface OFData (CryptographicHashing)
/**
 * @brief The MD5 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringByMD5Hashing;

/**
 * @brief The RIPEMD-160 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringByRIPEMD160Hashing;

/**
 * @brief The SHA-1 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA1Hashing;

/**
 * @brief The SHA-224 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA224Hashing;

/**
 * @brief The SHA-256 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA256Hashing;

/**
 * @brief The SHA-384 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA384Hashing;

/**
 * @brief The SHA-512 hash of the data as a string.
 */
@property (readonly, nonatomic) OFString *stringBySHA512Hashing;
@end

OF_ASSUME_NONNULL_END
