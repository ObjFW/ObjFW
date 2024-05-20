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
#import "OFNumber.h"
#import "OFSet.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "OFEvdevGameController.h"
#endif
#ifdef OF_WINDOWS
# include "OFXInputGameController.h"
#endif
#ifdef OF_WII
# include "OFWiiGameController.h"
#endif
#ifdef OF_NINTENDO_DS
# include "OFNintendoDSGameController.h"
#endif
#ifdef OF_NINTENDO_3DS
# include "OFNintendo3DSGameController.h"
#endif

const OFGameControllerButton OFGameControllerNorthButton = @"North";
const OFGameControllerButton OFGameControllerSouthButton = @"South";
const OFGameControllerButton OFGameControllerWestButton = @"West";
const OFGameControllerButton OFGameControllerEastButton = @"East";
const OFGameControllerButton OFGameControllerLeftTriggerButton =
    @"Left Trigger";
const OFGameControllerButton OFGameControllerRightTriggerButton =
    @"Right Trigger";
const OFGameControllerButton OFGameControllerLeftShoulderButton =
    @"Left Shoulder";
const OFGameControllerButton OFGameControllerRightShoulderButton =
    @"Right Shoulder";
const OFGameControllerButton OFGameControllerLeftStickButton = @"Left Stick";
const OFGameControllerButton OFGameControllerRightStickButton = @"Right Stick";
const OFGameControllerButton OFGameControllerDPadUpButton = @"D-Pad Up";
const OFGameControllerButton OFGameControllerDPadDownButton = @"D-Pad Down";
const OFGameControllerButton OFGameControllerDPadLeftButton = @"D-Pad Left";
const OFGameControllerButton OFGameControllerDPadRightButton = @"D-Pad Right";
const OFGameControllerButton OFGameControllerStartButton = @"Start";
const OFGameControllerButton OFGameControllerSelectButton = @"Select";
const OFGameControllerButton OFGameControllerHomeButton = @"Home";
const OFGameControllerButton OFGameControllerCaptureButton = @"Capture";

@implementation OFGameController
@dynamic name, buttons, pressedButtons, hasLeftAnalogStick;
@dynamic leftAnalogStickPosition, hasRightAnalogStick, rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	return [OFEvdevGameController controllers];
#elif defined(OF_WINDOWS)
	return [OFXInputGameController controllers];
#elif defined(OF_WII)
	return [OFWiiGameController controllers];
#elif defined(OF_NINTENDO_DS)
	return [OFNintendoDSGameController controllers];
#elif defined(OF_NINTENDO_3DS)
	return [OFNintendo3DSGameController controllers];
#else
	return [OFArray array];
#endif
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFGameController class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
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
	OF_UNRECOGNIZED_SELECTOR
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	return ([self.pressedButtons containsObject: button] ? 1 : 0);
}

- (OFString *)description
{
	if (self.vendorID != nil && self.productID != nil)
		return [OFString stringWithFormat:
		    @"<%@: %@ [%04X:%04X]>",
		    self.class, self.name, self.vendorID.unsignedShortValue,
		    self.productID.unsignedShortValue];
	else
		return [OFString stringWithFormat: @"<%@: %@>",
						   self.class, self.name];
}
@end

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "OFEvdevGameController.m"
#endif
#ifdef OF_WINDOWS
# include "OFXInputGameController.m"
#endif
#ifdef OF_WII
# include "OFWiiGameController.m"
#endif
#ifdef OF_NINTENDO_DS
# include "OFNintendoDSGameController.m"
#endif
#ifdef OF_NINTENDO_3DS
# include "OFNintendo3DSGameController.m"
#endif
