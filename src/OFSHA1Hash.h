/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

/*!
 * @class OFSHA1Hash OFSHA1Hash.h ObjFW/OFSHA1Hash.h
 *
 * @brief A class which provides functions to create an SHA-1 hash.
 */
@interface OFSHA1Hash: OFObject <OFHash>
{
	uint32_t _state[5];
	uint64_t _bits;
	union {
		uint8_t bytes[64];
		uint32_t words[80];
	} _buffer;
	size_t _bufferLength;
	bool _calculated;
}
@end
