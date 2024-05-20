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

/** @file */

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableSet OF_GENERIC(ObjectType);
@class OFNumber;
@class OFSet OF_GENERIC(ObjectType);

/**
 * @brief A button on a controller.
 *
 * Possible values are:
 *
 *  * @ref OFGameControllerNorthButton
 *  * @ref OFGameControllerSouthButton
 *  * @ref OFGameControllerWestButton
 *  * @ref OFGameControllerEastButton
 *  * @ref OFGameControllerLeftTriggerButton
 *  * @ref OFGameControllerRightTriggerButton
 *  * @ref OFGameControllerLeftShoulderButton
 *  * @ref OFGameControllerRightShoulderButton
 *  * @ref OFGameControllerLeftStickButton
 *  * @ref OFGameControllerRightStickButton
 *  * @ref OFGameControllerDPadUpButton
 *  * @ref OFGameControllerDPadDownButton
 *  * @ref OFGameControllerDPadLeftButton
 *  * @ref OFGameControllerDPadRightButton
 *  * @ref OFGameControllerStartButton
 *  * @ref OFGameControllerSelectButton
 *  * @ref OFGameControllerHomeButton
 *  * @ref OFGameControllerCaptureButton
 *  * @ref OFGameControllerSLButton
 *  * @ref OFGameControllerSRButton
 *  * @ref OFGameControllerAssistantButton
 */
typedef OFConstantString *OFGameControllerButton;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The north button on a game controller's diamond pad.
 */
extern const OFGameControllerButton OFGameControllerNorthButton;

/**
 * @brief The south button on a game controller's diamond pad.
 */
extern const OFGameControllerButton OFGameControllerSouthButton;

/**
 * @brief The west button on a game controller's diamond pad.
 */
extern const OFGameControllerButton OFGameControllerWestButton;

/**
 * @brief The east button on a game controller's diamond pad.
 */
extern const OFGameControllerButton OFGameControllerEastButton;

/**
 * @brief The left trigger button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerLeftTriggerButton;

/**
 * @brief The right trigger button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerRightTriggerButton;

/**
 * @brief The left shoulder button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerLeftShoulderButton;

/**
 * @brief The right shoulder button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerRightShoulderButton;

/**
 * @brief The left stick button (pressing the left stick) on a game controller.
 */
extern const OFGameControllerButton OFGameControllerLeftStickButton;

/**
 * @brief The right stick button (pressing the right stick) on a game
 *	  controller.
 */
extern const OFGameControllerButton OFGameControllerRightStickButton;

/**
 * @brief The D-Pad Up button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerDPadUpButton;

/**
 * @brief The D-Pad Down button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerDPadDownButton;

/**
 * @brief The D-Pad Left button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerDPadLeftButton;

/**
 * @brief The D-Pad Right button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerDPadRightButton;

/**
 * @brief The Start button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerStartButton;

/**
 * @brief The Select button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerSelectButton;

/**
 * @brief The Home button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerHomeButton;

/**
 * @brief The Capture button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerCaptureButton;

/**
 * @brief The SL button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerSLButton;

/**
 * @brief The SR button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerSRButton;

/**
 * @brief The Assistant button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerAssistantButton;
#ifdef __cplusplus
}
#endif

/**
 * @brief A class for reading state from a game controller.
 */
@interface OFGameController: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFArray <OFGameController *> *controllers;
#endif

/**
 * @brief The name of the controller.
 */
@property (readonly, nonatomic, copy) OFString *name;

/**
 * @brief The vendor ID of the controller or `nil` if unavailable.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFNumber *vendorID;

/**
 * @brief The product ID of the controller or `nil` if unavailable.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFNumber *productID;

/**
 * @brief The buttons the controller has.
 */
@property (readonly, nonatomic, copy)
    OFSet OF_GENERIC(OFGameControllerButton) *buttons;

/**
 * @brief The currently pressed buttons on the controller.
 */
@property (readonly, nonatomic, copy)
    OFSet OF_GENERIC(OFGameControllerButton) *pressedButtons;

/**
 * @brief Whether the controller has a left analog stick.
 */
@property (readonly, nonatomic) bool hasLeftAnalogStick;

/**
 * @brief The position of the left analog stick.
 *
 * The range is from (-1, -1) to (1, 1).
 */
@property (readonly, nonatomic) OFPoint leftAnalogStickPosition;

/**
 * @brief Whether the controller has a right analog stick.
 *
 * @note The Nintendo 64 controller has no right analog stick, however, the C
 *	 buttons are used to emulate one.
 */
@property (readonly, nonatomic) bool hasRightAnalogStick;

/**
 * @brief The position of the right analog stick.
 *
 * The range is from (-1, -1) to (1, 1).
 *
 * @note The Nintendo 64 controller has no right analog stick, however, the C
 *	 buttons are used to emulate one.
 */
@property (readonly, nonatomic) OFPoint rightAnalogStickPosition;

/**
 * @brief Returns the available controllers.
 *
 * @return The available controllers
 */
+ (OFArray OF_GENERIC(OFGameController *) *)controllers;

/**
 * @brief Retrieve the current state from the game controller.
 *
 * The state returned by @ref OFGameController's messages does not change until
 * this method is called.
 *
 * @throw OFReadFailedException The controller's state could not be read
 */
- (void)retrieveState;

/**
 * @brief Returns how hard the specified button is pressed.
 *
 * The returned value is in the range from 0 to 1.
 *
 * @param button The button for which to return how hard it is pressed.
 * @return How hard the specified button is pressed
 */
- (float)pressureForButton: (OFGameControllerButton)button;
@end

OF_ASSUME_NONNULL_END
