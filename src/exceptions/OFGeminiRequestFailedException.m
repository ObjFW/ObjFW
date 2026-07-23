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

#include "config.h"

#import "OFGeminiRequestFailedException.h"
#import "OFGeminiRequest.h"
#import "OFGeminiResponse.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFGeminiRequestFailedException
@synthesize request = _request, response = _response;

+ (instancetype)exceptionWithRequest: (OFGeminiRequest *)request
			    response: (OFGeminiResponse *)response
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithRequest: request
				 response: response]);
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithRequest: (OFGeminiRequest *)request
		       response: (OFGeminiResponse *)response
{
	self = [super init];

	_request = objc_retain(request);
	_response = objc_retain(response);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_request);
	objc_release(_response);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"A Gemini request with IRI %@ failed with code %hhu: %@!",
	    _request.IRI, _response.statusCode, _response.metadata];
}
@end
