/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFString.h"
#import "OFBlock.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#if defined(OF_OBJFW_RUNTIME)
# include <objfw-rt.h>
#elif defined(OF_GNU_RUNTIME)
# include <objc/objc-api.h>
#endif
#if defined(OF_GNU_RUNTIME) || defined(OF_OBJFW_RUNTIME)
# define objc_getClass objc_get_class
#endif

#import "TestsAppDelegate.h"

static OFString *module = @"OFBlock";

extern void *_NSConcreteStackBlock;
extern void *_NSConcreteGlobalBlock;
extern void *_NSConcreteMallocBlock;

@implementation TestsAppDelegate (OFBlockTests)
- (void)blockTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	__block int x;
	void (^s)() = ^ { x = 0; };
	void (^g)() = ^ {};
	void (^m)();

	TEST(@"Class of stack block",
	    (Class)&_NSConcreteStackBlock == objc_getClass("OFStackBlock") &&
	    [s isKindOfClass: [OFBlock class]])

	TEST(@"Class of global block",
	    (Class)&_NSConcreteGlobalBlock == objc_getClass("OFGlobalBlock") &&
	    [g isKindOfClass: [OFBlock class]])

	TEST(@"Class of a malloc block",
	    (Class)&_NSConcreteMallocBlock == objc_getClass("OFMallocBlock"))

	TEST(@"Copying a stack block",
	    (m = [s copy]) && [m class] == objc_getClass("OFMallocBlock") &&
	    [m isKindOfClass: [OFBlock class]])

	TEST(@"Copying a global block", (id)g == [g copy])

	TEST(@"Copying a malloc block",
	    (id)m == [m copy] && [m retainCount] == 2)

	TEST(@"Autorelease a stack block", R([s autorelease]))

	TEST(@"Autorelease a global block", R([g autorelease]))

	TEST(@"Autorelease a malloc block", R([m autorelease]))

	[pool drain];
}
@end
