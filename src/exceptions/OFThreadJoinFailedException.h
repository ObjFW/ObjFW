/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

/*!
 * @class OFThreadJoinFailedException \
 *	  OFThreadJoinFailedException.h ObjFW/OFThreadJoinFailedException.h
 *
 * @brief An exception indicating that joining a thread failed.
 */
@interface OFThreadJoinFailedException: OFException
{
	OFThread *_thread;
}

/*!
 * The thread which could not be joined.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFThread *thread;

/*!
 * @brief Creates a new, autoreleased thread join failed exception.
 *
 * @param thread The thread which could not be joined
 * @return A new, autoreleased thread join failed exception
 */
+ (instancetype)exceptionWithThread: (nullable OFThread *)thread;

/*!
 * @brief Initializes an already allocated thread join failed exception.
 *
 * @param thread The thread which could not be joined
 * @return An initialized thread join failed exception
 */
- (instancetype)initWithThread: (nullable OFThread *)thread
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
