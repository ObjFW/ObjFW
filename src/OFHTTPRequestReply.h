/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFObject.h"

@class OFDataArray;
@class OFDictionary;

/*!
 * @brief A class for storing a reply to an HTTP request.
 */
@interface OFHTTPRequestReply: OFObject
{
	short statusCode;
	OFDataArray *data;
	OFDictionary *headers;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) short statusCode;
@property (readonly, copy) OFDictionary *headers;
@property (readonly, retain) OFDataArray *data;
#endif

/*!
 * @brief Creates a new OFHTTPRequestReply.
 *
 * @param status The HTTP status code replied to the request
 * @param headers The headers replied to the request
 * @param data The data replied to the request
 * @return A new OFHTTPRequestReply
 */
+ replyWithStatusCode: (short)status
	      headers: (OFDictionary*)headers
		 data: (OFDataArray*)data;

/*!
 * @brief Initializes an already allocated OFHTTPRequestReply.
 *
 * @param status The HTTP status code replied to the request
 * @param headers The headers replied to the request
 * @param data The data replied to the request
 * @return An initialized OFHTTPRequestReply
 */
- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers
		data: (OFDataArray*)data;

/*!
 * @brief Returns the state code of the reply of the HTTP request.
 *
 * @return The status code of the reply of the HTTP request
 */
- (short)statusCode;

/*!
 * @brief Returns the headers of the reply of the HTTP request.
 *
 * @return The headers of the reply of the HTTP request
 */
- (OFDictionary*)headers;

/*!
 * @brief Returns the data received for the HTTP request.
 *
 * @return The data received for the HTTP request
 */
- (OFDataArray*)data;
@end
