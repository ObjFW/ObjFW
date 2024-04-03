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
extern int _OFString_PropertyListParsing_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (PropertyListParsing)
/**
 * @brief The string interpreted as a property list and parsed as an object.
 *
 * @note This only supports XML property lists!
 *
 * @throw OFInvalidFormatException The string is not in correct XML property
 *				   list format
 * @throw OFUnsupportedVersionException The property list is using a version
 *					that is not supported
 */
@property (readonly, nonatomic) id objectByParsingPropertyList;
@end

OF_ASSUME_NONNULL_END
