/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSystemInfo OFSystemInfo.h ObjFW/OFSystemInfo.h
 *
 * @brief A class for querying information about the system.
 */
@interface OFSystemInfo: OFObject
/*!
 * @brief Returns the size of a page.
 *
 * @return The size of a page
 */
+ (size_t)pageSize;

/*!
 * @brief Returns the number of CPUs installed in the system.
 *
 * A CPU with multiple cores counts as multiple CPUs.
 *
 * @return The number of CPUs installed in the system
 */
+ (size_t)numberOfCPUs;

/*!
 * @brief Returns the path where user data for the application can be stored.
 *
 * On Unix systems, this adheres to the XDG Base Directory specification.@n
 * On Mac OS X and iOS, it uses the `NSApplicationSupportDirectory` directory.@n
 * On Windows, it uses the `APPDATA` environment variable.@n
 * On Haiku, it uses the `B_USER_SETTINGS_DIRECTORY` directory.
 *
 * @return The path where user data for the application can be stored
 */
+ (OFString*)userDataPath;

/*!
 * @brief Returns the path where user configuration for the application can be
 *	  stored.
 *
 * On Unix systems, this adheres to the XDG Base Directory specification.@n
 * On Mac OS X and iOS, it uses the `Preferences` directory inside of
 * `NSLibraryDirectory` directory.@n
 * On Windows, it uses the `APPDATA` environment variable.@n
 * On Haiku, it uses the `B_USER_SETTINGS_DIRECTORY` directory.
 *
 * @return The path where user configuration for the application can be stored
 */
+ (OFString*)userConfigPath;

/*!
 * @brief Returns the vendor of the CPU.
 *
 * If the vendor could not be determined, `nil` is returned instead.
 *
 * @return The vendor of the CPU
 */
+ (nullable OFString*)CPUVendor;

#if defined(OF_X86_64) || defined(OF_X86) || defined(DOXYGEN)
/*!
 * @brief Returns whether the CPU supports MMX.
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports MMX
 */
+ (bool)supportsMMX;

/*!
 * @brief Returns whether the CPU supports SSE.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSE
 */
+ (bool)supportsSSE;

/*!
 * @brief Returns whether the CPU supports SSE2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSE2
 */
+ (bool)supportsSSE2;

/*!
 * @brief Returns whether the CPU supports SSE3.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSE3
 */
+ (bool)supportsSSE3;

/*!
 * @brief Returns whether the CPU supports SSSE3.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSSE3
 */
+ (bool)supportsSSSE3;

/*!
 * @brief Returns whether the CPU supports SSE4.1.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSE4.1
 */
+ (bool)supportsSSE41;

/*!
 * @brief Returns whether the CPU supports SSE4.2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports SSE4.2
 */
+ (bool)supportsSSE42;

/*!
 * @brief Returns whether the CPU supports AVX.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports AVX
 */
+ (bool)supportsAVX;

/*!
 * @brief Returns whether the CPU supports AVX2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on x86 and x86_64.
 *
 * @return Whether the CPU supports AVX2
 */
+ (bool)supportsAVX2;
#endif

#if defined(OF_POWERPC) || defined(OF_POWERPC64)
/*!
 * @brief Returns whether the CPU and OS support AltiVec.
 *
 * @note This method is only available on PowerPC and PowerPC64.
 *
 * @return Whether the CPU and OS support AltiVec
 */
+ (bool)supportsAltiVec;
#endif
@end

OF_ASSUME_NONNULL_END
