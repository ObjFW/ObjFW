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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFReadOrWriteFailedException OFReadOrWriteFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that reading from or writing to an object
 *	  failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	id _object;
	size_t _requestedLength;
	int _errNo;
	OF_RESERVE_IVARS(OFReadOrWriteFailedException, 4)
}

/**
 * @brief The stream which caused the read or write failed exception.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief The requested length of the data that could not be read / written.
 */
@property (readonly, nonatomic) size_t requestedLength;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased read or write failed exception
 */
+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
			      errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that could not be
 *			  read / written
 * @param errNo The errno of the error that occurred
 * @return A new open file failed exception
 */
- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
