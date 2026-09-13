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

#import <Foundation/NSString.h>

#import "OFNSToOFBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSString_OFObject_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

/**
 * @category NSString (OFObject) NSString+OFObject.h ObjFWBridge/ObjFWBridge.h
 *
 * @brief Support for bridging an NSString to an @ref OFString.
 *
 * Unfortunately, they need to be copied, as NSString is not capable of
 * handling UCS-4 properly (a character of NSString is only 2 bytes, while a
 * character of OFString is 4).
 */
@interface NSString (OFObject) <OFNSToOFBridging>
@property (readonly, nonatomic) OFString *OFObject;
@end

OF_ASSUME_NONNULL_END
