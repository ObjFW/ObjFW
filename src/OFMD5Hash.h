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

#import "OFCryptoHash.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMD5Hash OFMD5Hash.h ObjFW/OFMD5Hash.h
 *
 * @brief A class which provides methods to create an MD5 hash.
 */
@interface OFMD5Hash: OFObject <OFCryptoHash>
{
	uint32_t _state[4];
	uint64_t _bits;
	union of_md5_hash_buffer {
		uint8_t bytes[64];
		uint32_t words[16];
	} _buffer;
	size_t _bufferLength;
	bool _calculated;
}
@end

OF_ASSUME_NONNULL_END
