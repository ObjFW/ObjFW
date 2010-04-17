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

#import "OFObject.h"
#import "OFString.h"

#define OF_MD5_DIGEST_SIZE  16
#define OF_SHA1_DIGEST_SIZE 20

extern int _OFHashing_reference;

/**
 * \brief A base class for classes providing hash functions.
 */
@interface OFHash: OFObject
{
	BOOL	 calculated;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) BOOL calculated;
#endif

/**
 * Adds a buffer to the hash to be calculated.
 *
 * \param buf The buffer which should be included into the calculation.
 * \param size The size of the buffer
 */
- (void)updateWithBuffer: (const char*)buf
		  ofSize: (size_t)size;

/**
 * \return A buffer containing the hash. The size of the buffer is depending
 *	   on the hash used. The buffer is part of object's memory pool.
 */
- (uint8_t*)digest;

/**
 * \return A boolean whether the hash has already been calculated
 */
- (BOOL)calculated;
@end

/**
 * \brief A class which provides functions to create an MD5 hash.
 */
@interface OFMD5Hash: OFHash
{
	uint32_t buf[4];
	uint32_t bits[2];
	uint8_t	 in[64];
}

/**
 * \return A new autoreleased MD5 Hash
 */
+ md5Hash;
@end

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
+ sha1Hash;
@end

/**
 * The OFString (OFHashing) category provides methods to calculate hashes for
 * strings.
 */
@interface OFString (OFHashing)
/**
 * \return The MD5 hash of the string as an autoreleased OFString
 */
- (OFString*)md5Hash;

/**
 * \return The SHA1 hash of the string as an autoreleased OFString
 */
- (OFString*)sha1Hash;
@end
