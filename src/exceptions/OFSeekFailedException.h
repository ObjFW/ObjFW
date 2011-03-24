/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

@class OFSeekableStream;

/**
 * \brief An exception indicating that seeking in a stream failed.
 */
@interface OFSeekFailedException: OFException
{
	OFSeekableStream *stream;
	int		 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFSeekableStream *stream;
@property (readonly) int errNo;
#endif

/**
 * \param stream The stream for which seeking failed
 * \return A new seek failed exception
 */
+ newWithClass: (Class)class_
	stream: (OFSeekableStream*)stream;

/**
 * Initializes an already allocated seek failed exception.
 *
 * \param stream The stream for which seeking failed
 * \return An initialized seek failed exception
 */
- initWithClass: (Class)class_
	 stream: (OFSeekableStream*)stream;

/**
 * \return The stream for which seeking failed
 */
- (OFSeekableStream*)stream;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end
