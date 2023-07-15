/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import <Foundation/NSValue.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFNumber;

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSNumber_OFObject_reference;
#ifdef __cplusplus
}
#endif

/**
 * @category NSNumber (OFObject)
 *	     NSNumber+OFObject.h ObjFWBridge/NSNumber+OFObject.h
 *
 * @brief Support for bridging NSNumbers to OFNumbers.
 */
@interface NSNumber (OFObject) <NSBridging>
@property (readonly, nonatomic) OFNumber *OFObject;
@end

OF_ASSUME_NONNULL_END
