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

#import "OHGameControllerElement.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHGameControllerButton \
 *	  OHGameControllerButton.h ObjFWHID/OHGameControllerButton.h
 *
 * @brief A button of a game controller.
 */
@interface OHGameControllerButton: OHGameControllerElement
{
	float _value;
	OF_RESERVE_IVARS(OHGameControllerButton, 4)
}

/**
 * @brief Whether the game controller button is pressed.
 */
@property (readonly, nonatomic, getter=isPressed) bool pressed;

/**
 * @brief The pressure with which the button is pressed.
 */
@property (nonatomic) float value;
@end

OF_ASSUME_NONNULL_END
