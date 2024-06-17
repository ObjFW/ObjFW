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

#import "OHGamepad.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OHExtendedGamepad OHExtendedGamepad.h ObjFWHID/ObjFWHID.h
 *
 * @brief A game controller profile representing a gamepad.
 */
@protocol OHExtendedGamepad <OHGamepad>
/**
 * @brief The left trigger button.
 */
@property (readonly, nonatomic) OHGameControllerButton *leftTriggerButton;

/**
 * @brief The right trigger button.
 */
@property (readonly, nonatomic) OHGameControllerButton *rightTriggerButton;

/**
 * @brief The left thumb stick button.
 *
 * This button is optional and may be `nil`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OHGameControllerButton *leftThumbstickButton;

/**
 * @brief The right thumb stick button.
 *
 * This button is optional and may be `nil`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OHGameControllerButton *rightThumbstickButton;

/**
 * @brief The home button.
 *
 * This button is optional and may be `nil`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OHGameControllerButton *homeButton;

/**
 * @brief The left thumb stick.
 */
@property (readonly, nonatomic) OHGameControllerDirectionalPad *leftThumbstick;

/**
 * @brief The right thumb stick.
 */
@property (readonly, nonatomic) OHGameControllerDirectionalPad *rightThumbstick;
@end

OF_ASSUME_NONNULL_END
