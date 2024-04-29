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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_JSONParsing_reference OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

@interface OFString (JSONParsing)
/**
 * @brief The string interpreted as JSON and parsed as an object.
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
 * @throw OFInvalidJSONException The string contained invalid JSON
 */
@property (readonly, nonatomic) id objectByParsingJSON;

/**
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
 * @return An object
 * @throw OFInvalidJSONException The string contained invalid JSON
 */
- (id)objectByParsingJSONWithDepthLimit: (size_t)depthLimit;
@end

OF_ASSUME_NONNULL_END
