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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

@class OFHTTPRequest;
@class OFHTTPResponse;

/*!
 * @brief An exception indicating that a HTTP request failed.
 */
@interface OFHTTPRequestFailedException: OFException
{
	OFHTTPRequest *_request;
	OFHTTPResponse *_response;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFHTTPRequest *request;
@property (readonly, retain, nonatomic) OFHTTPResponse *response;
#endif

/*!
 * @brief Creates a new, autoreleased HTTP request failed exception.
 *
 * @param request The HTTP request which failed
 * @param response The response for the failed HTTP request
 * @return A new, autoreleased HTTP request failed exception
 */
+ (instancetype)exceptionWithRequest: (OFHTTPRequest*)request
			    response: (OFHTTPResponse*)response;

/*!
 * @brief Initializes an already allocated HTTP request failed exception.
 *
 * @param request The HTTP request which failed
 * @param response The response for the failed HTTP request
 * @return A new HTTP request failed exception
 */
- initWithRequest: (OFHTTPRequest*)request
	 response: (OFHTTPResponse*)response;

/*!
 * @brief Returns the HTTP request which failed.
 *
 * @return The HTTP request which failed
 */
- (OFHTTPRequest*)request;

/*!
 * @brief Returns the response for the failed HTTP request.
 *
 * @return The response for the failed HTTP request
 */
- (OFHTTPResponse*)response;
@end
