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

#import <Foundation/NSSet.h>

#import "NSBridging.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSet OF_GENERIC(ObjectType);

#ifdef __cplusplus
extern "C" {
#endif
extern int _NSSet_OFObject_reference;
#ifdef __cplusplus
}
#endif

/*!
 * @category NSSet (OFObject)
 *	     NSSet+OFObject.h ObjFWBridge/NSSet+OFObject.h
 *
 * @brief Support for bridging NSSets to OFSets.
 */
@interface NSSet (OFObject) <NSBridging>
@property (readonly, nonatomic) OFSet *OFObject;
@end

OF_ASSUME_NONNULL_END
