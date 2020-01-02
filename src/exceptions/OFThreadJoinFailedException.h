/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
	int _errNo;
}

/*!
 * @brief The thread which could not be joined.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFThread *thread;

/*!
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/*!
 * @brief Creates a new, autoreleased thread join failed exception.
 *
 * @param thread The thread which could not be joined
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased thread join failed exception
 */
+ (instancetype)exceptionWithThread: (nullable OFThread *)thread
			      errNo: (int)errNo;

/*!
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
