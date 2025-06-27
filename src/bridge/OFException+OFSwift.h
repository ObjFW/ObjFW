/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#ifdef OBJFWBRIDGE_LOCAL_INCLUDES
# import "OFException.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFException.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @category OFException (OFSwift) OFException+OFSwift.h
 *	     ObjFWBridge/ObjFWBridge.h
 *
 * @brief Support for throwing and catching an @ref OFException in Swift.
 */
@interface OFException (OFSwift)
#ifdef OF_HAVE_BLOCKS
/**
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

/**
 * @brief Execute the specified try block and finally call the finally block.
 *
 * @note This is only useful for Swift.
 *
 * @param try The try block to execute
 * @param finally The finally block to call at the end
 */
+ (void)try: (void (^)(void))try finally: (void (^)(void))finally;

/**
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

/**
 * @brief Raises the exception.
 *
 * @note This is only useful to raise OFExceptions in Swift.
 */
- (void)throw OF_NO_RETURN;
@end

OF_ASSUME_NONNULL_END
