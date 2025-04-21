/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFCharacterSet;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_PercentEncoding_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

@interface OFString (PercentEncoding)
/**
 * @brief The string with percent encoding removed.
 *
 * @throw OFInvalidFormatException The string is not in proper percent encoding
 */
@property (readonly, nonatomic) OFString *stringByRemovingPercentEncoding;

/**
 * @brief Percent-encodes a string for use in an IRI, but does not escape the
 *	  specified allowed characters.
 *
 * @param allowedCharacters A character set of characters that should not be
 *			    escaped
 *
 * @return A new autoreleased string
 */
- (OFString *)stringByAddingPercentEncodingWithAllowedCharacters:
    (OFCharacterSet *)allowedCharacters;
@end

OF_ASSUME_NONNULL_END
