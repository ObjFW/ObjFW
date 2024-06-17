/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMemoryStream OFMemoryStream.h ObjFW/ObjFW.h
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
