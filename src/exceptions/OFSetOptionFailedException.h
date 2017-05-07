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

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

/*!
 * @class OFSetOptionFailedException \
 *	  OFSetOptionFailedException.h ObjFW/OFSetOptionFailedException.h
 *
 * @brief An exception indicating that setting an option for a stream failed.
 */
@interface OFSetOptionFailedException: OFException
{
	OFStream *_stream;
	int _errNo;
}

/*!
 * The stream for which the option could not be set.
 */
@property (readonly, nonatomic) OFStream *stream;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased set option failed exception.
 *
 * @param stream The stream for which the option could not be set
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased set option failed exception
 */
+ (instancetype)exceptionWithStream: (OFStream *)stream
			      errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated set option failed exception.
 *
 * @param stream The stream for which the option could not be set
 * @param errNo The errno of the error that occurred
 * @return An initialized set option failed exception
 */
- initWithStream: (OFStream *)stream
	   errNo: (int)errNo;
@end

OF_ASSUME_NONNULL_END
