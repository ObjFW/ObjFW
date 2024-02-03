/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifdef OF_BRIDGE_LOCAL_INCLUDES
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
extern int _OFNumber_NSObject_reference;
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
