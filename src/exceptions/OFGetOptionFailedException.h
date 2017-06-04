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
 * @class OFGetOptionFailedException \
 *	  OFGetOptionFailedException.h ObjFW/OFGetOptionFailedException.h
 *
 * @brief An exception indicating that getting an option for a stream failed.
 */
@interface OFGetOptionFailedException: OFException
{
	OFStream *_stream;
	int _errNo;
}

/*!
 * The stream for which the option could not be retrieved.
 */
@property (readonly, nonatomic) OFStream *stream;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased get option failed exception.
 *
 * @param stream The stream for which the option could not be gotten
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased get option failed exception
 */
+ (instancetype)exceptionWithStream: (OFStream *)stream
			      errNo: (int)errNo;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated get option failed exception.
 *
 * @param stream The stream for which the option could not be gotten
 * @param errNo The errno of the error that occurred
 * @return An initialized get option failed exception
 */
- initWithStream: (OFStream *)stream
	   errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
