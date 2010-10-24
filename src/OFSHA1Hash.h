/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFHash.h"

#define OF_SHA1_DIGEST_SIZE 20

/**
 * \brief A class which provides functions to create an SHA1 hash.
 */
@interface OFSHA1Hash: OFHash
{
	uint32_t state[5];
	uint64_t count;
	char	 buffer[64];
	uint8_t	 digest[OF_SHA1_DIGEST_SIZE];
}

/**
 * \return A new autoreleased SHA1 Hash
 */
+ SHA1Hash;
@end
