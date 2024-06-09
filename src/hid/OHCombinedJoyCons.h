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

#import "OHExtendedGamepad.h"

OF_ASSUME_NONNULL_BEGIN

@class OHGameController;

/**
 * @class OHCombinedJoyCons OHCombinedJoyCons.h ObjFWHID/OHCombinedJoyCons.h
 *
 * @brief Combines a left and a right Joy-Con into a gamepad.
 */
@interface OHCombinedJoyCons: OHExtendedGamepad
{
	OHGameControllerProfile *_leftJoyCon, *_rightJoyCon;
}

/**
 * @brief Creates a new @ref OHCombinedJoyCons with the specified left and
 *	  right Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con
 * @param rightJoyCon The right Joy-Con
 * @return An new @ref OHCombinedJoyCons
 */
+ (instancetype)gamepadWithLeftJoyCon: (OHGameController *)leftJoyCon
			  rightJoyCon: (OHGameController *)rightJoyCon;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated @ref OHCombinedJoyCons with the
 *	  specified left and right Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con
 * @param rightJoyCon The right Joy-Con
 * @return An initialized @ref OHCombinedJoyCons
 */
- (instancetype)initWithLeftJoyCon: (OHGameController *)leftJoyCon
		       rightJoyCon: (OHGameController *)rightJoyCon;
@end

OF_ASSUME_NONNULL_END
