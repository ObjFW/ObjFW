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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFColor.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFStdIOStream.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OHExtendedGamepad.h"
#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerProfile.h"
#import "OHGamepad.h"
#import "OHJoyConPair.h"
#import "OHLeftJoyCon.h"
#import "OHRightJoyCon.h"

#import "OFReadFailedException.h"

#if defined(OF_NINTENDO_DS)
static size_t buttonsPerLine = 2;
#elif defined(OF_NINTENDO_3DS)
static size_t buttonsPerLine = 3;
#else
static size_t buttonsPerLine = 5;
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS) || \
    defined(OF_NINTENDO_SWITCH)
# define red maroon
# define yellow olive
# define gray silver
#endif

#ifdef OF_NINTENDO_SWITCH
# define id nx_id
# include <switch.h>
# undef id
#endif

@interface GameControllerTests: OFObject <OFApplicationDelegate>
{
	OFArray OF_GENERIC(OHGameController *) *_controllers;
	OFDate *_lastControllersUpdate;
	OHJoyConPair *_joyConPair;
}
@end

OF_APPLICATION_DELEGATE(GameControllerTests)

static void printProfile(id <OHGameControllerProfile> profile)
{
	OFArray OF_GENERIC(OFString *) *buttons =
	    profile.buttons.allKeys.sortedArray;
	OFArray OF_GENERIC(OFString *) *axes = profile.axes.allKeys.sortedArray;
	OFArray OF_GENERIC(OFString *) *directionalPads =
	    profile.directionalPads.allKeys.sortedArray;
	size_t i;

	i = 0;
	for (OFString *name in buttons) {
		OHGameControllerButton *button =
		    [profile.buttons objectForKey: name];

		if (i++ == buttonsPerLine) {
			[OFStdOut writeString: @"\n"];
			i = 0;
		}

		if (button.value == 1)
			OFStdOut.foregroundColor = [OFColor red];
		else if (button.value > 0.5)
			OFStdOut.foregroundColor = [OFColor yellow];
		else if (button.value > 0)
			OFStdOut.foregroundColor = [OFColor green];
		else
			OFStdOut.foregroundColor = [OFColor gray];

		[OFStdOut writeFormat: @"[%@] ", name];
	}
	OFStdOut.foregroundColor = [OFColor gray];
	[OFStdOut writeString: @"\n"];

	i = 0;
	for (OFString *name in axes) {
		OHGameControllerAxis *axis = [profile.axes objectForKey: name];

		if (i++ == buttonsPerLine) {
			[OFStdOut writeString: @"\n"];
			i = 0;
		}

		[OFStdOut writeFormat: @"%@: %5.2f  ", name, axis.value];
	}
	if (axes.count > 0)
		[OFStdOut writeString: @"\n"];

	i = 0;
	for (OFString *name in directionalPads) {
		OHGameControllerDirectionalPad *directionalPad =
		    [profile.directionalPads objectForKey: name];

		if (i++ == 2) {
			[OFStdOut writeString: @"\n"];
			i = 0;
		}

		[OFStdOut writeFormat:
		    @"%@: (%5.2f, %5.2f)  ",
		    name,
		    directionalPad.xAxis.value, directionalPad.yAxis.value];
	}
	if (directionalPads.count > 0)
		[OFStdOut writeString: @"\n"];

	if ([profile conformsToProtocol: @protocol(OHGamepad)]) {
		id <OHGamepad> gamepad = (id <OHGamepad>)profile;

		[OFStdOut writeFormat:
		    @"[Map] North: %@  South: %@  West: %@  East: %@\n",
		    gamepad.northButton.name, gamepad.southButton.name,
		    gamepad.westButton.name, gamepad.eastButton.name];
		[OFStdOut writeFormat:
		    @"[Map] Left Shoulder: %@  Right Shoulder: %@\n",
		    gamepad.leftShoulderButton.name,
		    gamepad.rightShoulderButton.name];
	}

	if ([profile conformsToProtocol: @protocol(OHExtendedGamepad)]) {
		id <OHExtendedGamepad> extendedGamepad =
		    (id <OHExtendedGamepad>)profile;

		[OFStdOut writeFormat:
		    @"[Map] Left Trigger: %@  Right Trigger: %@\n",
		    extendedGamepad.leftTriggerButton.name,
		    extendedGamepad.rightTriggerButton.name];
		[OFStdOut writeFormat:
		    @"[Map] Left Thumbstick: %@  Right Thumbstick: %@\n",
		    extendedGamepad.leftThumbstickButton.name,
		    extendedGamepad.rightThumbstickButton.name];
	}

	if ([profile conformsToProtocol: @protocol(OHGamepad)]) {
		id <OHGamepad> gamepad = (id <OHGamepad>)profile;

		[OFStdOut writeFormat:
		    @"[Map] Menu: %@  Options: %@",
		    gamepad.menuButton.name, gamepad.optionsButton.name];
	}

	if ([profile conformsToProtocol: @protocol(OHExtendedGamepad)]) {
		id <OHExtendedGamepad> extendedGamepad =
		    (id <OHExtendedGamepad>)profile;

		[OFStdOut writeFormat: @"  Home: %@",
		    extendedGamepad.homeButton.name];
	}

	if ([profile conformsToProtocol: @protocol(OHGamepad)])
		[OFStdOut writeString: @"\n"];
}

@implementation GameControllerTests
- (void)updateOutput
{
	OHLeftJoyCon *leftJoyCon = nil;
	OHRightJoyCon *rightJoyCon = nil;

	if (_lastControllersUpdate == nil ||
	    -[_lastControllersUpdate timeIntervalSinceNow] > 1) {
		[_joyConPair release];
		[_controllers release];
		[_lastControllersUpdate release];

		_joyConPair = nil;
		_controllers = [[OHGameController controllers] retain];
		_lastControllersUpdate = [[OFDate alloc] init];

		[OFStdOut clear];
	}

	[OFStdOut setCursorPosition: OFMakePoint(0, 0)];

	for (OHGameController *controller in _controllers) {
		id <OHGameControllerProfile> profile = controller.profile;

		OFStdOut.foregroundColor = [OFColor green];
		[OFStdOut writeLine: controller.description];
		OFStdOut.foregroundColor = [OFColor teal];
		[OFStdOut writeFormat: @"Profile: %@\n", profile];

		@try {
			[controller updateState];
		} @catch (OFReadFailedException *e) {
			OFStdOut.foregroundColor = [OFColor red];
			[OFStdOut writeString: e.description];
			continue;
		}

		printProfile(profile);

		if ([profile isKindOfClass: [OHLeftJoyCon class]])
			leftJoyCon = (OHLeftJoyCon *)profile;
		else if ([profile isKindOfClass: [OHRightJoyCon class]])
			rightJoyCon = (OHRightJoyCon *)profile;

		if (_joyConPair == nil && leftJoyCon != nil &&
		    rightJoyCon != nil)
			_joyConPair = [[OHJoyConPair
			    gamepadWithLeftJoyCon: leftJoyCon
				      rightJoyCon: rightJoyCon] retain];
	}

	if (_joyConPair) {
		OFStdOut.foregroundColor = [OFColor green];
		[OFStdOut writeLine: @"Joy-Con Pair"];

		printProfile(_joyConPair);
	}

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	[OFThread waitForVerticalBlank];
#elif defined(OF_NINTENDO_SWITCH)
	consoleUpdate(NULL);
#endif
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	[OFStdIOStream setUpConsole];
#endif
#if defined(OF_NINTENDO_SWITCH)
	consoleInit(NULL);

	while (appletMainLoop()) {
		void *pool = objc_autoreleasePoolPush();

		[self updateOutput];

		objc_autoreleasePoolPop(pool);
	}
#else
	[OFTimer scheduledTimerWithTimeInterval: 1.f / 60.f
					 target: self
				       selector: @selector(updateOutput)
					repeats: true];
#endif
}
@end
