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
 * @protocol OHGamepad OHGamepad.h ObjFWHID/OHGamepad.h
 *
 * @brief A game controller profile representing a gamepad.
 */
@protocol OHGamepad <OHGameControllerProfile>
/**
 * @brief The north button on the gamepad's diamond pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *northButton;

/**
 * @brief The south button on the gamepad's diamond pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *southButton;

/**
 * @brief The west button on the gamepad's diamond pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *westButton;

/**
 * @brief The east button on the gamepad's diamond pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *eastButton;

/**
 * @brief The left shoulder button.
 */
@property (readonly, nonatomic) OHGameControllerButton *leftShoulderButton;

/**
 * @brief The right shoulder button.
 */
@property (readonly, nonatomic) OHGameControllerButton *rightShoulderButton;

/**
 * @brief The menu button, sometimes also called start button.
 */
@property (readonly, nonatomic) OHGameControllerButton *menuButton;

/**
 * @brief The options button, sometimes also called select button.
 */
@property (readonly, nonatomic) OHGameControllerButton *optionsButton;

/**
 * @brief The D-Pad.
 */
@property (readonly, nonatomic) OHGameControllerDirectionalPad *dPad;
@end

OF_ASSUME_NONNULL_END
