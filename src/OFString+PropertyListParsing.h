/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
