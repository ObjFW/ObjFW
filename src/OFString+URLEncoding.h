/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_URLEncoding_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (URLEncoding)
/*!
 * @brief Encodes a string for use in a URL.
 *
 * @return A new autoreleased string
 */
- (OFString*)stringByURLEncoding;

/*!
 * @brief Encodes a string for use in a URL, but does not escape the specified
 *	  ignored characters.
 *
 * @param ignored A C string of characters that should not be escaped
 *
 * @return A new autoreleased string
 */
- (OFString*)stringByURLEncodingWithIgnoredCharacters: (const char*)ignored;

/*!
 * @brief Decodes a string used in a URL.
 *
 * @return A new autoreleased string
 */
- (OFString*)stringByURLDecoding;
@end

OF_ASSUME_NONNULL_END
