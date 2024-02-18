/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFApplication.h"
#import "OFColor.h"
#import "OFDictionary.h"
#import "OFMethodSignature.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFValue.h"

#import "OTTestCase.h"

#import "OTAssertionFailedException.h"
#import "OTTestSkippedException.h"

#ifdef OF_IOS
# include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef OF_WII
# define asm __asm__
# include <gccore.h>
# include <wiiuse/wpad.h>
# undef asm
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
#endif

#ifdef OF_NINTENDO_SWITCH
# define id nx_id
# include <switch.h>
# undef id

static OFDate *lastConsoleUpdate;

static void
updateConsole(bool force)
{
	if (force || lastConsoleUpdate.timeIntervalSinceNow <= -1.0 / 60) {
		consoleUpdate(NULL);
		[lastConsoleUpdate release];
		lastConsoleUpdate = [[OFDate alloc] init];
	}
}
#endif

@interface OTAppDelegate: OFObject <OFApplicationDelegate>
@end

enum Status {
	StatusRunning,
	StatusOk,
	StatusFailed,
	StatusSkipped
};

OF_APPLICATION_DELEGATE(OTAppDelegate)

static bool
isSubclassOfClass(Class class, Class superclass)
{
	for (Class iter = class; iter != Nil; iter = class_getSuperclass(iter))
		if (iter == superclass)
			return true;

	return false;
}

@implementation OTAppDelegate
+ (void)initialize
{
	if (self != [OTAppDelegate class])
		return;

#if defined(OF_IOS)
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
	UInt8 resourcesPath[PATH_MAX];

	if (!CFURLGetFileSystemRepresentation(resourcesURL, true, resourcesPath,
	    PATH_MAX)) {
		[OFStdErr writeLine: @"Failed to locate resources!"];
		[OFApplication terminateWithStatus: 1];
	}

	[[OFFileManager defaultManager] changeCurrentDirectoryPath:
	    [OFString stringWithUTF8String: (const char *)resourcesPath]];

	CFRelease(resourcesURL);
#elif defined(OF_WII)
	GXRModeObj *mode;
	void *nextFB;

	VIDEO_Init();
	WPAD_Init();

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
#elif defined(OF_NINTENDO_SWITCH)
	consoleInit(NULL);
	padConfigureInput(1, HidNpadStyleSet_NpadStandard);
	updateConsole(true);
#endif
}

- (OFSet OF_GENERIC(Class) *)testClasses
{
	Class *classes = objc_copyClassList(NULL);
	OFMutableSet *testClasses;

	if (classes == NULL)
		return nil;

	@try {
		testClasses = [OFMutableSet set];

		for (Class *iter = classes; *iter != Nil; iter++) {
			/*
			 * Make sure the class is initialized.
			 * Required for the ObjFW runtime, as otherwise
			 * class_getSuperclass() crashes.
			 */
#ifdef OF_OBJFW_RUNTIME
			[*iter class];
#endif

			/*
			 * Don't use +[isSubclassOfClass:], as the Apple runtime
			 * can return (presumably internal?) classes that don't
			 * implement it, resulting in a crash.
			 */
			if (isSubclassOfClass(*iter, [OTTestCase class]))
				[testClasses addObject: *iter];
		}
	} @finally {
		OFFreeMemory(classes);
	}

	[testClasses removeObject: [OTTestCase class]];

	[testClasses makeImmutable];
	return testClasses;
}

- (OFSet OF_GENERIC(OFValue *) *)testsInClass: (Class)class
{
	Method *methods = class_copyMethodList(class, NULL);
	OFMutableSet *tests;

	if (methods == NULL)
		return nil;

	@try {
		tests = [OFMutableSet set];

		for (Method *iter = methods; *iter != NULL; iter++) {
			SEL selector = method_getName(*iter);
			void *pool;
			OFMethodSignature *sig;

			if (selector == NULL)
				continue;

			if (strncmp(sel_getName(selector), "test", 4) != 0)
				continue;

			pool = objc_autoreleasePoolPush();
			sig = [OFMethodSignature signatureWithObjCTypes:
			    method_getTypeEncoding(*iter)];

			if (strcmp(sig.methodReturnType, "v") == 0 &&
			    sig.numberOfArguments == 2 &&
			    strcmp([sig argumentTypeAtIndex: 0], "@") == 0 &&
			    strcmp([sig argumentTypeAtIndex: 1], ":") == 0)
				[tests addObject:
				    [OFValue valueWithPointer: selector]];

			objc_autoreleasePoolPop(pool);
		}
	} @finally {
		OFFreeMemory(methods);
	}

	if (class_getSuperclass(class) != Nil)
		[tests unionSet:
		    [self testsInClass: class_getSuperclass(class)]];

	[tests makeImmutable];
	return tests;
}

- (void)printStatusForTest: (SEL)test
		   inClass: (Class)class
		    status: (enum Status)status
	       description: (OFString *)description
{
	switch (status) {
	case StatusRunning:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setForegroundColor: [OFColor olive]];
			[OFStdOut writeFormat: @"-[%@ ", class];
			[OFStdOut setForegroundColor: [OFColor yellow]];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			[OFStdOut setForegroundColor: [OFColor olive]];
			[OFStdOut writeString: @"]: "];
		} else
			[OFStdOut writeFormat: @"-[%@ %s]: ",
					       class, sel_getName(test)];
		break;
	case StatusOk:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setForegroundColor: [OFColor green]];
			[OFStdOut writeFormat: @"\r-[%@ ", class];
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			[OFStdOut setForegroundColor: [OFColor green]];
			[OFStdOut writeLine: @"]: ok"];
		} else
			[OFStdOut writeLine: @"ok"];
		break;
	case StatusFailed:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setForegroundColor: [OFColor maroon]];
			[OFStdOut writeFormat: @"\r-[%@ ", class];
			[OFStdOut setForegroundColor: [OFColor red]];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			[OFStdOut setForegroundColor: [OFColor maroon]];
			[OFStdOut writeLine: @"]: failed"];
			[OFStdOut writeLine: description];
		} else
			[OFStdOut writeLine: @"failed"];
		break;
	case StatusSkipped:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setForegroundColor: [OFColor gray]];
			[OFStdOut writeFormat: @"\r-[%@ ", class];
			[OFStdOut setForegroundColor: [OFColor silver]];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			[OFStdOut setForegroundColor: [OFColor gray]];
			[OFStdOut writeLine: @"]: skipped"];
		} else
			[OFStdOut writeLine: @"skipped"];

		if (description != nil)
			[OFStdOut writeLine: description];

		break;
	}

	if (status == StatusFailed) {
#if defined(OF_WII)
		[OFStdOut setForegroundColor: [OFColor silver]];
		[OFStdOut writeLine: @"Press A to continue"];

		for (;;) {
			WPAD_ScanPads();

			if (WPAD_ButtonsDown(0) & WPAD_BUTTON_A)
				break;

			VIDEO_WaitVSync();
		}
#elif defined(OF_NINTENDO_DS)
		[OFStdOut setForegroundColor: [OFColor silver]];
		[OFStdOut writeLine: @"Press A to continue"];

		for (;;) {
			swiWaitForVBlank();
			scanKeys();

			if (keysDown() & KEY_A)
				break;
		}
#elif defined(OF_NINTENDO_3DS)
		[OFStdOut setForegroundColor: [OFColor silver]];
		[OFStdOut writeLine: @"Press A to continue"];

		for (;;) {
			hidScanInput();

			if (hidKeysDown() & KEY_A)
				break;

			gspWaitForVBlank();
		}
#elif defined(OF_NINTENDO_SWITCH)
		[OFStdOut setForegroundColor: [OFColor silver]];
		[OFStdOut writeLine: @"Press A to continue"];

		while (appletMainLoop()) {
			PadState pad;

			padUpdate(&pad);
			updateConsole(true);

			if (padGetButtonsDown(&pad) & HidNpadButton_A)
				break;
		}
#endif
	}
}

- (OFString *)descriptionForException: (id)exception
{
	OFMutableString *description = [OFMutableString
	    stringWithFormat: @"Unhandled exception: %@",
			      exception];
	OFArray OF_GENERIC(OFValue *) *stackTraceAddresses = nil;
	OFArray OF_GENERIC(OFString *) *stackTraceSymbols = nil;
	OFStringEncoding encoding = [OFLocale encoding];

	if ([exception respondsToSelector: @selector(stackTraceAddresses)])
		stackTraceAddresses = [exception stackTraceAddresses];

	if (stackTraceAddresses != nil) {
		size_t count = stackTraceAddresses.count;

		if ([exception respondsToSelector:
		    @selector(stackTraceSymbols)])
			stackTraceSymbols = [exception stackTraceSymbols];

		if (stackTraceSymbols.count != count)
			stackTraceSymbols = nil;

		[description appendString: @"\n\nStack trace:"];

		if (stackTraceSymbols != nil) {
			for (size_t i = 0; i < count; i++) {
				void *address = [[stackTraceAddresses
				    objectAtIndex: i] pointerValue];
				const char *symbol = [[stackTraceSymbols
				    objectAtIndex: i]
				    cStringWithEncoding: encoding];

				[description appendFormat: @"\n  %p  %s",
							   address, symbol];
			}
		} else {
			for (size_t i = 0; i < count; i++) {
				void *address = [[stackTraceAddresses
				    objectAtIndex: i] pointerValue];

				[description appendFormat: @"\n  %p", address];
			}
		}
	}

	[description makeImmutable];

	return description;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFSet OF_GENERIC(Class) *testClasses = [self testClasses];
	size_t numSucceeded = 0, numFailed = 0, numSkipped = 0;
	OFMutableDictionary *summaries = [OFMutableDictionary dictionary];

	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeString: @"Found "];
#if !defined(OF_WII) && !defined(OF_NINTENDO_DS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_NINTENDO_SWITCH)
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
#endif
	[OFStdOut writeFormat: @"%zu", testClasses.count];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test case%s\n",
			       (testClasses.count != 1 ? "s" : "")];

	for (Class class in testClasses) {
		OFArray *summary;

		[OFStdOut setForegroundColor: [OFColor teal]];
		[OFStdOut writeFormat: @"Running ", class];
		[OFStdOut setForegroundColor: [OFColor aqua]];
		[OFStdOut writeFormat: @"%@\n", class];

		for (OFValue *test in [self testsInClass: class]) {
			void *pool = objc_autoreleasePoolPush();
			bool failed = false, skipped = false;
			OTTestCase *instance;

			[self printStatusForTest: test.pointerValue
					 inClass: class
					  status: StatusRunning
				     description: nil];

			instance = [[[class alloc] init] autorelease];

			@try {
				[instance setUp];
				[instance performSelector: test.pointerValue];
			} @catch (OTAssertionFailedException *e) {
				/*
				 * If an assertion fails during -[setUp], don't
				 * run the test.
				 * If an assertion fails during a test, abort
				 * the test.
				 */
				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: StatusFailed
					     description: e.description];

				failed = true;
			} @catch (OTTestSkippedException *e) {
				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: StatusSkipped
					     description: e.description];

				skipped = true;
			} @catch (id e) {
				OFString *description =
				    [self descriptionForException: e];

				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: StatusFailed
					     description: description];

				failed = true;
			}
			@try {
				[instance tearDown];
			} @catch (OTAssertionFailedException *e) {
				/*
				 * If an assertion fails during -[tearDown],
				 * abort the tear down.
				 */
				if (!failed) {
					SEL selector = test.pointerValue;
					OFString *description = e.description;

					[self printStatusForTest: selector
							 inClass: class
							  status: StatusFailed
						     description: description];

					failed = true;
				}
			} @catch (id e) {
				OFString *description =
				    [self descriptionForException: e];

				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: StatusFailed
					     description: description];

				failed = true;
			}

			if (failed)
				numFailed++;
			else if (skipped)
				numSkipped++;
			else {
				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: StatusOk
					     description: nil];

				numSucceeded++;
			}

			objc_autoreleasePoolPop(pool);
		}

		summary = [class summary];
		if (summary != nil)
			[summaries setObject: summary forKey: class];
	}

	for (Class class in summaries) {
		OFArray *summary = [summaries objectForKey: class];

		[OFStdOut setForegroundColor: [OFColor teal]];
		[OFStdOut writeString: @"Summary for "];
		[OFStdOut setForegroundColor: [OFColor aqua]];
		[OFStdOut writeFormat: @"%@\n", class];

		for (OFPair *line in summary) {
			[OFStdOut setForegroundColor: [OFColor navy]];
			[OFStdOut writeFormat: @"%@: ", line.firstObject];
			[OFStdOut setForegroundColor: [OFColor blue]];
			[OFStdOut writeFormat: @"%@\n", line.secondObject];
		}
	}

#if !defined(OF_WII) && !defined(OF_NINTENDO_DS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_NINTENDO_SWITCH)
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
#else
	[OFStdOut setForegroundColor: [OFColor purple]];
#endif
	[OFStdOut writeFormat: @"%zu", numSucceeded];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test%s succeeded, ",
			       (numSucceeded != 1 ? "s" : "")];
#if !defined(OF_WII) && !defined(OF_NINTENDO_DS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_NINTENDO_SWITCH)
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
#endif
	[OFStdOut writeFormat: @"%zu", numFailed];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test%s failed, ",
			       (numFailed != 1 ? "s" : "")];
#if !defined(OF_WII) && !defined(OF_NINTENDO_DS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_NINTENDO_SWITCH)
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
#endif
	[OFStdOut writeFormat: @"%zu", numSkipped];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test%s skipped\n",
			       (numSkipped != 1 ? "s" : "")];
	[OFStdOut reset];

#if defined(OF_WII)
	[OFStdOut setForegroundColor: [OFColor silver]];
	[OFStdOut writeLine: @"Press home button to exit"];

	for (;;) {
		WPAD_ScanPads();

		if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME)
			break;

		VIDEO_WaitVSync();
	}
#elif defined(OF_NINTENDO_DS)
	[OFStdOut setForegroundColor: [OFColor silver]];
	[OFStdOut writeLine: @"Press start button to exit"];

	for (;;) {
		swiWaitForVBlank();
		scanKeys();

		if (keysDown() & KEY_START)
			break;
	}
#elif defined(OF_NINTENDO_3DS)
	[OFStdOut setForegroundColor: [OFColor silver]];
	[OFStdOut writeLine: @"Press start button to exit"];

	for (;;) {
		hidScanInput();

		if (hidKeysDown() & KEY_START)
			break;

		gspWaitForVBlank();
	}
#elif defined(OF_NINTENDO_SWITCH)
	while (appletMainLoop())
		updateConsole(true);

	consoleExit(NULL);
#endif

	[OFApplication terminateWithStatus: (int)numFailed];
}
@end
