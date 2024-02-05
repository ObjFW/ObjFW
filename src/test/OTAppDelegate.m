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

#import "OFSet.h"
#import "OFValue.h"

#import "OTTestCase.h"

OF_APPLICATION_DELEGATE(OTAppDelegate)

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
			if ([*iter isSubclassOfClass: [OTTestCase class]])
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

	for (Class class in testClasses) {
		for (OFValue *test in [self testsInClass: class]) {
			void *pool = objc_autoreleasePoolPush();
			OTTestCase *instance =
			    [[[class alloc] init] autorelease];

			[instance setUp];
			[instance performSelector: test.pointerValue];
			[instance tearDown];

			objc_autoreleasePoolPop(pool);
		}
	}

	[OFApplication terminate];
}
@end
