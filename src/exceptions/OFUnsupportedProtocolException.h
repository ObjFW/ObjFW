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

@class OFURL;

/*!
 * @brief An exception indicating that the protocol specified by the URL is not
 *	  supported.
 */
@interface OFUnsupportedProtocolException: OFException
{
	OFURL *_URL;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFURL *URL;
#endif

/*!
 * @brief Creates a new, autoreleased unsupported protocol exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param URL The URL whose protocol is unsupported
 * @return A new, autoreleased unsupported protocol exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			       URL: (OFURL*)URL;

/*!
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param class_ The class of the object which caused the exception
 * @param URL The URL whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- initWithClass: (Class)class_
	    URL: (OFURL*)URL;

/*!
 * @brief Returns the URL whose protocol is unsupported.
 *
 * @return The URL whose protocol is unsupported
 */
- (OFURL*)URL;
@end
