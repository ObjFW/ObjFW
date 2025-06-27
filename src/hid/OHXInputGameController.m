/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OHXInputGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHXboxGamepad.h"
#import "OHXboxGamepad+Private.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#include <xinput.h>

#ifndef XINPUT_GAMEPAD_GUIDE
# define XINPUT_GAMEPAD_GUIDE 0x400
#endif

struct XInputCapabilitiesEx {
	XINPUT_CAPABILITIES capabilities;
	WORD vendorID;
	WORD productID;
	WORD versionNumber;
	WORD unknown1;
	DWORD unknown2;
};

static int XInputVersion;
static WINAPI DWORD (*XInputGetStateFuncPtr)(DWORD, XINPUT_STATE *);
static WINAPI DWORD (*XInputGetCapabilitiesExFuncPtr)(DWORD, DWORD, DWORD,
    struct XInputCapabilitiesEx *);

@implementation OHXInputGameController
@synthesize vendorID = _vendorID, productID = _productID;
@synthesize extendedGamepad = _extendedGamepad;

+ (void)initialize
{
	HMODULE module;

	if (self != [OHXInputGameController class])
		return;

	if ((module = LoadLibraryA("xinput1_4.dll")) != NULL) {
		XInputGetStateFuncPtr =
		    (WINAPI DWORD (*)(DWORD, XINPUT_STATE *))
		    GetProcAddress(module, (LPCSTR)100);
		XInputGetCapabilitiesExFuncPtr = (WINAPI DWORD (*)(DWORD, DWORD,
		    DWORD, struct XInputCapabilitiesEx *))
		    GetProcAddress(module, (LPCSTR)108);
		XInputVersion = 14;
	} else if ((module = LoadLibrary("xinput1_3.dll")) != NULL) {
		XInputGetStateFuncPtr =
		    (WINAPI DWORD (*)(DWORD, XINPUT_STATE *))
		    GetProcAddress(module, (LPCSTR)100);
		XInputVersion = 13;
	} else if ((module = LoadLibrary("xinput9_1_0.dll")) != NULL) {
		XInputGetStateFuncPtr =
		    (WINAPI DWORD (*)(DWORD, XINPUT_STATE *))
		    GetProcAddress(module, "XInputGetState");
		XInputVersion = 910;
	}
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];

	if (XInputGetStateFuncPtr != NULL) {
		void *pool = objc_autoreleasePoolPush();

		for (DWORD i = 0; i < XUSER_MAX_COUNT; i++) {
			OHGameController *controller;

			@try {
				controller = objc_autorelease(
				    [[OHXInputGameController alloc]
				    oh_initWithIndex: i]);
			} @catch (OFInitializationFailedException *e) {
				/* Controller does not exist. */
				continue;
			}

			[controllers addObject: controller];
		}

		objc_autoreleasePoolPop(pool);
	}

	[controllers makeImmutable];

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithIndex: (DWORD)index
{
	self = [super oh_init];

	@try {
		XINPUT_STATE state = { 0 };

		if (XInputGetStateFuncPtr(index, &state) ==
		    ERROR_DEVICE_NOT_CONNECTED)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_index = index;

		if (XInputGetCapabilitiesExFuncPtr != NULL) {
			struct XInputCapabilitiesEx capabilities;

			if (XInputGetCapabilitiesExFuncPtr(1, _index,
			    XINPUT_FLAG_GAMEPAD, &capabilities) ==
			    ERROR_SUCCESS) {
				_vendorID = [[OFNumber alloc]
				    initWithUnsignedShort:
				    capabilities.vendorID];
				_productID = [[OFNumber alloc]
				    initWithUnsignedShort:
				    capabilities.productID];
			}
		}

		_extendedGamepad = [[OHXboxGamepad alloc]
		    oh_initWithHasGuideButton: (XInputVersion != 910)];

		[self updateState];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_vendorID);
	objc_release(_productID);
	objc_release(_extendedGamepad);

	[super dealloc];
}

- (void)updateState
{
	XINPUT_STATE state = { 0 };

	if (XInputGetStateFuncPtr(_index, &state) != ERROR_SUCCESS)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: sizeof(state)
							    errNo: 0];

	[_extendedGamepad.northButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_Y)];
	[_extendedGamepad.southButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_A)];
	[_extendedGamepad.westButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_X)];
	[_extendedGamepad.eastButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_B)];
	[_extendedGamepad.leftShoulderButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER)];
	[_extendedGamepad.rightShoulderButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER)];
	[_extendedGamepad.leftThumbstickButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB)];
	[_extendedGamepad.rightThumbstickButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB)];
	[_extendedGamepad.menuButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_START)];
	[_extendedGamepad.optionsButton setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_BACK)];
	if (XInputVersion != 910)
		[_extendedGamepad.homeButton setValue:
		    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_GUIDE)];

	[_extendedGamepad.leftTriggerButton setValue:
	    (float)state.Gamepad.bLeftTrigger / 255];
	[_extendedGamepad.rightTriggerButton setValue:
	    (float)state.Gamepad.bRightTrigger / 255];

	[_extendedGamepad.leftThumbstick.xAxis setValue:
	    (float)state.Gamepad.sThumbLX /
	    (state.Gamepad.sThumbLX < 0 ? -INT16_MIN : INT16_MAX)];
	[_extendedGamepad.leftThumbstick.yAxis setValue:
	    -(float)state.Gamepad.sThumbLY /
	    (state.Gamepad.sThumbLY < 0 ? -INT16_MIN : INT16_MAX)];
	[_extendedGamepad.rightThumbstick.xAxis setValue:
	    (float)state.Gamepad.sThumbRX /
	    (state.Gamepad.sThumbRX < 0 ? -INT16_MIN : INT16_MAX)];
	[_extendedGamepad.rightThumbstick.yAxis setValue:
	    -(float)state.Gamepad.sThumbRY /
	    (state.Gamepad.sThumbRY < 0 ? -INT16_MIN : INT16_MAX)];

	[_extendedGamepad.dPad.up setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP)];
	[_extendedGamepad.dPad.down setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN)];
	[_extendedGamepad.dPad.left setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT)];
	[_extendedGamepad.dPad.right setValue:
	    !!(state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT)];
}

- (OFString *)name
{
	switch (XInputVersion) {
	case 14:
		return @"XInput 1.4 device";
	case 13:
		return @"XInput 1.3 device";
	case 910:
		return @"XInput 9.1.0 device";
	}

	return nil;
}

- (id <OHGameControllerProfile>)profile
{
	return _extendedGamepad;
}

- (id <OHGamepad>)gamepad
{
	return _extendedGamepad;
}
@end
