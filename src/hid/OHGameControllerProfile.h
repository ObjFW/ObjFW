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

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OHGameControllerAxis;
@class OHGameControllerButton;
@class OHGameControllerDirectionalPad;

/**
 * @class OHGameControllerProfile \
 *	  OHGameControllerProfile.h ObjFWHID/OHGameControllerProfile.h
 *
 * @brief A profile for a @ref OHGameController.
 */
@interface OHGameControllerProfile: OFObject
{
	OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *_axes;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
	OF_RESERVE_IVARS(OHGameControllerProfile, 4)
}

/**
 * @brief A map of all button names to their @ref OHGameControllerButton.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *buttons;

/**
 * @brief A map of all axis names to their @ref OHGameControllerAxis.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *axes;

/**
 * @brief A map of all directional pads to their
 *	  @ref OHGameControllerDirectionalPad.
 */
@property (readonly, nonatomic) OFDictionary OF_GENERIC(OFString *,
    OHGameControllerDirectionalPad *) *directionalPads;
@end

OF_ASSUME_NONNULL_END
