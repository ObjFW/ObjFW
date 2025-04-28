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
#import "OFColor.h"
#import "OFDictionary.h"
#import "OFMethodSignature.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFThread.h"
#import "OFValue.h"

#import "OTTestCase.h"

#import "OHGameController.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerProfile.h"

#import "OTAssertionFailedException.h"
#import "OTTestSkippedException.h"

#ifdef OF_IOS
# include <CoreFoundation/CoreFoundation.h>
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
		objc_release(lastConsoleUpdate);
		lastConsoleUpdate = nil;
		lastConsoleUpdate = [[OFDate alloc] init];
	}
}
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS) || \
    defined(OF_NINTENDO_SWITCH)
# define red maroon
# define lime green
# define yellow olive
# define fuchsia purple
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
#elif defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	[OFStdIOStream setUpConsole];
#elif defined(OF_NINTENDO_SWITCH)
	consoleInit(NULL);
	updateConsole(true);
#endif
}

- (OFMutableSet OF_GENERIC(Class) *)testClasses
{
	Class *classes;
	int classesCount;
	OFMutableSet *testClasses;

	classesCount = objc_getClassList(NULL, 0);
	if (classesCount < 1)
		return nil;

	classes = OFAllocMemory(classesCount, sizeof(Class));
	@try {
		if ((int)objc_getClassList(classes, classesCount) !=
		    classesCount)
			return nil;

		testClasses = [OFMutableSet set];

		for (int i = 0; i < classesCount; i++) {
			/*
			 * Make sure the class is initialized.
			 * Required for the ObjFW runtime, as otherwise
			 * class_getSuperclass() crashes.
			 */
#ifdef OF_OBJFW_RUNTIME
			[classes[i] class];
#endif

			/*
			 * Don't use +[isSubclassOfClass:], as the Apple runtime
			 * can return (presumably internal?) classes that don't
			 * implement it, resulting in a crash.
			 */
			if (isSubclassOfClass(classes[i], [OTTestCase class]))
				[testClasses addObject: classes[i]];
		}
	} @finally {
		OFFreeMemory(classes);
	}

	[testClasses removeObject: [OTTestCase class]];

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
		OFStdOut.foregroundColor = [OFColor olive];
		[OFStdOut writeFormat: @"-[%@ ", class];
		OFStdOut.bold = true;
		OFStdOut.foregroundColor = [OFColor yellow];
		[OFStdOut writeFormat: @"%s", sel_getName(test)];
		OFStdOut.bold = false;
		OFStdOut.foregroundColor = [OFColor olive];
		[OFStdOut writeString: @"]: "];
		break;
	case StatusOk:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setCursorColumn: 0];
			[OFStdOut eraseLine];
			OFStdOut.foregroundColor = [OFColor green];
			[OFStdOut writeFormat: @"-[%@ ", class];
			OFStdOut.bold = true;
			OFStdOut.foregroundColor = [OFColor lime];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			OFStdOut.bold = false;
			OFStdOut.foregroundColor = [OFColor green];
			[OFStdOut writeLine: @"]: ok"];
		} else
			[OFStdOut writeLine: @"ok"];
		break;
	case StatusFailed:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setCursorColumn: 0];
			[OFStdOut eraseLine];
			OFStdOut.foregroundColor = [OFColor maroon];
			[OFStdOut writeFormat: @"-[%@ ", class];
			OFStdOut.bold = true;
			OFStdOut.foregroundColor = [OFColor red];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			OFStdOut.bold = false;
			OFStdOut.foregroundColor = [OFColor maroon];
			[OFStdOut writeLine: @"]: failed"];
		} else
			[OFStdOut writeLine: @"failed"];

		if (description != nil)
			[OFStdOut writeLine: description];

		break;
	case StatusSkipped:
		if (OFStdOut.hasTerminal) {
			[OFStdOut setCursorColumn: 0];
			[OFStdOut eraseLine];
			OFStdOut.foregroundColor = [OFColor gray];
			[OFStdOut writeFormat: @"-[%@ ", class];
			OFStdOut.bold = true;
			OFStdOut.foregroundColor = [OFColor silver];
			[OFStdOut writeFormat: @"%s", sel_getName(test)];
			OFStdOut.bold = false;
			OFStdOut.foregroundColor = [OFColor gray];
			[OFStdOut writeLine: @"]: skipped"];
		} else
			[OFStdOut writeLine: @"skipped"];

		if (description != nil)
			[OFStdOut writeLine: description];

		break;
	}

	if (status == StatusFailed) {
#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS) || \
    defined(OF_NINTENDO_SWITCH)
		OFStdOut.foregroundColor = [OFColor silver];
		[OFStdOut writeLine: @"Press A to continue"];

# ifdef OF_NINTENDO_SWITCH
		while (appletMainLoop()) {
# else
		for (;;) {
# endif
			void *pool = objc_autoreleasePoolPush();
			OHGameController *controller =
			    [[OHGameController controllers] objectAtIndex: 0];
			OHGameControllerButton *button =
			    [controller.profile.buttons objectForKey: @"A"];

			[controller updateState];

			if (button.pressed)
				break;

# ifdef OF_NINTENDO_SWITCH
			updateConsole(true);
# else
			[OFThread waitForVerticalBlank];
# endif

			objc_autoreleasePoolPop(pool);
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
	OFMutableSet OF_GENERIC(Class) *testClasses;
	size_t numSucceeded = 0, numFailed = 0, numSkipped = 0;
	OFMutableDictionary *summaries = [OFMutableDictionary dictionary];

	if ([OFApplication arguments].count > 0) {
		testClasses = [OFMutableSet set];

		for (OFString *className in [OFApplication arguments]) {
			Class class = objc_lookUpClass([className
			    cStringWithEncoding: OFStringEncodingASCII]);

			if (class == Nil ||
			    !isSubclassOfClass(class, [OTTestCase class])) {
				[OFStdErr writeFormat: @"%@ is not a valid "
						       @"test case!\n",
						       className];
				[OFApplication terminateWithStatus: 1];
			}

			[testClasses addObject: class];
		}
	} else
		testClasses = [self testClasses];

	OFStdOut.foregroundColor = [OFColor purple];
	[OFStdOut writeString: @"Running "];
	OFStdOut.bold = true;
	OFStdOut.foregroundColor = [OFColor fuchsia];
	[OFStdOut writeFormat: @"%zu", testClasses.count];
	OFStdOut.bold = false;
	OFStdOut.foregroundColor = [OFColor purple];
	[OFStdOut writeFormat: @" test case%s\n",
			       (testClasses.count != 1 ? "s" : "")];

	for (Class class in testClasses) {
		OFArray *summary;

		OFStdOut.foregroundColor = [OFColor teal];
		[OFStdOut writeFormat: @"Running ", class];
		OFStdOut.bold = true;
		OFStdOut.foregroundColor = [OFColor aqua];
		[OFStdOut writeFormat: @"%@\n", class];
		OFStdOut.bold = false;

		for (OFValue *test in [self testsInClass: class]) {
			void *pool = objc_autoreleasePoolPush();
			bool failed = false, skipped = false;
			OTTestCase *instance;

			[self printStatusForTest: test.pointerValue
					 inClass: class
					  status: StatusRunning
				     description: nil];

			instance = objc_autorelease([[class alloc] init]);

			@try {
				SEL selector;
				IMP method;

				[instance setUp];

				selector = test.pointerValue;
				method = [instance methodForSelector: selector];
				((void (*)(id, SEL))method)(instance, selector);
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

		OFStdOut.foregroundColor = [OFColor teal];
		[OFStdOut writeString: @"Summary for "];
		OFStdOut.bold = true;
		OFStdOut.foregroundColor = [OFColor aqua];
		[OFStdOut writeFormat: @"%@\n", class];
		OFStdOut.bold = false;

		for (OFPair *line in summary) {
			OFStdOut.foregroundColor = [OFColor navy];
			[OFStdOut writeFormat: @"%@: ", line.firstObject];
			OFStdOut.bold = true;
			OFStdOut.foregroundColor = [OFColor blue];
			[OFStdOut writeFormat: @"%@\n", line.secondObject];
			OFStdOut.bold = false;
		}
	}

	OFStdOut.bold = true;
	OFStdOut.foregroundColor = [OFColor fuchsia];
	[OFStdOut writeFormat: @"%zu", numSucceeded];
	OFStdOut.bold = false;
	OFStdOut.foregroundColor = [OFColor purple];
	[OFStdOut writeFormat: @" test%s succeeded, ",
			       (numSucceeded != 1 ? "s" : "")];
	OFStdOut.bold = true;
	OFStdOut.foregroundColor = [OFColor fuchsia];
	[OFStdOut writeFormat: @"%zu", numFailed];
	OFStdOut.bold = false;
	OFStdOut.foregroundColor = [OFColor purple];
	[OFStdOut writeFormat: @" test%s failed, ",
			       (numFailed != 1 ? "s" : "")];
	OFStdOut.bold = true;
	OFStdOut.foregroundColor = [OFColor fuchsia];
	[OFStdOut writeFormat: @"%zu", numSkipped];
	OFStdOut.bold = false;
	OFStdOut.foregroundColor = [OFColor purple];
	[OFStdOut writeFormat: @" test%s skipped\n",
			       (numSkipped != 1 ? "s" : "")];
	[OFStdOut reset];

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	OFStdOut.foregroundColor = [OFColor silver];
# ifdef OF_WII
	[OFStdOut writeLine: @"Press Home button to exit"];
# else
	[OFStdOut writeLine: @"Press Start button to exit"];
# endif

	for (;;) {
		void *pool = objc_autoreleasePoolPush();
		OHGameController *controller =
		    [[OHGameController controllers] objectAtIndex: 0];
		OHGameControllerButton *button =
# ifdef OF_WII
		    [controller.profile.buttons objectForKey: @"Home"];
# else
		    [controller.profile.buttons objectForKey: @"Start"];
# endif

		[controller updateState];

		if (button.pressed)
			break;

		[OFThread waitForVerticalBlank];

		objc_autoreleasePoolPop(pool);
	}
#elif defined(OF_NINTENDO_SWITCH)
	while (appletMainLoop())
		updateConsole(true);

	consoleExit(NULL);
#endif

	[OFApplication terminateWithStatus: (int)numFailed];
}
@end
