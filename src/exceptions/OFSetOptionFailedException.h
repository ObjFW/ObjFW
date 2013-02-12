/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

@class OFStream;

/*!
 * @brief An exception indicating that setting an option for a stream failed.
 */
@interface OFSetOptionFailedException: OFException
{
	OFStream *_stream;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFStream *stream;
#endif

/*!
 * @brief Creates a new, autoreleased set option failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param stream The stream for which the option could not be set
 * @return A new, autoreleased set option failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    stream: (OFStream*)stream;

/*!
 * @brief Initializes an already allocated set option failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param stream The stream for which the option could not be set
 * @return An initialized set option failed exception
 */
- initWithClass: (Class)class_
	 stream: (OFStream*)stream;

/*!
 * @brief Returns the stream for which the option could not be set.
 *
 * @return The stream for which the option could not be set
 */
- (OFStream*)stream;
@end
