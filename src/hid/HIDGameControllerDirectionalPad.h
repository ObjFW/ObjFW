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

#import "HIDGameControllerElement.h"
#import "HIDGameControllerAxis.h"
#import "HIDGameControllerButton.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief An directional pad or thumb stick of a game controller.
 */
OF_SUBCLASSING_RESTRICTED
@interface HIDGameControllerDirectionalPad: HIDGameControllerElement
{
	HIDGameControllerAxis *_xAxis, *_yAxis;
	HIDGameControllerButton *_upButton, *_downButton;
	HIDGameControllerButton *_leftButton, *_rightButton;
}

/**
 * @brief The X axis of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerAxis *xAxis;

/**
 * @brief The Y axis of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerAxis *yAxis;

/**
 * @brief The up button of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerButton *upButton;

/**
 * @brief The down button of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerButton *downButton;

/**
 * @brief The left button of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerButton *leftButton;

/**
 * @brief The right button of the directional pad.
 */
@property (readonly, nonatomic) HIDGameControllerButton *rightButton;

- (instancetype)initWithName: (OFString *)name OF_UNAVAILABLE;

- (instancetype)initWithName: (OFString *)name
		       xAxis: (HIDGameControllerAxis *)xAxis
		       yAxis: (HIDGameControllerAxis *)yAxis;

- (instancetype)initWithName: (OFString *)name
		    upButton: (HIDGameControllerButton *)upButton
		  downButton: (HIDGameControllerButton *)downButton
		  leftButton: (HIDGameControllerButton *)leftButton
		 rightButton: (HIDGameControllerButton *)rightButton;
@end

OF_ASSUME_NONNULL_END
