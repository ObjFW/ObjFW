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

#ifdef OBJFWHID_LOCAL_INCLUDES
# import "OFObject.h"
# import "OFString.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFObject.h>
#  import <ObjFW/OFString.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHGameControllerElement OHGameControllerElement.h ObjFWHID/ObjFWHID.h
 *
 * @brief An element of a game controller, e.g. a button, an axis or a
 *	  directional pad.
 */
@interface OHGameControllerElement: OFObject
{
	OFString *_name;
	bool _analog;
	OF_RESERVE_IVARS(OHGameControllerElement, 4)
}

/**
 * @brief The name of the game controller element.
 */
@property (readonly, nonatomic) OFString *name;

/**
 * @brief Whether the game controller element is analog.
 */
@property (readonly, nonatomic, getter=isAnalog) bool analog;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithName: (OFString *)name
		      analog: (bool)analog OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
