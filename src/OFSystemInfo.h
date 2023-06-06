/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFIRI;

#ifdef OF_HAVE_SOCKETS
/**
 * @brief A dictionary describing a network interface, as returned by
 *	  @ref networkInterfaces.
 *
 * Keys are of type @ref OFNetworkInterfaceKey.
 */
typedef OFDictionary OF_GENERIC(OFString *, id) *OFNetworkInterface;

/**
 * @brief A key of an @ref OFNetworkInterface.
 *
 * Possible values are:
 *
 *   * @ref OFNetworkInterfaceIndex
 */
typedef OFConstantString *OFNetworkInterfaceKey;

/**
 * @brief The index of a network interface.
 *
 * This maps to an @ref OFNumber.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIndex;

# ifdef OF_HAVE_IPV6
/**
 * @brief The IPv6 addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIPv6Addresses;
# endif

/**
 * @brief The IPv4 addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIPv4Addresses;

# ifdef OF_HAVE_APPLETALK
/**
 * @brief The AppleTalk addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceAppleTalkAddresses;
# endif
#endif

/**
 * @class OFSystemInfo OFSystemInfo.h ObjFW/OFSystemInfo.h
 *
 * @brief A class for querying information about the system.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFSystemInfo: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) size_t pageSize;
@property (class, readonly, nonatomic) size_t numberOfCPUs;
@property (class, readonly, nonatomic) OFString *ObjFWVersion;
@property (class, readonly, nonatomic) unsigned short ObjFWVersionMajor;
@property (class, readonly, nonatomic) unsigned short ObjFWVersionMinor;
@property (class, readonly, nullable, nonatomic) OFString *operatingSystemName;
@property (class, readonly, nullable, nonatomic)
    OFString *operatingSystemVersion;
@property (class, readonly, nullable, nonatomic) OFIRI *userDataIRI;
@property (class, readonly, nullable, nonatomic) OFIRI *userConfigIRI;
@property (class, readonly, nullable, nonatomic) OFIRI *temporaryDirectoryIRI;
@property (class, readonly, nullable, nonatomic) OFString *CPUVendor;
@property (class, readonly, nullable, nonatomic) OFString *CPUModel;
# if defined(OF_AMD64) || defined(OF_X86) || defined(DOXYGEN)
@property (class, readonly, nonatomic) bool supportsMMX;
@property (class, readonly, nonatomic) bool supports3DNow;
@property (class, readonly, nonatomic) bool supportsEnhanced3DNow;
@property (class, readonly, nonatomic) bool supportsSSE;
@property (class, readonly, nonatomic) bool supportsSSE2;
@property (class, readonly, nonatomic) bool supportsSSE3;
@property (class, readonly, nonatomic) bool supportsSSSE3;
@property (class, readonly, nonatomic) bool supportsSSE41;
@property (class, readonly, nonatomic) bool supportsSSE42;
@property (class, readonly, nonatomic) bool supportsAVX;
@property (class, readonly, nonatomic) bool supportsAVX2;
@property (class, readonly, nonatomic) bool supportsAESNI;
@property (class, readonly, nonatomic) bool supportsSHAExtensions;
# endif
# if defined(OF_POWERPC) || defined(OF_POWERPC64) || defined(DOXYGEN)
@property (class, readonly, nonatomic) bool supportsAltiVec;
# endif
# ifdef OF_WINDOWS
@property (class, readonly, nonatomic, getter=isWindowsNT) bool windowsNT;
# endif
# ifdef OF_HAVE_SOCKETS
@property (class, readonly, nullable, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *networkInterfaces;
# endif
#endif

/**
 * @brief Returns the size of a page.
 *
 * @return The size of a page
 */
+ (size_t)pageSize;

/**
 * @brief Returns the number of CPUs installed in the system.
 *
 * A CPU with multiple cores counts as multiple CPUs.
 *
 * @return The number of CPUs installed in the system
 */
+ (size_t)numberOfCPUs;

/**
 * @brief The version of ObjFW.
 *
 * @return The version of ObjFW
 */
+ (OFString *)ObjFWVersion;

/**
 * @brief The major version of ObjFW.
 *
 * @return The major version of ObjFW
 */
+ (unsigned short)ObjFWVersionMajor;

/**
 * @brief The minor version of ObjFW.
 *
 * @return The minor version of ObjFW
 */
+ (unsigned short)ObjFWVersionMinor;

/**
 * @brief Returns the name of the operating system the application is running
 *	  on.
 *
 * @return The name of the operating system the application is running on
 */
+ (nullable OFString *)operatingSystemName;

/**
 * @brief Returns the version of the operating system the application is
 *	  running on.
 *
 * @return The version of the operating system the application is running on
 */
+ (nullable OFString *)operatingSystemVersion;

/**
 * @brief Returns the path where user data for the application can be stored.
 *
 * On UNIX systems, this adheres to the XDG Base Directory specification.@n
 * On macOS and iOS, it uses the `NSApplicationSupportDirectory` directory.@n
 * On Windows, it uses the `APPDATA` environment variable.@n
 * On Haiku, it uses the `B_USER_SETTINGS_DIRECTORY` directory.@n
 * On AmigaOS and MorphOS, it returns `PROGDIR:`.
 *
 * @return The path where user data for the application can be stored
 */
+ (nullable OFIRI *)userDataIRI;

/**
 * @brief Returns the path where user configuration for the application can be
 *	  stored.
 *
 * On UNIX systems, this adheres to the XDG Base Directory specification.@n
 * On macOS and iOS, it uses the `Preferences` directory inside of
 * `NSLibraryDirectory` directory.@n
 * On Windows, it uses the `APPDATA` environment variable.@n
 * On Haiku, it uses the `B_USER_SETTINGS_DIRECTORY` directory.
 * On AmigaOS and MorphOS, it returns `PROGDIR:`.
 *
 * @return The path where user configuration for the application can be stored
 */
+ (nullable OFIRI *)userConfigIRI;

/**
 * @brief Returns a path where temporary files for can be stored.
 * 
 * If possible, returns a temporary directory for the user, otherwise returns a
 * global temporary directory.
 *
 * On UNIX systems, this adheres to the XDG Base Directory specification and
 * returns `/tmp` if `XDG_RUNTIME_DIR` is not set.@n
 * On macOS and iOS, this uses `_CS_DARWIN_USER_TEMP_DIR`, falling back to
 * `/tmp` if this fails.@n
 * On Windows, it uses `GetTempPath`.@n
 * On Haiku, it uses the `B_SYSTEM_TEMP_DIRECTORY` directory.
 * On AmigaOS and MorphOS, it returns `T:`.
 *
 * @return A path where temporary files can be stored
 */
+ (nullable OFIRI *)temporaryDirectoryIRI;

/**
 * @brief Returns the vendor of the CPU.
 *
 * If the vendor could not be determined, `nil` is returned instead.
 *
 * @return The vendor of the CPU
 */
+ (nullable OFString *)CPUVendor;

/**
 * @brief Returns the model of the CPU.
 *
 * If the model could not be determined, `nil` is returned instead.
 *
 * @return The model of the CPU
 */
+ (nullable OFString *)CPUModel;

#if defined(OF_AMD64) || defined(OF_X86) || defined(DOXYGEN)
/**
 * @brief Returns whether the CPU supports MMX.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports MMX
 */
+ (bool)supportsMMX;

/**
 * @brief Returns whether the CPU supports 3DNow!.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports 3DNow!
 */
+ (bool)supports3DNow;

/**
 * @brief Returns whether the CPU supports enhanced 3DNow!.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports enhanced 3DNow!
 */
+ (bool)supportsEnhanced3DNow;

/**
 * @brief Returns whether the CPU supports SSE.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSE
 */
+ (bool)supportsSSE;

/**
 * @brief Returns whether the CPU supports SSE2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSE2
 */
+ (bool)supportsSSE2;

/**
 * @brief Returns whether the CPU supports SSE3.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSE3
 */
+ (bool)supportsSSE3;

/**
 * @brief Returns whether the CPU supports SSSE3.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSSE3
 */
+ (bool)supportsSSSE3;

/**
 * @brief Returns whether the CPU supports SSE4.1.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSE4.1
 */
+ (bool)supportsSSE41;

/**
 * @brief Returns whether the CPU supports SSE4.2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports SSE4.2
 */
+ (bool)supportsSSE42;

/**
 * @brief Returns whether the CPU supports AVX.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX
 */
+ (bool)supportsAVX;

/**
 * @brief Returns whether the CPU supports AVX2.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX2
 */
+ (bool)supportsAVX2;

/**
 * @brief Returns whether the CPU supports AES-NI.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AES-NI
 */
+ (bool)supportsAESNI;

/**
 * @brief Returns whether the CPU supports Intel SHA Extensions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports Intel SHA Extensions
 */
+ (bool)supportsSHAExtensions;
#endif

#if defined(OF_POWERPC) || defined(OF_POWERPC64)
/**
 * @brief Returns whether the CPU and OS support AltiVec.
 *
 * @note This method is only available on PowerPC and PowerPC 64.
 *
 * @return Whether the CPU and OS support AltiVec
 */
+ (bool)supportsAltiVec;
#endif

#ifdef OF_WINDOWS
/**
 * @brief Returns whether the application is running on Windows NT.
 *
 * @note This method is only available on Windows.
 *
 * @return Whether the application is running on Windows NT
 */
+ (bool)isWindowsNT;
#endif

#ifdef OF_HAVE_SOCKETS
/**
 * @brief Returns the available (though not necessarily configured) network
 *	  interfaces.
 *
 * @return The available network interfaces
 */
+ (nullable OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)
    networkInterfaces;
#endif

+ (instancetype)alloc OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
