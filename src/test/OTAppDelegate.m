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

@interface OTAppDelegate: OFObject <OFApplicationDelegate>
@end

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

		for (Class *iter = classes; *iter != Nil; iter++) {
			/*
			 * Make sure the class is initialized.
			 * Required for the ObjFW runtime, as otherwise
			 * class_getSuperclass() crashes.
			 */
			[*iter class];

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
		    status: (int)status
	       description: (OFString *)description
{
	switch (status) {
	case 0:
		[OFStdOut setForegroundColor: [OFColor olive]];
		[OFStdOut writeFormat: @"-[%@ ", class];
		[OFStdOut setForegroundColor: [OFColor yellow]];
		[OFStdOut writeFormat: @"%s", sel_getName(test)];
		[OFStdOut setForegroundColor: [OFColor olive]];
		[OFStdOut writeString: @"]: "];
		break;
	case 1:
		[OFStdOut setForegroundColor: [OFColor green]];
		[OFStdOut writeFormat: @"\r-[%@ ", class];
		[OFStdOut setForegroundColor: [OFColor lime]];
		[OFStdOut writeFormat: @"%s", sel_getName(test)];
		[OFStdOut setForegroundColor: [OFColor green]];
		[OFStdOut writeLine: @"]: ok"];
		break;
	case 2:
		[OFStdOut setForegroundColor: [OFColor maroon]];
		[OFStdOut writeFormat: @"\r-[%@ ", class];
		[OFStdOut setForegroundColor: [OFColor red]];
		[OFStdOut writeFormat: @"%s", sel_getName(test)];
		[OFStdOut setForegroundColor: [OFColor maroon]];
		[OFStdOut writeLine: @"]: failed"];
		[OFStdOut writeLine: description];
		break;
	}
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFSet OF_GENERIC(Class) *testClasses = [self testClasses];
	size_t numSucceeded = 0, numFailed = 0;
	OFMutableDictionary *summaries = [OFMutableDictionary dictionary];

	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeString: @"Found "];
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
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
			bool failed = false;
			OTTestCase *instance;

			[self printStatusForTest: test.pointerValue
					 inClass: class
					  status: 0
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
						  status: 2
					     description: e.description];
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
							  status: 2
						     description: description];
					failed = true;
				}
			}

			if (!failed) {
				[self printStatusForTest: test.pointerValue
						 inClass: class
						  status: 1
					     description: nil];
				numSucceeded++;
			} else
				numFailed++;

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

	[OFStdOut setForegroundColor: [OFColor fuchsia]];
	[OFStdOut writeFormat: @"%zu", numSucceeded];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test%s succeeded, ",
			       (numSucceeded != 1 ? "s" : "")];
	[OFStdOut setForegroundColor: [OFColor fuchsia]];
	[OFStdOut writeFormat: @"%zu", numFailed];
	[OFStdOut setForegroundColor: [OFColor purple]];
	[OFStdOut writeFormat: @" test%s failed\n",
			       (numFailed != 1 ? "s" : "")];
	[OFStdOut reset];

	[OFApplication terminateWithStatus: (int)numFailed];
}
@end
