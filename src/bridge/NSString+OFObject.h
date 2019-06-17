/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import <Foundation/NSString.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSString_OFObject_reference;
#ifdef __cplusplus
}
#endif

/*!
 * @category NSString (OFObject)
 *	     NSString+OFObject.h ObjFWBridge/NSString+OFObject.h
 *
 * @brief Support for bridging NSStrings to OFStrings.
 *
 * Unfortunately, they need to be copied, as NSString is not capable of
 * handling UCS-4 properly (a character of NSString is only 2 bytes, while a
 * character of OFString is 4).
 */
@interface NSString (OFObject) <NSBridging>
@property (readonly, nonatomic) OFString *OFObject;
@end

OF_ASSUME_NONNULL_END
