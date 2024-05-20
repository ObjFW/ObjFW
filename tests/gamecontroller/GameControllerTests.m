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
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

#ifdef OF_WII
# define asm __asm__
# include <gccore.h>
# undef asm
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
# define BUTTONS_PER_LINE 2
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
# define BUTTONS_PER_LINE 3
#endif

#ifndef BUTTONS_PER_LINE
# define BUTTONS_PER_LINE 5
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
# define red maroon
# define yellow olive
# define gray silver
#endif

@interface GameControllerTests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(GameControllerTests)

@implementation GameControllerTests
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFArray *controllers;

#if defined(OF_WII)
	GXRModeObj *mode;
	void *nextFB;

	VIDEO_Init();

	mode = VIDEO_GetPreferredMode(NULL);
	nextFB = MEM_K0_TO_K1(SYS_AllocateFramebuffer(mode));
	VIDEO_Configure(mode);
	VIDEO_SetNextFramebuffer(nextFB);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();

	VIDEO_WaitVSync();
	if (mode->viTVMode & VI_NON_INTERLACE)
		VIDEO_WaitVSync();

	CON_InitEx(mode, 2, 2, mode->fbWidth - 4, mode->xfbHeight - 4);
	VIDEO_ClearFrameBuffer(mode, nextFB, COLOR_BLACK);
#elif defined(OF_NINTENDO_DS)
	consoleDemoInit();
#elif defined(OF_NINTENDO_3DS)
	gfxInitDefault();
	atexit(gfxExit);

	consoleInit(GFX_TOP, NULL);
#endif

	controllers = [OFGameController controllers];

	[OFStdOut clear];

	for (;;) {
		void *pool = objc_autoreleasePoolPush();

#ifdef OF_WII
		/* Wii needs some time before controllers are found. */
		controllers = [OFGameController controllers];
#endif

		[OFStdOut setCursorPosition: OFMakePoint(0, 0)];

		for (OFGameController *controller in controllers) {
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

				if (++i == BUTTONS_PER_LINE) {
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

		objc_autoreleasePoolPop(pool);
	}
}
@end
