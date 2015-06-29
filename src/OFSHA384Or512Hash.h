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

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSHA384Or512Hash OFSHA384Or512Hash.h ObjFW/OFSHA384Or512Hash.h
 *
 * @brief A base class for SHA-384 and SHA-512.
 */
@interface OFSHA384Or512Hash: OFObject <OFHash>
{
	uint64_t _state[8];
	uint64_t _bits[2];
	union {
		uint8_t bytes[128];
		uint64_t words[80];
	} _buffer;
	size_t _bufferLength;
	bool _calculated;
}

- (void)OF_resetState;
@end

OF_ASSUME_NONNULL_END
