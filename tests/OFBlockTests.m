/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFBlock";

#if defined(OF_OBJFW_RUNTIME)
extern struct objc_class _NSConcreteStackBlock;
extern struct objc_class _NSConcreteGlobalBlock;
extern struct objc_class _NSConcreteMallocBlock;
#elif defined(OF_APPLE_RUNTIME)
extern void *_NSConcreteStackBlock;
extern void *_NSConcreteGlobalBlock;
extern void *_NSConcreteMallocBlock;
#endif

static void (^globalBlock)(void) = ^ {};

static int
(^returnStackBlock(void))(void)
{
	__block int i = 42;

	return [Block_copy(^ int { return ++i; }) autorelease];
}

static double
forwardTest(void)
{
	__block double d;
	void (^block)(void) = Block_copy(^ {
		d = 5;
	});

	block();
	Block_release(block);

	return d;
}

@implementation TestsAppDelegate (OFBlockTests)
- (void)blockTests
{
	void *pool = objc_autoreleasePoolPush();
	__block int x;
	void (^stackBlock)(void) = ^ { x = 0; };
	void (^mallocBlock)(void);
	int (^voidBlock)(void);

	TEST(@"Class of stack block",
	    (Class)&_NSConcreteStackBlock == objc_getClass("OFStackBlock") &&
	    [stackBlock isKindOfClass: [OFBlock class]])

#if !defined(OF_WINDOWS) || !defined(__clang__) || !defined(OF_NO_SHARED)
	/*
	 * Causes a linker error on Windows with Clang when compiling as a
	 * static library. This is a bug in Clang.
	 */
	TEST(@"Class of global block",
	    (Class)&_NSConcreteGlobalBlock == objc_getClass("OFGlobalBlock") &&
	    [globalBlock isKindOfClass: [OFBlock class]])
#endif

	TEST(@"Class of a malloc block",
	    (Class)&_NSConcreteMallocBlock == objc_getClass("OFMallocBlock"))

	TEST(@"Copying a stack block",
	    (mallocBlock = [[stackBlock copy] autorelease]) &&
	    [mallocBlock class] == objc_getClass("OFMallocBlock") &&
	    [mallocBlock isKindOfClass: [OFBlock class]])

	TEST(@"Copying a stack block and referencing its variable",
	    forwardTest() == 5)

	TEST(@"Copying a stack block and using its copied variable",
	    (voidBlock = returnStackBlock()) && voidBlock() == 43 &&
	    voidBlock() == 44 && voidBlock() == 45)

	TEST(@"Copying a global block",
	    (id)globalBlock == [[globalBlock copy] autorelease])

#ifndef __clang_analyzer__
	TEST(@"Copying a malloc block",
	    (id)mallocBlock == [mallocBlock copy] &&
	    [mallocBlock retainCount] == 2)
#endif

	TEST(@"Autorelease a stack block", R([stackBlock autorelease]))

	TEST(@"Autorelease a global block", R([globalBlock autorelease]))

#ifndef __clang_analyzer__
	TEST(@"Autorelease a malloc block", R([mallocBlock autorelease]))
#endif

	objc_autoreleasePoolPop(pool);
}
@end
