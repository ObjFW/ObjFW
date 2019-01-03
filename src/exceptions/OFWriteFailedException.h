/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFReadOrWriteFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFWriteFailedException \
 *	  OFWriteFailedException.h ObjFW/OFWriteFailedException.h
 *
 * @brief An exception indicating that writing to an object failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException
{
	size_t _bytesWritten;
}

/*!
 * @brief The number of bytes already written before the write failed.
 *
 * This can be used to make sure that a retry does not write data already
 * written before.
 */
@property (readonly, nonatomic) size_t bytesWritten;

+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
			      errNo: (int)errNo OF_UNAVAILABLE;

/*!
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

- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
			 errNo: (int)errNo OF_UNAVAILABLE;

/*!
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
@end

OF_ASSUME_NONNULL_END
