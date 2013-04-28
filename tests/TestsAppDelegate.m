/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdlib.h>

#import "OFString.h"
#import "OFStdIOStream.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

#ifdef _PSP
# include <pspmoduleinfo.h>
# include <pspkernel.h>
# include <pspdebug.h>
PSP_MODULE_INFO("ObjFW Tests", 0, 0, 0);
#endif

#ifdef __wii__
# define BOOL OGC_BOOL
# include <gccore.h>
# include <wiiuse/wpad.h>
# undef BOOL
#endif

enum {
	NO_COLOR,
	RED,
	GREEN,
	YELLOW
};

int
main(int argc, char *argv[])
{
#if defined(OF_OBJFW_RUNTIME) && !defined(_WIN32)
	/* This does not work on Win32 if ObjFW is built as a DLL */
	atexit(objc_exit);
#endif

	/* We need deterministic hashes for tests */
	of_hash_seed = 0;

#ifdef __wii__
	GXRModeObj *rmode;
	void *xfb;

	VIDEO_Init();
	WPAD_Init();

	rmode = VIDEO_GetPreferredMode(NULL);
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
	VIDEO_Configure(rmode);
	VIDEO_SetNextFramebuffer(xfb);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();

	VIDEO_WaitVSync();
	if (rmode->viTVMode & VI_NON_INTERLACE)
		VIDEO_WaitVSync();

	CON_InitEx(rmode, 10, 20, rmode->fbWidth - 10, rmode->xfbHeight - 20);
	VIDEO_ClearFrameBuffer(rmode, xfb, COLOR_BLACK);

	@try {
		return of_application_main(&argc, &argv,
		    [TestsAppDelegate class]);
	} @catch (id e) {
		TestsAppDelegate *delegate =
		    [[OFApplication sharedApplication] delegate];
		OFString *string = [OFString stringWithFormat:
		    @"\nRuntime error: Unhandled exception:\n%@\n", e];

		[delegate outputString: string
			       inColor: RED];
		[delegate outputString: @"Press home button to exit!\n"
			       inColor: NO_COLOR];
		for (;;) {
			WPAD_ScanPads();

			if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME)
				[OFApplication terminateWithStatus: 1];

			VIDEO_WaitVSync();
		}
	}
#else
	return of_application_main(&argc, &argv, [TestsAppDelegate class]);
#endif
}

@implementation TestsAppDelegate
- (void)outputString: (OFString*)str
	     inColor: (int)color
{
#if defined(_PSP)
	char i, space = ' ';
	int y = pspDebugScreenGetY();

	pspDebugScreenSetXY(0, y);
	for (i = 0; i < 68; i++)
		pspDebugScreenPrintData(&space, 1);

	switch (color) {
	case 0:
		pspDebugScreenSetTextColor(0x00FFFF);
		break;
	case 1:
		pspDebugScreenSetTextColor(0x00FF00);
		break;
	case 2:
		pspDebugScreenSetTextColor(0x0000FF);
		break;
	}

	pspDebugScreenSetXY(0, y);
	pspDebugScreenPrintData([str UTF8String], [str UTF8StringLength]);
#elif defined(STDOUT)
	switch (color) {
	case NO_COLOR:
		[of_stdout writeString: @"\r\033[K"];
# ifdef __wii__
		[of_stdout writeString: @"\033[37m"];
# endif
		break;
	case RED:
		[of_stdout writeString: @"\r\033[K\033[31;1m"];
		break;
	case GREEN:
		[of_stdout writeString: @"\r\033[K\033[32;1m"];
		break;
	case YELLOW:
		[of_stdout writeString: @"\r\033[K\033[33;1m"];
		break;
	}

	[of_stdout writeString: str];
	[of_stdout writeString: @"\033[m"];
#else
# error No output method!
#endif
}

- (void)outputTesting: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%@] %@: testing...",
							module, test]
		   inColor: YELLOW];
	[pool release];
}

- (void)outputSuccess: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%@] %@: ok\n",
							module, test]
		   inColor: GREEN];
	[pool release];
}

- (void)outputFailure: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%@] %@: failed\n",
							module, test]
		   inColor: RED];
	[pool release];

#ifdef __wii__
	[self outputString: @"Press A to continue!\n"
		   inColor: NO_COLOR];
	for (;;) {
		WPAD_ScanPads();

		if (WPAD_ButtonsDown(0) & WPAD_BUTTON_A)
			return;

		VIDEO_WaitVSync();
	}
#endif
}

- (void)applicationDidFinishLaunching
{
#ifdef _PSP
	pspDebugScreenInit();
#endif
#ifdef __wii__
	[OFFile changeToDirectoryAtPath: @"/apps/objfw-tests"];
#endif

	[self objectTests];
#ifdef OF_HAVE_BLOCKS
	[self blockTests];
#endif
	[self MD5HashTests];
	[self SHA1HashTests];
	[self stringTests];
	[self dataArrayTests];
	[self arrayTests];
	[self dictionaryTests];
	[self listTests];
	[self setTests];
	[self dateTests];
	[self numberTests];
	[self streamTests];
#ifdef OF_HAVE_SOCKETS
	[self TCPSocketTests];
#endif
#ifdef OF_HAVE_THREADS
	[self threadTests];
#endif
	[self URLTests];
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self HTTPClientTests];
#endif
	[self XMLParserTests];
	[self XMLNodeTests];
	[self XMLElementBuilderTests];
	[self serializationTests];
	[self JSONTests];
#ifdef OF_HAVE_PLUGINS
	[self pluginTests];
#endif
	[self forwardingTests];
#ifdef OF_HAVE_PROPERTIES
	[self propertiesTests];
#endif

#ifdef __wii__
	[self outputString: @"Press home button to exit!\n"
		   inColor: NO_COLOR];
	for (;;) {
		WPAD_ScanPads();

		if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME)
			[OFApplication terminateWithStatus: _fails];

		VIDEO_WaitVSync();
	}
#else
	[OFApplication terminateWithStatus: _fails];
#endif
}
@end
