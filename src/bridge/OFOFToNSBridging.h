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
# import "macros.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/macros.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFOFToNSBridging OFOFToNSBridging.h ObjFWBridge/ObjFWBridge.h
 *
 * @brief A protocol implemented by classes supporting bridging ObjFW objects
 *	  to Foundation objects.
 */
@protocol OFOFToNSBridging
/**
 * @brief An instance of a Foundation object corresponding to the object.
 *
 * If possible, the original object is wrapped. If this is not possible, an
 * autoreleased copy is created.
 */
@property (readonly, nonatomic) id NSObject;
@end

OF_ASSUME_NONNULL_END
