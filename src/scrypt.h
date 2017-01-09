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
extern void of_salsa20_8_core(uint32_t buffer[_Nonnull 16]);
extern void of_scrypt_block_mix(uint32_t *output, const uint32_t *input,
    size_t blockSize);
extern void of_scrypt_romix(uint32_t *buffer, size_t blockSize,
    size_t costFactor, uint32_t *tmp);
extern void of_scrypt(size_t blockSize, size_t costFactor,
    size_t parallelization, const unsigned char *salt, size_t saltLength,
    const char *password, size_t passwordLength,
    unsigned char *key, size_t keyLength);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
