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

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFThread;

/**
 * @class OFJoinThreadFailedException OFJoinThreadFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that joining a thread failed.
 */
@interface OFJoinThreadFailedException: OFException
{
	OFThread *_Nullable _thread;
	int _errNo;
	OF_RESERVE_IVARS(OFJoinThreadFailedException, 4)
}

/**
 * @brief The thread which could not be joined.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFThread *thread;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased thread join failed exception.
 *
 * @param thread The thread which could not be joined
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased thread join failed exception
 */
+ (instancetype)exceptionWithThread: (nullable OFThread *)thread
			      errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated thread join failed exception.
 *
 * @param thread The thread which could not be joined
 * @param errNo The errno of the error that occurred
 * @return An initialized thread join failed exception
 */
- (instancetype)initWithThread: (nullable OFThread *)thread
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
