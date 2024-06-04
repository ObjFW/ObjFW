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

#import "OHGameControllerProfile.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHGamepad OHGamepad.h ObjFWHID/OHGamepad.h
 *
 * @brief A game controller profile representing a gamepad.
 */
@interface OHGamepad: OHGameControllerProfile
{
	OF_RESERVE_IVARS(OHGamepad, 4)
}

@property (readonly, nonatomic) OHGameControllerButton *northButton;
@property (readonly, nonatomic) OHGameControllerButton *southButton;
@property (readonly, nonatomic) OHGameControllerButton *westButton;
@property (readonly, nonatomic) OHGameControllerButton *eastButton;
@property (readonly, nonatomic) OHGameControllerButton *leftShoulderButton;
@property (readonly, nonatomic) OHGameControllerButton *rightShoulderButton;
@property (readonly, nonatomic) OHGameControllerButton *leftTriggerButton;
@property (readonly, nonatomic) OHGameControllerButton *rightTriggerButton;
@property (readonly, nonatomic) OHGameControllerButton *leftThumbstickButton;
@property (readonly, nonatomic) OHGameControllerButton *rightThumbstickButton;
@property (readonly, nonatomic) OHGameControllerButton *menuButton;
@property (readonly, nonatomic) OHGameControllerButton *optionsButton;
@property (readonly, nonatomic) OHGameControllerButton *homeButton;
@property (readonly, nonatomic) OHGameControllerDirectionalPad *leftThumbstick;
@property (readonly, nonatomic) OHGameControllerDirectionalPad *rightThumbstick;
@property (readonly, nonatomic) OHGameControllerDirectionalPad *directionalPad;
@end

OF_ASSUME_NONNULL_END
