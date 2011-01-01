/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#define OF_UNICODE_UPPER_TABLE_SIZE 0x105
#define OF_UNICODE_LOWER_TABLE_SIZE 0x105
#define OF_UNICODE_CASEFOLDING_TABLE_SIZE 0x105

extern const of_unichar_t* const
    of_unicode_upper_table[OF_UNICODE_UPPER_TABLE_SIZE];
extern const of_unichar_t* const
    of_unicode_lower_table[OF_UNICODE_LOWER_TABLE_SIZE];
extern const of_unichar_t* const
    of_unicode_casefolding_table[OF_UNICODE_CASEFOLDING_TABLE_SIZE];
