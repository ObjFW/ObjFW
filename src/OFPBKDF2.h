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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFHMAC;

/**
 * @brief The parameters for @ref OFPBKDF2.
 */
typedef struct {
	/** @brief The HMAC to use to derive a key. */
	__unsafe_unretained OFHMAC *HMAC;
	/** @brief The number of iterations to perform. */
	size_t iterations;
	/** @brief The salt to derive a key with. */
	const unsigned char *salt;
	/** @brief The length of the salt. */
	size_t saltLength;
	/** @brief The password to derive a key from. */
	const char *password;
	/** @brief The length of the password. */
	size_t passwordLength;
	/** @brief The buffer to write the key to. */
	unsigned char *key;
	/**
	 * @brief The desired length for the derived key.
	 *
	 * @ref key needs to have enough storage.
	 */
	size_t keyLength;
	/** @brief Whether data may be stored in swappable memory. */
	bool allowsSwappableMemory;
} OFPBKDF2Parameters;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Derives a key from a password and a salt using PBKDF2.
 *
 * @note This will call @ref OFHMAC#reset on the `HMAC` first, making it
 *	 possible to reuse the `HMAC`, but also meaning all previous results
 *	 from the `HMAC` get invalidated if they have not been copied.
 *
 * @param parameters The parameters to use
 */
extern void OFPBKDF2(OFPBKDF2Parameters parameters);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
