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
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerProfile.h"

#import "OFReadFailedException.h"

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
	OFMutableArray OF_GENERIC(OHGameController *) *_controllers;
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

			_controllers = [[OHGameController controllers]
			    mutableCopy];
			_lastControllersUpdate = [[OFDate alloc] init];

			[OFStdOut clear];
		}

		[OFStdOut setCursorPosition: OFMakePoint(0, 0)];

		for (OHGameController *controller in _controllers) {
			OHGameControllerProfile *profile =
			    controller.rawProfile;
			OFArray OF_GENERIC(OFString *) *buttons =
			    profile.buttons.allKeys.sortedArray;
			OFArray OF_GENERIC(OFString *) *axes =
			    profile.axes.allKeys.sortedArray;
			size_t i;

			[OFStdOut setForegroundColor: [OFColor green]];
			[OFStdOut writeString: controller.description];

			@try {
				[controller retrieveState];
			} @catch (OFReadFailedException *e) {
				[OFStdOut setForegroundColor: [OFColor red]];
				[OFStdOut writeFormat: @"\n%@", e.description];
				continue;
			}

			i = 0;
			for (OFString *name in buttons) {
				OHGameControllerButton *button =
				    [profile.buttons objectForKey: name];

				if (i == 0)
					[OFStdOut writeString: @"\n"];

				if (button.value == 1)
					[OFStdOut setForegroundColor:
					    [OFColor red]];
				else if (button.value > 0.5)
					[OFStdOut setForegroundColor:
					    [OFColor yellow]];
				else if (button.value > 0)
					[OFStdOut setForegroundColor:
					    [OFColor green]];
				else
					[OFStdOut setForegroundColor:
					    [OFColor gray]];

				[OFStdOut writeFormat: @"[%@]", button.name];

				if (++i == buttonsPerLine) {
					i = 0;
				} else
					[OFStdOut writeString: @" "];
			}
			[OFStdOut setForegroundColor: [OFColor gray]];
			[OFStdOut writeString: @"\n"];

			i = 0;
			for (OFString *name in axes) {
				OHGameControllerAxis *axis =
				    [profile.axes objectForKey: name];

				if (i == 0)
					[OFStdOut writeString: @"\n"];

				[OFStdOut writeFormat: @"%@: %5.2f ",
						       name, axis.value];

				if (++i == buttonsPerLine) {
					i = 0;
				} else
					[OFStdOut writeString: @" "];
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
