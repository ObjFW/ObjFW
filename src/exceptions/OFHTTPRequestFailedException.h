/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFHTTPRequest;
@class OFHTTPResponse;

/**
 * @class OFHTTPRequestFailedException \
 *	  OFHTTPRequestFailedException.h \
 *	  ObjFW/OFHTTPRequestFailedException.h
 *
 * @brief An exception indicating that an HTTP request failed.
 */
@interface OFHTTPRequestFailedException: OFException
{
	OFHTTPRequest *_request;
	OFHTTPResponse *_response;
	OF_RESERVE_IVARS(OFHTTPRequestFailedException, 4)
}

/**
 * @brief The HTTP request which failed.
 */
@property (readonly, nonatomic) OFHTTPRequest *request;

/**
 * @brief The response for the failed HTTP request.
 */
@property (readonly, nonatomic) OFHTTPResponse *response;

/**
 * @brief Creates a new, autoreleased HTTP request failed exception.
 *
 * @param request The HTTP request which failed
 * @param response The response for the failed HTTP request
 * @return A new, autoreleased HTTP request failed exception
 */
+ (instancetype)exceptionWithRequest: (OFHTTPRequest *)request
			    response: (OFHTTPResponse *)response;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated HTTP request failed exception.
 *
 * @param request The HTTP request which failed
 * @param response The response for the failed HTTP request
 * @return A new HTTP request failed exception
 */
- (instancetype)initWithRequest: (OFHTTPRequest *)request
		       response: (OFHTTPResponse *)response
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
