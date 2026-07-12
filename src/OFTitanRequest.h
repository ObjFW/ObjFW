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

#import "OFGeminiRequest.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFTitanRequest OFTitanRequest.h ObjFW/ObjFW.h
 *
 * @brief A class for storing Titan requests.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFTitanRequest: OFGeminiRequest
/**
 * @brief The upload path of the Titan request.
 *
 * @throw OFInvalidArgumentException The IRI of the request is not a valid
 *				     Titan IRI
 */
@property (copy, nonatomic) OFString *uploadPath;

/**
 * @brief The upload size of the Titan request.
 *
 * @throw OFInvalidArgumentException The IRI of the request is not a valid
 *				     Titan IRI
 * @throw OFInvalidFormatException The upload size inside the IRI is not a
 *				   valid number
 * @throw OFOutOfRangeException The upload size inside the IRI is too big
 */
@property (nonatomic) unsigned long long uploadSize;

/**
 * @brief The upload MIME type of the Titan request.
 *
 * @throw OFInvalidArgumentException The IRI of the request is not a valid
 *				     Titan IRI
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *uploadMIMEType;

/**
 * @brief The upload token of the Titan request.
 *
 * @throw OFInvalidArgumentException The IRI of the request is not a valid
 *				     Titan IRI
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *uploadToken;
@end

OF_ASSUME_NONNULL_END
