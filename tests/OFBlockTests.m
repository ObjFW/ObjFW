/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

	return objc_autorelease(Block_copy(^ int { return ++i; }));
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

	mallocBlock = objc_autorelease([stackBlock copy]);
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
	OTAssertEqual(objc_autorelease([globalBlock copy]), (id)globalBlock);
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

	mallocBlock = objc_autorelease([stackBlock copy]);
	OTAssertEqual(objc_autorelease([mallocBlock copy]), (id)mallocBlock);
	OTAssertEqual([mallocBlock retainCount], 2);
}
@end
