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
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHGameControllerDirectionalPad \
 *	  OHGameControllerDirectionalPad.h 
 *	  ObjFWHID/OHGameControllerDirectionalPad.h
 *
 * @brief An directional pad or thumb stick of a game controller.
 */
OF_SUBCLASSING_RESTRICTED
@interface OHGameControllerDirectionalPad: OHGameControllerElement
{
	OHGameControllerAxis *_xAxis, *_yAxis;
	OHGameControllerButton *_up, *_down, *_left, *_right;
}

/**
 * @brief The X axis of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerAxis *xAxis;

/**
 * @brief The Y axis of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerAxis *yAxis;

/**
 * @brief The up button of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *up;

/**
 * @brief The down button of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *down;

/**
 * @brief The left button of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *left;

/**
 * @brief The right button of the directional pad.
 */
@property (readonly, nonatomic) OHGameControllerButton *right;

- (instancetype)initWithName: (OFString *)name OF_UNAVAILABLE;

- (instancetype)initWithName: (OFString *)name
		       xAxis: (OHGameControllerAxis *)xAxis
		       yAxis: (OHGameControllerAxis *)yAxis;

- (instancetype)initWithName: (OFString *)name
			  up: (OHGameControllerButton *)up
			down: (OHGameControllerButton *)down
			left: (OHGameControllerButton *)left
		       right: (OHGameControllerButton *)right;
@end

OF_ASSUME_NONNULL_END
