/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"
#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFSeekFailedException OFSeekFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that seeking in a stream failed.
 */
@interface OFSeekFailedException: OFException
{
	OFSeekableStream *_stream;
	OFStreamOffset _offset;
	OFSeekWhence _whence;
	int _errNo;
	OF_RESERVE_IVARS(OFSeekFailedException, 4)
}

/**
 * @brief The stream for which seeking failed.
 */
@property (readonly, nonatomic) OFSeekableStream *stream;

/**
 * @brief The offset to which seeking failed.
 */
@property (readonly, nonatomic) OFStreamOffset offset;

/**
 * @brief To what the offset is relative.
 */
@property (readonly, nonatomic) OFSeekWhence whence;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased seek failed exception
 */
+ (instancetype)exceptionWithStream: (OFSeekableStream *)stream
			     offset: (OFStreamOffset)offset
			     whence: (OFSeekWhence)whence
			      errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @param errNo The errno of the error that occurred
 * @return An initialized seek failed exception
 */
- (instancetype)initWithStream: (OFSeekableStream *)stream
			offset: (OFStreamOffset)offset
			whence: (OFSeekWhence)whence
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
