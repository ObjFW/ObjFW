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

#import "OFStream.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFGeminiResponse OFGeminiResponse.h ObjFW/ObjFW.h
 *
 * @brief A class representing a Gemini request response as a stream.
 */
#ifndef OF_GEMINI_CLIENT_M
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFGeminiResponse: OFStream
{
	unsigned char _statusCode;
	OFString *_metadata;
}

/**
 * @brief The status code of the response to the Gemini request.
 */
@property (nonatomic) unsigned char statusCode;

/**
 * @brief The metadata of the response to the Gemini request.
 */
@property (copy, nonatomic) OFString *metadata;
@end

OF_ASSUME_NONNULL_END
