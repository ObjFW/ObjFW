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

#import "OFReadOrWriteFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFWriteFailedException OFWriteFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that writing to an object failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException
{
	size_t _bytesWritten;
	OF_RESERVE_IVARS(OFWriteFailedException, 4)
}

/**
 * @brief The number of bytes already written before the write failed.
 *
 * This can be used to make sure that a retry does not write data already
 * written before.
 */
@property (readonly, nonatomic) size_t bytesWritten;

/**
 * @brief Creates a new, autoreleased write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param bytesWritten The amount of bytes already written before the write
 *		       failed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased write failed exception
 */
+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
		       bytesWritten: (size_t)bytesWritten
			      errNo: (int)errNo;

+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param bytesWritten The amount of bytes already written before the write
 *		       failed
 * @param errNo The errno of the error that occurred
 * @return A new open file failed exception
 */
- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
		  bytesWritten: (size_t)bytesWritten
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
			 errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
