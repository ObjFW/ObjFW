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

#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

#define FORMAT @"%@ %@ %@ %@ %@ %@ %@ %@ %@ %g %g %g %g %g %g %g %g %g"
#define ARGS @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", \
	    1.5, 2.25, 3.125, 4.0625, 5.03125, 6.5, 7.25, 8.0, 9.0
#define RESULT @"a b c d e f g h i 1.5 2.25 3.125 4.0625 5.03125 6.5 7.25 8 9"

@interface ForwardingTests: OTTestCase
@end

static size_t forwardingsCount = 0;
static bool success = false;
static id target = nil;

struct StretTest {
	char buffer[1024];
};

@interface ForwardingTestObject: OFObject
@end

@interface ForwardingTestObject (NonExistentMethods)
+ (void)test;
- (void)test;
- (uint32_t)forwardingTargetTest: (intptr_t)a0
				: (intptr_t)a1
				: (double)a2
				: (double)a3;
- (OFString *)forwardingTargetVarArgTest: (OFConstantString *)format, ...;
- (long double)forwardingTargetFPRetTest;
- (struct StretTest)forwardingTargetStRetTest;
- (void)forwardingTargetNilTest;
- (void)forwardingTargetSelfTest;
- (struct StretTest)forwardingTargetNilStRetTest;
- (struct StretTest)forwardingTargetSelfStRetTest;
@end

@interface ForwardingTarget: OFObject
@end

static void
test(id self, SEL _cmd)
{
	success = true;
}

@implementation ForwardingTests
- (void)setUp
{
	[super setUp];

	forwardingsCount = 0;
	success = false;
	target = nil;
}

- (void)testForwardingMessageAndAddingClassMethod
{
	[ForwardingTestObject test];
	OTAssertTrue(success);
	OTAssertEqual(forwardingsCount, 1);

	[ForwardingTestObject test];
	OTAssertEqual(forwardingsCount, 1);
}

- (void)forwardingMessageAndAddingInstanceMethod
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	[testObject test];
	OTAssertTrue(success);
	OTAssertEqual(forwardingsCount, 1);

	[testObject test];
	OTAssertEqual(forwardingsCount, 1);
}

#ifdef OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
- (void)testForwardingTargetForSelector
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertEqual(
	    [testObject forwardingTargetTest: 0xDEADBEEF
					    : -1
					    : 1.25
					    : 2.75], 0x12345678);
}

- (void)testForwardingTargetForSelectorWithVariableArguments
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertEqualObjects(
	    ([testObject forwardingTargetVarArgTest: FORMAT, ARGS]), RESULT);
}

/*
 * Don't try fpret on Win64 if we don't have stret forwarding, as long double
 * is handled as a struct there.
 *
 * Don't try fpret on macOS on x86_64 with the Apple runtime as a regression
 * was introduced in either macOS 14 or 15 where objc_msgSend_fpret calls the
 * stret forwarding handler instead of the regular one.
 */
# if !(defined(OF_WINDOWS) && defined(OF_AMD64) && \
    defined(OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET)) && \
    !(defined(OF_APPLE_RUNTIME) && defined(OF_AMD64))
- (void)testForwardingTargetForSelectorFPRet
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertEqual([testObject forwardingTargetFPRetTest],
	    12345678.00006103515625);
}
# endif

# ifdef OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
- (void)testForwardingTargetForSelectorStRet
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertEqual(memcmp([testObject forwardingTargetStRetTest].buffer,
	    "abcdefghijklmnopqrstuvwxyz", 27), 0);
}
# endif

- (void)testForwardingTargetForSelectorReturningNilThrows
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertThrowsSpecific([testObject forwardingTargetNilTest],
	    OFNotImplementedException);
}

- (void)testForwardingTargetForSelectorReturningSelfThrows
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertThrowsSpecific([testObject forwardingTargetSelfTest],
	    OFNotImplementedException);
}

# ifdef OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
- (void)testForwardingTargetForSelectorStRetReturningNilThrows
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertThrowsSpecific([testObject forwardingTargetNilStRetTest],
	    OFNotImplementedException);
}

- (void)testForwardingTargetForSelectorStRetReturningSelfThrows
{
	ForwardingTestObject *testObject =
	    objc_autorelease([[ForwardingTestObject alloc] init]);

	target = objc_autorelease([[ForwardingTarget alloc] init]);

	OTAssertThrowsSpecific([testObject forwardingTargetSelfStRetTest],
	    OFNotImplementedException);
}
# endif
#endif
@end

@implementation ForwardingTestObject
+ (bool)resolveClassMethod: (SEL)selector
{
	forwardingsCount++;

	if (sel_isEqual(selector, @selector(test))) {
		class_replaceMethod(object_getClass(self), @selector(test),
		    (IMP)test, "v#:");
		return YES;
	}

	return NO;
}

+ (bool)resolveInstanceMethod: (SEL)selector
{
	forwardingsCount++;

	if (sel_isEqual(selector, @selector(test))) {
		class_replaceMethod(self, @selector(test), (IMP)test, "v@:");
		return YES;
	}

	return NO;
}

- (id)forwardingTargetForSelector: (SEL)selector
{
	/*
	 * Do some useless calculations in as many registers as possible to
	 * check if the arguments are properly saved and restored.
	 */
	volatile register intptr_t r0 = 0, r1 = 1, r2 = 2, r3 = 3, r4 = 4,
	    r5 = 5, r6 = 6, r7 = 7, r8 = 8, r9 = 9, r10 = 10, r11 = 11;
	volatile register double f0 = 0.5, f1 = 1.5, f2 = 2.5, f3 = 3.5,
	    f4 = 4.5, f5 = 5.5, f6 = 6.5, f7 = 7.5, f8 = 8.5, f9 = 9.5,
	    f10 = 10.5, f11 = 11.5;
	double add = r0 * r1 * r2 * r3 * r4 * r5 * r6 * r7 * r8 * r9 * r10 *
	    r11 * f0 * f1 * f2 * f3 * f4 * f5 * f6 * f7 * f8 * f9 * f10 * f11;

	if (sel_isEqual(selector, @selector(forwardingTargetTest::::)) ||
	    sel_isEqual(selector, @selector(forwardingTargetVarArgTest:)) ||
	    sel_isEqual(selector, @selector(forwardingTargetFPRetTest)) ||
	    sel_isEqual(selector, @selector(forwardingTargetStRetTest)))
		return (id)((char *)target + (ptrdiff_t)add);

	if (sel_isEqual(selector, @selector(forwardingTargetNilTest)) ||
	    sel_isEqual(selector, @selector(forwardingTargetNilStRetTest)))
		return nil;

	if (sel_isEqual(selector, @selector(forwardingTargetSelfTest)) ||
	    sel_isEqual(selector, @selector(forwardingTargetSelfStRetTest)))
		return self;

	abort();

	OF_UNREACHABLE
}
@end

@implementation ForwardingTarget
- (uint32_t)forwardingTargetTest: (intptr_t)a0
				: (intptr_t)a1
				: (double)a2
				: (double)a3
{
	OTAssertEqual(self, target);

	if (a0 != (intptr_t)0xDEADBEEF)
		return 0;
	if (a1 != -1)
		return 0;
	if (a2 != 1.25)
		return 0;
	if (a3 != 2.75)
		return 0;

	return 0x12345678;
}

- (OFString *)forwardingTargetVarArgTest: (OFConstantString *)format, ...
{
	va_list args;
	OFString *ret;

	OTAssertEqual(self, target);

	va_start(args, format);
	ret = [[OFString alloc] initWithFormat: format arguments: args];
	va_end(args);

	return objc_autoreleaseReturnValue(ret);
}

- (long double)forwardingTargetFPRetTest
{
	OTAssertEqual(self, target);

	return 12345678.00006103515625;
}

- (struct StretTest)forwardingTargetStRetTest
{
	struct StretTest ret = { { 0 } };

	OTAssertEqual(self, target);

	memcpy(ret.buffer, "abcdefghijklmnopqrstuvwxyz", 27);

	return ret;
}
@end
