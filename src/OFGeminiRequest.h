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

#import "OFObject.h"
#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;

/**
 * @class OFGeminiRequest OFGeminiRequest.h ObjFW/ObjFW.h
 *
 * @brief A class for storing Gemini requests.
 */
@interface OFGeminiRequest: OFObject <OFCopying>
{
	OFIRI *_IRI;
	OFSocketAddress _remoteAddress;
	bool _hasRemoteAddress;
	OF_RESERVE_IVARS(OFGeminiRequest, 4)
}

/**
 * @brief The IRI of the Gemini request.
 */
@property (copy, nonatomic) OFIRI *IRI;

/**
 * @brief The remote address from which the request originates.
 *
 * @note The setter creates a copy of the remote address.
 */
@property OF_NULLABLE_PROPERTY (nonatomic) const OFSocketAddress *remoteAddress;

/**
 * @brief Creates a new OFGeminiRequest with the specified IRI.
 *
 * @param IRI The IRI for the request
 * @return A new, autoreleased OFGeminiRequest
 */
+ (instancetype)requestWithIRI: (OFIRI *)IRI;

/**
 * @brief Initializes an already allocated OFGeminiRequest with the specified
 *	  IRI.
 *
 * @param IRI The IRI for the request
 * @return An initialized OFGeminiRequest
 */
- (instancetype)initWithIRI: (OFIRI *)IRI;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
