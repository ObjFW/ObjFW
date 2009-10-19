/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

#define OF_UNICODE_UPPER_TABLE_SIZE 0x105
#define OF_UNICODE_LOWER_TABLE_SIZE 0x105

extern const of_unichar_t* const
    of_unicode_upper_table[OF_UNICODE_UPPER_TABLE_SIZE];
extern const of_unichar_t* const
    of_unicode_lower_table[OF_UNICODE_LOWER_TABLE_SIZE];
