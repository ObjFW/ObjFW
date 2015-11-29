/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
 * @class OFUnsupportedProtocolException \
 *	  OFUnsupportedProtocolException.h \
 *	  ObjFW/OFUnsupportedProtocolException.h
 *
 * @brief An exception indicating that the protocol specified by the URL is not
 *	  supported.
 */
@interface OFUnsupportedProtocolException: OFException
{
	OFURL *_URL;
}

/*!
 * The URL whose protocol is unsupported.
 */
@property (readonly, retain) OFURL *URL;

/*!
 * @brief Creates a new, autoreleased unsupported protocol exception.
 *
 * @param URL The URL whose protocol is unsupported
 * @return A new, autoreleased unsupported protocol exception
 */
+ (instancetype)exceptionWithURL: (OFURL*)URL;

/*!
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param URL The URL whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- initWithURL: (OFURL*)URL;
@end
