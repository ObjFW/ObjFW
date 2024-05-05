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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFSet OF_GENERIC(ObjectType);

/**
 * @brief A class for reading state from a game controller.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFGameController: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) size_t numControllers;
#endif

/**
 * @brief The buttons the controller has.
 */
@property (readonly, nonatomic) OFSet OF_GENERIC(OFString *) *buttons;

/**
 * @brief The currently pressed buttons on the controller.
 */
@property (readonly, nonatomic) OFSet OF_GENERIC(OFString *) *pressedButtons;

/**
 * @brief The number of analog sticks the controller has.
 */
@property (readonly, nonatomic) size_t numAnalogSticks;

/**
 * @brief Returns the number of available controllers.
 *
 * @return The number of available controllers
 */
+ (size_t)numControllers;

/**
 * @brief Returns the specified controller.
 *
 * @param index The index of the controller to return
 * @return The specified controller
 */
+ (OFGameController *)controllerWithIndex: (size_t)index;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns the current position of the specified analog stick.
 *
 * The range is from (-1, -1) to (1, 1).
 *
 * @param index The index of the analog stick whose position to return
 * @return The current position of the specified analog stick
 */
- (OFPoint)positionOfAnalogStickWithIndex: (size_t)index;
@end

OF_ASSUME_NONNULL_END
