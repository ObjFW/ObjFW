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

@class HIDGameControllerAxis;
@class HIDGameControllerButton;
@class HIDGameControllerDirectionalPad;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/**
 * @class HIDGameControllerMapping \
 *	  HIDGameControllerMapping.h ObjFWHID/HIDGameControllerMapping.h
 *
 * @brief A mapping for a @ref HIDGameController.
 */
@interface HIDGameControllerMapping: OFObject
{
	OFDictionary OF_GENERIC(OFString *, HIDGameControllerButton *)
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, HIDGameControllerAxis *) *_axes;
	OFDictionary OF_GENERIC(OFString *, HIDGameControllerDirectionalPad *)
	    *_directionalPads;
	OF_RESERVE_IVARS(HIDGameControllerMapping, 4)
}

/**
 * @brief A map of all button names to their @ref HIDGameControllerButton.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, HIDGameControllerButton *) *buttons;

/**
 * @brief A map of all axis names to their @ref HIDGameControllerAxis.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, HIDGameControllerAxis *) *axes;

/**
 * @brief A map of all directional pads to their
 *	  @ref HIDGameControllerDirectionalPad.
 */
@property (readonly, nonatomic) OFDictionary OF_GENERIC(OFString *,
    HIDGameControllerDirectionalPad *) *directionalPads;
@end

OF_ASSUME_NONNULL_END
