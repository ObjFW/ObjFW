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

@class OFHTTPRequest;

/**
 * \brief An exception indicating that a HTTP request failed.
 */
@interface OFHTTPRequestFailedException: OFException
{
	OFHTTPRequest *HTTPRequest;
	short statusCode;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFHTTPRequest *HTTPRequest;
@property (readonly) short statusCode;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param request The HTTP request which failed
 * \param code The status code of the fialed HTTP request
 * \return A new HTTP request failed exception
 */
+ newWithClass: (Class)class_
   HTTPRequest: (OFHTTPRequest*)request
    statusCode: (short)code;

/**
 * Initializes an already allocated HTTP request failed exception
 *
 * \param class_ The class of the object which caused the exception
 * \param request The HTTP request which failed
 * \param code The status code of the fialed HTTP request
 * \return A new HTTP request failed exception
 */
- initWithClass: (Class)class_
    HTTPRequest: (OFHTTPRequest*)request
     statusCode: (short)code;

/**
 * \return The HTTP request which failed
 */
- (OFHTTPRequest*)HTTPRequest;

/**
 * \return The status code of the HTTP request
 */
- (short)statusCode;
@end
