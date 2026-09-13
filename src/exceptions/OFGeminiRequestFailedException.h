/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

@class OFGeminiResponse;
@class OFGeminiRequest;

/**
 * @class OFGeminiRequestFailedException OFGeminiRequestFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a Gemini request failed.
 */
@interface OFGeminiRequestFailedException: OFException
{
	OFGeminiRequest *_request;
	OFGeminiResponse *_response;
	OF_RESERVE_IVARS(OFGeminiRequestFailedException, 4)
}

/**
 * @brief The Gemini request which failed.
 */
@property (readonly, nonatomic) OFGeminiRequest *request;

/**
 * @brief The response for the failed Gemini request.
 */
@property (readonly, nonatomic) OFGeminiResponse *response;

/**
 * @brief Creates a new, autoreleased Gemini request failed exception.
 *
 * @param request The Gemini request which failed
 * @param response The response for the failed Gemini request
 * @return A new, autoreleased Gemini request failed exception
 */
+ (instancetype)exceptionWithRequest: (OFGeminiRequest *)request
			    response: (OFGeminiResponse *)response;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated Gemini request failed exception.
 *
 * @param request The Gemini request which failed
 * @param response The response for the failed Gemini request
 * @return A new Gemini request failed exception
 */
- (instancetype)initWithRequest: (OFGeminiRequest *)request
		       response: (OFGeminiResponse *)response
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
