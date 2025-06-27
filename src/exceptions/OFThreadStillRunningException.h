/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
 * @class OFThreadStillRunningException OFThreadStillRunningException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a thread is still running.
 */
@interface OFThreadStillRunningException: OFException
{
	OFThread *_Nullable _thread;
	OF_RESERVE_IVARS(OFThreadStillRunningException, 4)
}

/**
 * @brief The thread which is still running.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFThread *thread;

/**
 * @brief Creates a new, autoreleased thread still running exception.
 *
 * @param thread The thread which is still running
 * @return A new, autoreleased thread still running exception
 */
+ (instancetype)exceptionWithThread: (nullable OFThread *)thread;

/**
 * @brief Initializes an already allocated thread still running exception.
 *
 * @param thread The thread which is still running
 * @return An initialized thread still running exception
 */
- (instancetype)initWithThread: (nullable OFThread *)thread
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
