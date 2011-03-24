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

/**
 * \brief An exception indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	OFString *host;
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *host;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param host The host for which translation was requested
 * \return A new address translation failed exception
 */
+ newWithClass: (Class)class_
	  host: (OFString*)host;

/**
 * Initializes an already allocated address translation failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param host The host for which translation was requested
 * \return An initialized address translation failed exception
 */
- initWithClass: (Class)class_
	   host: (OFString*)host;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * /return The host for which translation was requested
 */
- (OFString*)host;
@end
