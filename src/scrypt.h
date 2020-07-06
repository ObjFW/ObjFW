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

/*! @file */

@class OFHMAC;

/*!
 * @brief The parameters for @ref of_scrypt.
 */
typedef struct of_scrypt_parameters_t {
	/*! @brief The block size to use. */
	size_t blockSize;
	/*! @brief The CPU/memory cost factor to use. */
	size_t costFactor;
	/*! @brief The parallelization to use. */
	size_t parallelization;
	/*! @brief The salt to derive a key with. */
	const unsigned char *salt;
	/*! @brief The length of the salt. */
	size_t saltLength;
	/*! @brief The password to derive a key from. */
	const char *password;
	/*! @brief The length of the password. */
	size_t passwordLength;
	/*! @brief The buffer to write the key to. */
	unsigned char *key;
	/*!
	 * @brief The desired length for the derived key.
	 *
	 * @ref key needs to have enough storage.
	 */
	size_t keyLength;
	/*! @brief Whether data may be stored in swappable memory. */
	bool allowsSwappableMemory;
} of_scrypt_parameters_t;

#ifdef __cplusplus
extern "C" {
#endif
extern void of_salsa20_8_core(uint32_t buffer[_Nonnull 16]);
extern void of_scrypt_block_mix(uint32_t *output, const uint32_t *input,
    size_t blockSize);
extern void of_scrypt_romix(uint32_t *buffer, size_t blockSize,
    size_t costFactor, uint32_t *tmp);

/*!
 * @brief Derives a key from a password and a salt using scrypt.
 *
 * @param param The parameters to use
 */
extern void of_scrypt(of_scrypt_parameters_t param);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
