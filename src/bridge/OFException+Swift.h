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

#ifdef OF_BRIDGE_LOCAL_INCLUDES
# import "OFException.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFException.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

@interface OFException (Swift)
#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Execute the specified try block and call the catch block if an
 *	  OFException occurred.
 *
 * @note This is only useful to catch OFExceptions in Swift.
 *
 * @param try The try block to execute
 * @param catch The catch block to execute if an OFException occurred
 */
+ (void)try: (void (^)(void))try
      catch: (void (^)(OF_KINDOF(OFException *)))catch;

/*!
 * @brief Execute the specified try block and finally call the finally block.
 *
 * @note This is only useful for Swift.
 *
 * @param try The try block to execute
 * @param finally The finally block to call at the end
 */
+ (void)try: (void (^)(void))try
    finally: (void (^)(void))finally;

/*!
 * @brief Execute the specified try block and call the catch block if an
 *	  OFException occurred and finally call the finally block.
 *
 * @note This is only useful to catch OFExceptions in Swift.
 *
 * @param try The try block to execute
 * @param catch The catch block to execute if an OFException occurred
 * @param finally The finally block to call at the end
 */
+ (void)try: (void (^)(void))try
      catch: (void (^)(OF_KINDOF(OFException *)))catch
    finally: (void (^)(void))finally;
#endif

/*!
 * @brief Raises the exception.
 *
 * @note This is only useful to raise OFExceptions in Swift.
 */
- (void)throw OF_NO_RETURN;
@end

OF_ASSUME_NONNULL_END
