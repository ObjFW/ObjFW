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

#include "config.h"

#import "OFGameController.h"
#import "OFArray.h"

const OFGameControllerButton OFGameControllerButtonA = @"A";
const OFGameControllerButton OFGameControllerButtonB = @"B";
const OFGameControllerButton OFGameControllerButtonC = @"C";
const OFGameControllerButton OFGameControllerButtonX = @"X";
const OFGameControllerButton OFGameControllerButtonY = @"Y";
const OFGameControllerButton OFGameControllerButtonZ = @"Z";
const OFGameControllerButton OFGameControllerButtonL = @"L";
const OFGameControllerButton OFGameControllerButtonR = @"R";
const OFGameControllerButton OFGameControllerButtonZL = @"ZL";
const OFGameControllerButton OFGameControllerButtonZR = @"ZR";
const OFGameControllerButton OFGameControllerButtonSelect = @"Select";
const OFGameControllerButton OFGameControllerButtonStart = @"Start";
const OFGameControllerButton OFGameControllerButtonHome = @"Home";
const OFGameControllerButton OFGameControllerButtonCapture = @"Capture";
const OFGameControllerButton OFGameControllerButtonLeftStick = @"Left Stick";
const OFGameControllerButton OFGameControllerButtonRightStick = @"Right Stick";
const OFGameControllerButton OFGameControllerButtonDPadUp = @"D-Pad Up";
const OFGameControllerButton OFGameControllerButtonDPadDown = @"D-Pad Down";
const OFGameControllerButton OFGameControllerButtonDPadLeft = @"D-Pad Left";
const OFGameControllerButton OFGameControllerButtonDPadRight = @"D-Pad Right";
const OFGameControllerButton OFGameControllerButtonCPadUp = @"C-Pad Up";
const OFGameControllerButton OFGameControllerButtonCPadDown = @"C-Pad Down";
const OFGameControllerButton OFGameControllerButtonCPadLeft = @"C-Pad Left";
const OFGameControllerButton OFGameControllerButtonCPadRight = @"C-Pad Right";
const OFGameControllerButton OFGameControllerButtonPlus = @"+";
const OFGameControllerButton OFGameControllerButtonMinus = @"-";
const OFGameControllerButton OFGameControllerButtonSL = @"SL";
const OFGameControllerButton OFGameControllerButtonSR = @"SR";
const OFGameControllerButton OFGameControllerButtonMode = @"Mode";

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "platform/Linux/OFGameController.m"
#elif defined(OF_WINDOWS)
# include "platform/Windows/OFGameController.m"
#elif defined(OF_NINTENDO_DS)
# include "platform/NintendoDS/OFGameController.m"
#elif defined(OF_NINTENDO_3DS)
# include "platform/Nintendo3DS/OFGameController.m"
#else
@implementation OFGameController
@dynamic name, buttons, pressedButtons, hasLeftAnalogStick;
@dynamic leftAnalogStickPosition, hasRightAnalogStick, rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	return [OFArray array];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (void)retrieveState
{
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	return 0;
}
@end
#endif
