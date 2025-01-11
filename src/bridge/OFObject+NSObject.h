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

#import <Foundation/NSObject.h>

#ifdef OBJFWBRIDGE_LOCAL_INCLUDES
# import "OFObject.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFObject.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFObject_NSObject_reference OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

/**
 * @category OFObject (NSObject) OFObject+NSObject.h ObjFWBridge/ObjFWBridge.h
 *
 * @brief NSObject-conformance for OFObject
 */
@interface OFObject (NSObject) <NSObject>
@end

OF_ASSUME_NONNULL_END
