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

#import "OFHash.h"

#define OF_MD5_DIGEST_SIZE  16

/**
 * \brief A class which provides functions to create an MD5 hash.
 */
@interface OFMD5Hash: OFHash
{
	uint32_t buf[4];
	uint32_t bits[2];
	union {
		uint8_t	u8[64];
		uint32_t u32[16];
	} in;
}

/**
 * \return A new autoreleased MD5 Hash
 */
+ MD5Hash;
@end
