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

#import <Foundation/NSEnumerator.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFEnumerator OF_GENERIC(ObjectType);

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSEnumerator_OFObject_reference;
#ifdef __cplusplus
}
#endif

/**
 * @category NSEnumerator (OFObject) \
 *	     NSEnumerator+OFObject.h ObjFWBridge/NSEnumerator+OFObject.h
 *
 * @brief Support for bridging NSEnumerators to OFEnumerators.
 */
@interface NSEnumerator (OFObject) <NSBridging>
@property (readonly, nonatomic) OFEnumerator *OFObject;
@end

OF_ASSUME_NONNULL_END
