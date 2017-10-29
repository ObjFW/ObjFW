/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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
extern int _OFString_JSONValue_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (JSONValue)
/*!
 * The string interpreted as JSON and parsed as an object.
 *
 * @note This also allows parsing JSON5, an extension of JSON. See
 *	 http://json5.org/ for more details.
 *
 * @warning Although not specified by the JSON specification, this can also
 *          return primitives like strings and numbers. The rationale behind
 *          this is that most JSON parsers allow JSON data just consisting of a
 *          single primitive, leading to real world JSON files sometimes only
 *          consisting of a single primitive. Therefore, you should not make any
 *          assumptions about the object returned by this method if you don't
 *          want your program to terminate due to a message not understood, but
 *          instead check the returned object using @ref isKindOfClass:.
 */
@property (readonly, nonatomic) id JSONValue;

/*!
 * @brief Creates an object from the JSON value of the string.
 *
 * @note This also allows parsing JSON5, an extension of JSON. See
 *	 http://json5.org/ for more details.
 *
 * @warning Although not specified by the JSON specification, this can also
 *          return primitives like strings and numbers. The rationale behind
 *          this is that most JSON parsers allow JSON data just consisting of a
 *          single primitive, leading to real world JSON files sometimes only
 *          consisting of a single primitive. Therefore, you should not make any
 *          assumptions about the object returned by this method if you don't
 *          want your program to terminate due to a message not understood, but
 *          instead check the returned object using @ref isKindOfClass:.
 *
 * @param depthLimit The maximum depth the parser should accept (defaults to 32
 *		     if not specified, 0 means no limit (insecure!))
 *
 * @return An object
 */
- (id)JSONValueWithDepthLimit: (size_t)depthLimit;
@end

OF_ASSUME_NONNULL_END
