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

/** @file */

/**
 * @brief Asserts that the specified condition condition holds.
 *
 * @param condition The condition to check
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssert(condition, ...) \
	OTAssertImpl(self, _cmd, condition, @#condition, \
	    @__FILE__, __LINE__, ## __VA_ARGS__, nil)

/**
 * @brief Asserts that the specified condition is true.
 *
 * @param condition The condition to check
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertTrue(condition, ...) \
	OTAssert(condition == true, ## __VA_ARGS__)

/**
 * @brief Asserts that the specified condition is false.
 *
 * @param condition The condition to check
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertFalse(condition, ...) \
	OTAssert(condition == false, ## __VA_ARGS__)

/**
 * @brief Asserts that the two values are equal.
 *
 * @param a The value to check
 * @param b The expected value
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertEqual(a, b, ...) OTAssert(a == b, ## __VA_ARGS__)

/**
 * @brief Asserts that the two values are not equal.
 *
 * @param a The value to check
 * @param b The value `a` should not have
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertNotEqual(a, b, ...) OTAssert(a != b, ## __VA_ARGS__)

/**
 * @brief Asserts that the value is less than another value.
 *
 * @param a The value to check
 * @param b The value `a` should be less than
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertLessThan(a, b, ...) OTAssert(a < b, ## __VA_ARGS__)

/**
 * @brief Asserts that the value is less than or equal to another value.
 *
 * @param a The value to check
 * @param b The value `a` should be less than or equal to
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertLessThanOrEqual(a, b, ...) OTAssert(a <= b, ## __VA_ARGS__)

/**
 * @brief Asserts that the value is greater than another value.
 *
 * @param a The value to check
 * @param b The value `a` should be greater than
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertGreaterThan(a, b, ...) OTAssert(a > b, ## __VA_ARGS__)

/**
 * @brief Asserts that the value is greater than or equal to another value.
 *
 * @param a The value to check
 * @param b The value `a` should be greater than or equal to
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertGreaterThanOrEqual(a, b, ...) OTAssert(a >= b, ## __VA_ARGS__)

/**
 * @brief Asserts that the two objects are equal.
 *
 * @param a The object to check
 * @param b The object `a` is expected to be equal to
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertEqualObjects(a, b, ...) OTAssert([a isEqual: b], ## __VA_ARGS__)

/**
 * @brief Asserts that the two objects are not equal.
 *
 * @param a The object to check
 * @param b The object `a` is expected to be not equal to
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertNotEqualObjects(a, b, ...) \
	OTAssert(![a isEqual: b], ## __VA_ARGS__)

/**
 * @brief Asserts that the specified object is `nil`.
 *
 * @param object The object to should be `nil`
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertNil(object, ...) OTAssert(object == nil, ## __VA_ARGS__)

/**
 * @brief Asserts that the specified object is not `nil`.
 *
 * @param object The object to should not be `nil`
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
#define OTAssertNotNil(object, ...) OTAssert(object != nil, ## __VA_ARGS__)

/**
 * @brief Asserts that the specified expression throws an exception.
 *
 * @param expression The expression that should throw
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
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

/**
 * @brief Asserts that the specified expression throws a specific exception.
 *
 * @param expression The expression that should throw
 * @param exception The exception the expression should throw (as just the
 *		    class name, without quotes)
 * @param ... An optional format string to print if the assertion failed,
 *	      followed by optional arguments
 */
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

/**
 * @brief Skips the current test, making it neither fail nor succeeed.
 *
 * @param ... An optional format string to print why the test was skipped,
 *	      followed by optional arguments
 */
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
