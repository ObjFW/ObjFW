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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSystemInfo OFSystemInfo.h ObjFW/OFSystemInfo.h
 *
 * @brief A class for querying information about the system.
 */
@interface OFSystemInfo: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) size_t pageSize;
@property (class, readonly, nonatomic) size_t numberOfCPUs;
@property (class, readonly, nonatomic) OFString *ObjFWVersion;
@property (class, readonly, nonatomic) unsigned int ObjFWVersionMajor;
@property (class, readonly, nonatomic) unsigned int ObjFWVersionMinor;
@property (class, readonly, nullable, nonatomic) OFString *operatingSystemName;
@property (class, readonly, nullable, nonatomic)
    OFString *operatingSystemVersion;
# ifdef OF_HAVE_FILES
@property (class, readonly, nullable, nonatomic) OFString *userDataPath;
@property (class, readonly, nullable, nonatomic) OFString *userConfigPath;
# endif
@property (class, readonly, nullable, nonatomic) OFString *CPUVendor;
@property (class, readonly, nullable, nonatomic) OFString *CPUModel;
# if defined(OF_X86_64) || defined(OF_X86) || defined(DOXYGEN)
@property (class, readonly, nonatomic) bool supportsMMX;
@property (class, readonly, nonatomic) bool supportsSSE;
@property (class, readonly, nonatomic) bool supportsSSE2;
@property (class, readonly, nonatomic) bool supportsSSE3;
@property (class, readonly, nonatomic) bool supportsSSSE3;
@property (class, readonly, nonatomic) bool supportsSSE41;
@property (class, readonly, nonatomic) bool supportsSSE42;
@property (class, readonly, nonatomic) bool supportsAVX;
@property (class, readonly, nonatomic) bool supportsAVX2;
# endif
# if defined(OF_POWERPC) || defined(OF_POWERPC64) || defined(DOXYGEN)
@property (class, readonly, nonatomic) bool supportsAltiVec;
# endif
#endif

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
 * @brief The version of ObjFW.
 *
 * @return The version of ObjFW
 */
+ (OFString *)ObjFWVersion;

/*!
 * @brief The major version of ObjFW.
 *
 * @return The major version of ObjFW
 */
+ (unsigned int)ObjFWVersionMajor;

/*!
 * @brief The minor version of ObjFW.
 *
 * @return The minor version of ObjFW
 */
+ (unsigned int)ObjFWVersionMinor;

/*!
 * @brief Returns the name of the operating system the application is running
 *	  on.
 *
 * @return The name of the operating system the application is running on
 */
+ (nullable OFString *)operatingSystemName;

/*!
 * @brief Returns the version of the operating system the application is
 *	  running on.
 *
 * @return The version of the operating system the application is running on
 */
+ (nullable OFString *)operatingSystemVersion;

#ifdef OF_HAVE_FILES
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
+ (nullable OFString *)userDataPath;

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
+ (nullable OFString *)userConfigPath;
#endif

/*!
 * @brief Returns the vendor of the CPU.
 *
 * If the vendor could not be determined, `nil` is returned instead.
 *
 * @return The vendor of the CPU
 */
+ (nullable OFString *)CPUVendor;

/*!
 * @brief Returns the model of the CPU.
 *
 * If the model could not be determined, `nil` is returned instead.
 *
 * @return The model of the CPU
 */
+ (nullable OFString *)CPUModel;

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
 * @note This method is only available on PowerPC and PowerPC 64.
 *
 * @return Whether the CPU and OS support AltiVec
 */
+ (bool)supportsAltiVec;
#endif

+ (instancetype)alloc OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
