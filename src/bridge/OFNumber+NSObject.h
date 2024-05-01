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

#ifdef OBJFWBRIDGE_LOCAL_INCLUDES
# import "OFNumber.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFNumber.h>
# endif
#endif

#import "OFBridging.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFNumber_NSObject_reference OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

/**
 * @category OFNumber (NSObject) \
 *	     OFNumber+NSObject.h ObjFWBridge/OFNumber+NSObject.h
 *
 * @brief Support for bridging OFNumbers to NSNumbers.
 */
@interface OFNumber (NSObject) <OFBridging>
@property (readonly, nonatomic) NSNumber *NSObject;
@end

OF_ASSUME_NONNULL_END
