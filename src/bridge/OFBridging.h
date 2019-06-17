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

#ifdef OF_BRIDGE_LOCAL_INCLUDES
# import "macros.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/macros.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/*!
 * @protocol OFBridging OFBridging.h ObjFWBridge/OFBridging.h
 *
 * @brief A protocol implemented by classes supporting bridging ObjFW objects
 *	  to Foundation objects.
 */
@protocol OFBridging
/*!
 * @brief An instance of a Foundation object corresponding to the object.
 *
 * If possible, the original object is wrapped. If this is not possible, an
 * autoreleased copy is created.
 */
@property (readonly, nonatomic) id NSObject;
@end

OF_ASSUME_NONNULL_END
