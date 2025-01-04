/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OHExtendedGamepad.h"

OF_ASSUME_NONNULL_BEGIN

@class NSString;
@class OFSet OF_GENERIC(ObjectType);
@class OHGameControllerButton;
@class OHGameControllerDirectionalPad;
@class OHLeftJoyCon;
@class OHRightJoyCon;

/**
 * @class OHJoyConPair OHJoyConPair.h ObjFWHID/ObjFWHID.h
 *
 * @brief Combines a left and a right Joy-Con into a gamepad.
 */
OF_SUBCLASSING_RESTRICTED
@interface OHJoyConPair: OFObject <OHExtendedGamepad>
{
	OHLeftJoyCon *_leftJoyCon;
	OHRightJoyCon *_rightJoyCon;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
}

/**
 * @brief Creates a new Joy-Con pair with the specified left and right Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con for the pair
 * @param rightJoyCon The right Joy-Con for the pair
 * @return An new Joy-Con pair
 */
+ (instancetype)gamepadWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
			  rightJoyCon: (OHRightJoyCon *)rightJoyCon;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated Joy-Con pair with the specified left
 *	  and right Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con for the pair
 * @param rightJoyCon The right Joy-Con for the pair
 * @return An initialized Joy-Con pair
 */
- (instancetype)initWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
		       rightJoyCon: (OHRightJoyCon *)rightJoyCon;
@end

OF_ASSUME_NONNULL_END
