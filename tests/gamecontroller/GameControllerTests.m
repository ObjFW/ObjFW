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
#import "OFGameController.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

@interface GameControllerTests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(GameControllerTests)

@implementation GameControllerTests
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFArray *controllers = [OFGameController controllers];

	[OFStdOut clear];

	for (;;) {
		[OFStdOut setCursorPosition: OFMakePoint(0, 0)];

		for (OFGameController *controller in controllers) {
			OFArray *buttons =
			    controller.buttons.allObjects.sortedArray;
			size_t i = 0;

			[OFStdOut setForegroundColor: [OFColor green]];
			[OFStdOut writeLine: controller.name];

			for (OFString *button in buttons) {
				bool pressed = [controller.pressedButtons
				    containsObject: button];

				[OFStdOut setForegroundColor: (pressed
				    ? [OFColor yellow] : [OFColor gray])];

				[OFStdOut writeFormat: @"[%@]", button];

				if (++i == 5) {
					[OFStdOut writeString: @"\n"];
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

		[OFThread sleepForTimeInterval: 1.f / 60.f];
	}
}
@end
