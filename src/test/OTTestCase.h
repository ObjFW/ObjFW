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

#ifdef OBJFWTEST_LOCAL_INCLUDES
# import "ObjFW.h"
#else
# import <ObjFW/ObjFW.h>
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class meant for subclassing to create a test case, consisting of
 *	  one or more tests.
 *
 * All methods with the prefix `test` that take no arguments of all classes
 * that subclass this class are automatically executed by ObjFWTest.
 *
 * @note ABI stability for this and all other classes in ObjFWTest is not
 *	 guaranteed! The assumption is that you recompile your tests after
 *	 updating ObjFWTest.
 */
@interface OTTestCase: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nullable, nonatomic)
    OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *summary;
#endif

/**
 * @brief Returns a summary for the test case that should be printed once all
 *	  tests in all test cases were run.
 *
 * This is mostly useful to print something at the end of all tests that needs
 * manual verification.
 */
+ (nullable OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *)summary;

/**
 * @brief Set up method that is run before every test in the test case.
 */
- (void)setUp;

/**
 * @brief Tear down method that is run after every test in the test case.
 */
- (void)tearDown;
@end

OF_ASSUME_NONNULL_END
