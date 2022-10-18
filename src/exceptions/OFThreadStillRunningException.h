/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFThread;

/**
 * @class OFThreadStillRunningException \
 *	  OFThreadStillRunningException.h ObjFW/OFThreadStillRunningException.h
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
