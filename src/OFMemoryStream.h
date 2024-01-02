/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMemoryStream OFMemoryStream.h ObjFW/OFMemoryStream.h
 *
 * @brief A seekable stream for reading from and writing to memory.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMemoryStream: OFSeekableStream
{
	char *_address;
	size_t _size, _position;
	bool _writable;
}

/**
 * @brief Creates a new OFMemoryStream with the specified memory.
 *
 * @warning The memory is not copied, so it is your responsibility that the
 *	    specified memory stays alive for as long as the OFMemoryStream does!
 *
 * @param address The memory address for the stream
 * @param size The size of the memory at the specified address
 * @param writable Whether writes to memory should be allowed
 * @return A new autoreleased OFMemoryStream
 */
+ (instancetype)streamWithMemoryAddress: (void *)address
				   size: (size_t)size
			       writable: (bool)writable;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMemoryStream with the specified
 *	  memory.
 *
 * @warning The memory is not copied, so it is your responsibility that the
 *	    specified memory stays alive for as long as the OFMemoryStream does!
 *
 * @param address The memory address for the stream
 * @param size The size of the memory at the specified address
 * @param writable Whether writes to memory should be allowed
 * @return An initialized OFMemoryStream
 */
- (instancetype)initWithMemoryAddress: (void *)address
				 size: (size_t)size
			     writable: (bool)writable;
@end

OF_ASSUME_NONNULL_END
