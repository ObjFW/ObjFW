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

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableSet OF_GENERIC(ObjectType);
@class OFSet OF_GENERIC(ObjectType);

/**
 * @brief A button on a controller.
 *
 * Possible values are:
 *
 *   * @ref OFGameControllerButtonA
 *   * @ref OFGameControllerButtonB
 *   * @ref OFGameControllerButtonC
 *   * @ref OFGameControllerButtonX
 *   * @ref OFGameControllerButtonY
 *   * @ref OFGameControllerButtonZ
 *   * @ref OFGameControllerButtonL
 *   * @ref OFGameControllerButtonR
 *   * @ref OFGameControllerButtonZL
 *   * @ref OFGameControllerButtonZR
 *   * @ref OFGameControllerButtonSelect
 *   * @ref OFGameControllerButtonStart
 *   * @ref OFGameControllerButtonHome
 *   * @ref OFGameControllerButtonLeftStick
 *   * @ref OFGameControllerButtonRightStick
 *   * @ref OFGameControllerButtonDPadUp
 *   * @ref OFGameControllerButtonDPadDown
 *   * @ref OFGameControllerButtonDPadLeft
 *   * @ref OFGameControllerButtonDPadRight
 *   * @ref OFGameControllerButtonCPadUp
 *   * @ref OFGameControllerButtonCPadDown
 *   * @ref OFGameControllerButtonCPadLeft
 *   * @ref OFGameControllerButtonCPadRight
 */
typedef OFConstantString *OFGameControllerButton;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The A button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonA;

/**
 * @brief The B button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonB;

/**
 * @brief The C button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonC;

/**
 * @brief The X button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonX;

/**
 * @brief The Y button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonY;

/**
 * @brief The Z button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonZ;

/**
 * @brief The L button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonL;

/**
 * @brief The R button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonR;

/**
 * @brief The ZL button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonZL;

/**
 * @brief The ZR button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonZR;

/**
 * @brief The Select button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonSelect;

/**
 * @brief The Start button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonStart;

/**
 * @brief The Home button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonHome;

/**
 * @brief The Capture button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonCapture;

/**
 * @brief The left stick button (pressing the left stick) on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonLeftStick;

/**
 * @brief The right stick button (pressing the right stick) on a game
 *	  controller.
 */
extern const OFGameControllerButton OFGameControllerButtonRightStick;

/**
 * @brief The D-Pad Up button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonDPadUp;

/**
 * @brief The D-Pad Down button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonDPadDown;

/**
 * @brief The D-Pad Left button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonDPadLeft;

/**
 * @brief The D-Pad Right button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonDPadRight;

/**
 * @brief The C-Pad Up button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonCPadUp;

/**
 * @brief The C-Pad Down button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonCPadDown;

/**
 * @brief The C-Pad Left button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonCPadLeft;

/**
 * @brief The C-Pad Right button on a game controller.
 */
extern const OFGameControllerButton OFGameControllerButtonCPadRight;
#ifdef __cplusplus
}
#endif

/**
 * @brief A class for reading state from a game controller.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFGameController: OFObject
{
#ifdef OF_LINUX
	OFString *_path;
	int _fd;
	uint16_t _vendorID, _productID;
	OFString *_name;
	OFMutableSet *_buttons, *_pressedButtons;
	bool _hasLeftAnalogStick, _hasRightAnalogStick;
	OFPoint _leftAnalogStickPosition, _rightAnalogStickPosition;
	int32_t _leftAnalogStickMinX, _leftAnalogStickMaxX;
	int32_t _leftAnalogStickMinY, _leftAnalogStickMaxY;
	int32_t _rightAnalogStickMinX, _rightAnalogStickMaxX;
	int32_t _rightAnalogStickMinY, _rightAnalogStickMaxY;
#endif
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFArray <OFGameController *> *controllers;
#endif

/**
 * @brief The name of the controller.
 */
@property (readonly, nonatomic, copy) OFString *name;

/**
 * @brief The buttons the controller has.
 */
@property (readonly, nonatomic, copy) OFSet OF_GENERIC(OFString *) *buttons;

/**
 * @brief The currently pressed buttons on the controller.
 */
@property (readonly, nonatomic, copy)
    OFSet OF_GENERIC(OFString *) *pressedButtons;

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
 */
@property (readonly, nonatomic) bool hasRightAnalogStick;

/**
 * @brief The position of the right analog stick.
 *
 * The range is from (-1, -1) to (1, 1).
 */
@property (readonly, nonatomic) OFPoint rightAnalogStickPosition;

/**
 * @brief Returns the available controllers.
 *
 * @return The available controllers
 */
+ (OFArray OF_GENERIC(OFGameController *) *)controllers;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
