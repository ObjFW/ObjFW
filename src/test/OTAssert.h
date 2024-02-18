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

/*
 * Unfortunately, that's the only way to make all compilers happy with the GNU
 * extensions for variadic macros that are being used here.
 */
#pragma GCC system_header

#define OTAssert(cond, ...) \
	OTAssertImpl(self, _cmd, cond, @#cond, @__FILE__, __LINE__,	\
	    ## __VA_ARGS__, nil)
#define OTAssertTrue(cond, ...) OTAssert(cond == true, ## __VA_ARGS__)
#define OTAssertFalse(cond, ...) OTAssert(cond == false, ## __VA_ARGS__)
#define OTAssertEqual(a, b, ...) OTAssert(a == b, ## __VA_ARGS__)
#define OTAssertNotEqual(a, b, ...) OTAssert(a != b, ## __VA_ARGS__)
#define OTAssertLessThan(a, b, ...) OTAssert(a < b, ## __VA_ARGS__)
#define OTAssertLessThanOrEqual(a, b, ...) OTAssert(a <= b, ## __VA_ARGS__)
#define OTAssertGreaterThan(a, b, ...) OTAssert(a > b, ## __VA_ARGS__)
#define OTAssertGreaterThanOrEqual(a, b, ...) OTAssert(a >= b, ## __VA_ARGS__)
#define OTAssertEqualObjects(a, b, ...) OTAssert([a isEqual: b], ## __VA_ARGS__)
#define OTAssertNotEqualObjects(a, b, ...) \
	OTAssert(![a isEqual: b], ## __VA_ARGS__)
#define OTAssertNil(object, ...) OTAssert(object == nil, ## __VA_ARGS__)
#define OTAssertNotNil(object, ...) OTAssert(object != nil, ## __VA_ARGS__)
#define OTAssertThrows(expression, ...)				\
	{							\
		bool OTThrown = false;				\
		@try {						\
			expression;				\
		} @catch (id e) {				\
			OTThrown = true;			\
		}						\
		OTAssert(OTThrown, ## __VA_ARGS__);		\
	}
#define OTAssertThrowsSpecific(expression, exception, ...)	\
	{							\
		bool OTThrown = false;				\
		@try {						\
			expression;				\
		} @catch (exception *e) {			\
			OTThrown = true;			\
		}						\
		OTAssert(OTThrown, ## __VA_ARGS__);		\
	}
#define OTSkip(...) \
	OTSkipImpl(self, _cmd, @__FILE__, __LINE__, ## __VA_ARGS__, nil)

#ifdef __cplusplus
extern "C" {
#endif
extern void OTAssertImpl(id testCase, SEL test, bool condition, OFString *check,
    OFString *file, size_t line, ...);
extern void OTSkipImpl(id testCase, SEL test, OFString *file, size_t line, ...);
#ifdef __cplusplus
}
#endif
