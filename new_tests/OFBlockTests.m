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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFBlockTests: OTTestCase
@end

#if defined(OF_OBJFW_RUNTIME)
extern struct objc_class _NSConcreteStackBlock;
extern struct objc_class _NSConcreteGlobalBlock;
extern struct objc_class _NSConcreteMallocBlock;
#elif defined(OF_APPLE_RUNTIME)
extern void *_NSConcreteStackBlock;
extern void *_NSConcreteGlobalBlock;
extern void *_NSConcreteMallocBlock;
#endif

/* Clang on Win32 generates broken code that crashes for global blocks. */
#if !defined(OF_WINDOWS) || !defined(__clang__)
static void (^globalBlock)(void) = ^ {};
#endif

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

@implementation OFBlockTests
- (void)testClassOfStackBlock
{
	__block int x;
	void (^stackBlock)(void) = ^ {
		x = 0;
		(void)x;
	};

	OTAssertEqual((Class)&_NSConcreteStackBlock,
	    objc_getClass("OFStackBlock"));
	OTAssertTrue([stackBlock isKindOfClass: [OFBlock class]]);
}

#if !defined(OF_WINDOWS) || !defined(__clang__)
- (void)testClassOfGlobalBlock
{
	OTAssertEqual((Class)&_NSConcreteGlobalBlock,
	    objc_getClass("OFGlobalBlock"));
	OTAssertTrue([globalBlock isKindOfClass: [OFBlock class]]);
}
#endif

- (void)testClassOfMallocBlock
{
	OTAssertEqual((Class)&_NSConcreteMallocBlock,
	    objc_getClass("OFMallocBlock"));
}

- (void)testCopyStackBlock
{
	__block int x;
	void (^stackBlock)(void) = ^ {
		x = 0;
		(void)x;
	};
	void (^mallocBlock)(void);

	mallocBlock = [[stackBlock copy] autorelease];
	OTAssertEqual([mallocBlock class], objc_getClass("OFMallocBlock"));
	OTAssertTrue([mallocBlock isKindOfClass: [OFBlock class]]);
}

- (void)testCopyStackBlockAndReferenceVariable
{
	OTAssertEqual(forwardTest(), 5);
}

- (void)testCopyStackBlockAndReferenceCopiedVariable
{
	int (^voidBlock)(void) = returnStackBlock();

	OTAssertEqual(voidBlock(), 43);
	OTAssertEqual(voidBlock(), 44);
	OTAssertEqual(voidBlock(), 45);
}

#if !defined(OF_WINDOWS) || !defined(__clang__)
- (void)testCopyGlobalBlock
{
	OTAssertEqual([[globalBlock copy] autorelease], (id)globalBlock);
}
#endif

- (void)testCopyMallocBlock
{
	__block int x;
	void (^stackBlock)(void) = ^ {
		x = 0;
		(void)x;
	};
	void (^mallocBlock)(void);

	mallocBlock = [[stackBlock copy] autorelease];
	OTAssertEqual([[mallocBlock copy] autorelease], (id)mallocBlock);
	OTAssertEqual([mallocBlock retainCount], 2);
}
@end
