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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFHMAC;

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Derive a key from a password and a salt.
 *
 * @note This will call @ref OFHMAC::reset on the @ref OFHMAC first, making it
 *	 possible to reuse the @ref OFHMAC, but also meaning all previous
 *	 results from the @ref OFHMAC get invalidated if they have not been
 *	 copied.
 *
 * @param HMAC The HMAC to use to derive a key
 * @param iterations The number of iterations to perform
 * @param salt The salt to derive a key with
 * @param saltLength The length of the salt
 * @param password The password to derive a key from
 * @param passwordLength The length of the password
 * @param key The buffer to write the key to
 * @param keyLength The desired length for the derived key (key needs to have
 *		    enough storage)
 */
extern void of_pbkdf2(OFHMAC *HMAC, size_t iterations,
    const unsigned char *salt, size_t saltLength,
    const char *password, size_t passwordLength,
    unsigned char *key, size_t keyLength);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
