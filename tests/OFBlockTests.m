/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

static OFString *module = @"OFBlock";

extern struct objc_abi_class _NSConcreteStackBlock;
extern struct objc_abi_class _NSConcreteGlobalBlock;
extern struct objc_abi_class _NSConcreteMallocBlock;

static void (^g)(void) = ^ {};

static int
(^returnStackBlock(void))(void)
{
	__block int i = 42;

	return Block_copy(^ int { return ++i; });
}

static double
forwardTest(void)
{
	__block double d;
	void (^b)(void) = Block_copy(^ {
		d = 5;
	});

	b();
	Block_release(b);

	return d;
}

@implementation TestsAppDelegate (OFBlockTests)
- (void)blockTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	__block int x;
	void (^s)(void) = ^ { x = 0; };
	void (^m)(void);
	int (^v)(void);

	TEST(@"Class of stack block",
	    (Class)&_NSConcreteStackBlock == objc_getClass("OFStackBlock") &&
	    [s isKindOfClass: [OFBlock class]])

#if !defined(OF_WINDOWS) || !defined(__clang__) || !defined(OF_NO_SHARED)
	/*
	 * Causes a linker error on Windows with Clang when compiling as a
	 * static library. This is a bug in Clang.
	 */
	TEST(@"Class of global block",
	    (Class)&_NSConcreteGlobalBlock == objc_getClass("OFGlobalBlock") &&
	    [g isKindOfClass: [OFBlock class]])
#endif

	TEST(@"Class of a malloc block",
	    (Class)&_NSConcreteMallocBlock == objc_getClass("OFMallocBlock"))

	TEST(@"Copying a stack block",
	    (m = [[s copy] autorelease]) &&
	    [m class] == objc_getClass("OFMallocBlock") &&
	    [m isKindOfClass: [OFBlock class]])

	TEST(@"Copying a stack block and referencing its variable",
	    forwardTest() == 5)

	TEST(@"Copying a stack block and using its copied variable",
	    (v = returnStackBlock()) && v() == 43 && v() == 44 && v() == 45)

	TEST(@"Copying a global block", (id)g == [[g copy] autorelease])

#ifndef __clang_analyzer__
	TEST(@"Copying a malloc block",
	    (id)m == [m copy] && [m retainCount] == 2)
#endif

	TEST(@"Autorelease a stack block", R([s autorelease]))

	TEST(@"Autorelease a global block", R([g autorelease]))

#ifndef __clang_analyzer__
	TEST(@"Autorelease a malloc block", R([m autorelease]))
#endif

	[pool drain];
}
@end
