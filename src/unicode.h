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

#define OF_UNICODE_UPPERCASE_TABLE_SIZE 0x1EA
#define OF_UNICODE_LOWERCASE_TABLE_SIZE 0x1EA
#define OF_UNICODE_TITLECASE_TABLE_SIZE 0x1EA
#define OF_UNICODE_CASEFOLDING_TABLE_SIZE 0x1EA
#define OF_UNICODE_DECOMPOSITION_TABLE_SIZE 0x2FB

#ifdef __cplusplus
extern "C" {
#endif
extern const of_unichar_t *const _Nonnull
    of_unicode_uppercase_table[OF_UNICODE_UPPERCASE_TABLE_SIZE];
extern const of_unichar_t *const _Nonnull
    of_unicode_lowercase_table[OF_UNICODE_LOWERCASE_TABLE_SIZE];
extern const of_unichar_t *const _Nonnull
    of_unicode_titlecase_table[OF_UNICODE_TITLECASE_TABLE_SIZE];
extern const of_unichar_t *const _Nonnull
    of_unicode_casefolding_table[OF_UNICODE_CASEFOLDING_TABLE_SIZE];
extern const char *const _Nullable *const _Nonnull
    of_unicode_decomposition_table[OF_UNICODE_DECOMPOSITION_TABLE_SIZE];
#ifdef __cplusplus
}
#endif
