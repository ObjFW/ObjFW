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

#ifdef OBJFWBRIDGE_LOCAL_INCLUDES
# import "OFArray.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFArray.h>
# endif
#endif

#import "OFOFToNSBridging.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFArray_NSObject_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

/**
 * @category OFArray (NSObject) OFArray+NSObject.h ObjFWBridge/ObjFWBridge.h
 *
 * @brief Support for bridging an @ref OFArray to an NSArray.
 */
@interface OFArray (NSObject) <OFOFToNSBridging>
@property (readonly, nonatomic) NSArray *NSObject;
@end

OF_ASSUME_NONNULL_END
