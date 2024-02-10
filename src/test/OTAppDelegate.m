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

#import "OTAppDelegate.h"

#import "OFColor.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFValue.h"

#import "OTTestCase.h"

#import "OTAssertionFailedException.h"

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
- (OFSet OF_GENERIC(Class) *)testClasses
{
	Class *classes = objc_copyClassList(NULL);
	OFMutableSet *testClasses;

	if (classes == NULL)
		return nil;

	@try {
		testClasses = [OFMutableSet set];

		for (Class *iter = classes; *iter != Nil; iter++)
			if (isSubclassOfClass(*iter, [OTTestCase class]))
				[testClasses addObject: *iter];
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

			if (selector == NULL)
				continue;

			if (strncmp(sel_getName(selector), "test", 4) == 0)
				[tests addObject:
				    [OFValue valueWithPointer: selector]];
		}
	} @finally {
		OFFreeMemory(methods);
	}

	[tests makeImmutable];
	return tests;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFSet OF_GENERIC(Class) *testClasses = [self testClasses];
	size_t numSucceeded = 0, numFailed = 0;

	[OFStdOut writeFormat: @"Running %zu test case(s)\n",
			       testClasses.count];

	for (Class class in testClasses) {
		[OFStdOut writeFormat: @"Running tests in %@\n", class];

		for (OFValue *test in [self testsInClass: class]) {
			void *pool = objc_autoreleasePoolPush();
			bool failed = false;
			OTTestCase *instance;

			[OFStdOut setForegroundColor: [OFColor yellow]];
			[OFStdOut writeFormat:
			    @"-[%@ %s]: ",
			    class, sel_getName(test.pointerValue)];

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
				[OFStdOut setForegroundColor: [OFColor red]];
				[OFStdOut writeFormat:
				    @"\r-[%@ %s]: failed\n",
				    class, sel_getName(test.pointerValue)];
				[OFStdOut writeLine: e.description];

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
					[OFStdOut setForegroundColor:
					    [OFColor red]];
					[OFStdOut writeFormat:
					    @"\r-[%@ %s]: failed\n",
					    class,
					    sel_getName(test.pointerValue)];
					[OFStdOut writeLine: e.description];

					failed = true;
				}
			}

			if (!failed) {
				[OFStdOut setForegroundColor: [OFColor green]];
				[OFStdOut writeFormat:
				    @"\r-[%@ %s]: ok\n",
				    class, sel_getName(test.pointerValue)];

				numSucceeded++;
			} else
				numFailed++;

			[OFStdOut reset];

			objc_autoreleasePoolPop(pool);
		}
	}

	[OFStdOut writeFormat: @"%zu test(s) succeeded, %zu test(s) failed.\n",
			       numSucceeded, numFailed];

	[OFApplication terminate];
}
@end
