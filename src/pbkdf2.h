/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
 * @brief The parameters for @ref of_pbkdf2.
 */
typedef struct of_pbkdf2_parameters_t {
	/** @brief The HMAC to use to derive a key. */
	OFHMAC *HMAC;
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
} of_pbkdf2_parameters_t;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Derives a key from a password and a salt using PBKDF2.
 *
 * @note This will call @ref OFHMAC::reset on the `HMAC` first, making it
 *	 possible to reuse the `HMAC`, but also meaning all previous results
 *	 from the `HMAC` get invalidated if they have not been copied.
 *
 * @param param The parameters to use
 */
extern void of_pbkdf2(of_pbkdf2_parameters_t param);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
