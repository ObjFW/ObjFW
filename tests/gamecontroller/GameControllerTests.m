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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFColor.h"
#import "OFDate.h"
#import "OFGameController.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

#if defined(OF_NINTENDO_DS)
static size_t buttonsPerLine = 2;
#elif defined(OF_NINTENDO_3DS)
static size_t buttonsPerLine = 3;
#else
static size_t buttonsPerLine = 5;
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
# define red maroon
# define yellow olive
# define gray silver
#endif

@interface GameControllerTests: OFObject <OFApplicationDelegate>
{
	OFArray OF_GENERIC(OFGameController *) *_controllers;
	OFDate *_lastControllersUpdate;
}
@end

OF_APPLICATION_DELEGATE(GameControllerTests)

@implementation GameControllerTests
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	[OFStdIOStream setUpConsole];
#endif

	for (;;) {
		void *pool = objc_autoreleasePoolPush();

		if (_lastControllersUpdate == nil ||
		    -[_lastControllersUpdate timeIntervalSinceNow] > 1) {
			[_controllers release];
			[_lastControllersUpdate release];

			_controllers = [[OFGameController controllers] retain];
			_lastControllersUpdate = [[OFDate alloc] init];

			[OFStdOut clear];
		}

		[OFStdOut setCursorPosition: OFMakePoint(0, 0)];

		for (OFGameController *controller in _controllers) {
			OFArray OF_GENERIC(OFGameControllerButton) *buttons =
			    controller.buttons.allObjects.sortedArray;
			size_t i = 0;

			[OFStdOut setForegroundColor: [OFColor green]];
			[OFStdOut writeString: controller.description];

			[controller retrieveState];

			for (OFGameControllerButton button in buttons) {
				float pressure;

				if (i == 0)
					[OFStdOut writeString: @"\n"];

				pressure =
				    [controller pressureForButton: button];

				if (pressure == 1)
					[OFStdOut setForegroundColor:
					    [OFColor red]];
				else if (pressure > 0.5)
					[OFStdOut setForegroundColor:
					    [OFColor yellow]];
				else if (pressure > 0)
					[OFStdOut setForegroundColor:
					    [OFColor green]];
				else
					[OFStdOut setForegroundColor:
					    [OFColor gray]];

				[OFStdOut writeFormat: @"[%@]", button];

				if (++i == buttonsPerLine) {
					i = 0;
				} else
					[OFStdOut writeString: @" "];
			}
			[OFStdOut setForegroundColor: [OFColor gray]];
			[OFStdOut writeString: @"\n"];

			if (controller.hasLeftAnalogStick) {
				OFPoint position =
				    controller.leftAnalogStickPosition;
				[OFStdOut writeFormat: @"(%5.2f, %5.2f) ",
						       position.x, position.y];
			}
			if (controller.hasRightAnalogStick) {
				OFPoint position =
				    controller.rightAnalogStickPosition;
				[OFStdOut writeFormat: @"(%5.2f, %5.2f)",
						       position.x, position.y];
			}
			[OFStdOut writeString: @"\n"];
		}

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
		[OFThread waitForVerticalBlank];
#else
		[OFThread sleepForTimeInterval: 1.f / 60.f];
#endif

		objc_autoreleasePoolPop(pool);
	}
}
@end
