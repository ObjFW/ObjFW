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
@property (class, readonly, nonatomic) bool supportsFusedMultiplyAdd;
@property (class, readonly, nonatomic) bool supportsF16C;
@property (class, readonly, nonatomic) bool supportsAVX512Foundation;
@property (class, readonly, nonatomic)
    bool supportsAVX512ConflictDetectionInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512ExponentialAndReciprocalInstructions;
@property (class, readonly, nonatomic) bool supportsAVX512PrefetchInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512VectorLengthExtensions;
@property (class, readonly, nonatomic)
    bool supportsAVX512DoublewordAndQuadwordInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512ByteAndWordInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512IntegerFusedMultiplyAdd;
@property (class, readonly, nonatomic)
    bool supportsAVX512VectorByteManipulationInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512VectorPopulationCountInstruction;
@property (class, readonly, nonatomic)
    bool supportsAVX512VectorNeuralNetworkInstructions;
@property (class, readonly, nonatomic)
    bool supportsAVX512VectorByteManipulationInstructions2;
@property (class, readonly, nonatomic) bool supportsAVX512BitAlgorithms;
@property (class, readonly, nonatomic) bool supportsAVX512Float16Instructions;
@property (class, readonly, nonatomic) bool supportsAVX512BFloat16Instructions;
# endif
# if defined(OF_POWERPC) || defined(OF_POWERPC64) || defined(DOXYGEN)
@property (class, readonly, nonatomic) bool supportsAltiVec;
# endif
# if defined(OF_WINDOWS) || defined(DOXYGEN)
@property (class, readonly, nonatomic, getter=isWindowsNT) bool windowsNT;
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

/**
 * @brief Returns whether the CPU supports fused multiply-add.
 *
 * @warning This method only checks CPU support and assumes OS support!
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports fused multiply-add
 */
+ (bool)supportsFusedMultiplyAdd;

/**
 * @brief Returns whether the CPU supports F16C.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports F16C
 */
+ (bool)supportsF16C;

/**
 * @brief Returns whether the CPU supports AVX-512 Foundation.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Foundation
 */
+ (bool)supportsAVX512Foundation;

/**
 * @brief Returns whether the CPU supports AVX-512 Conflict Detection
 *	  Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Conflict Detection Instructions
 */
+ (bool)supportsAVX512ConflictDetectionInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Exponential and Reciprocal
 *	  Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Exponential and Reciprocal
 *	   Instructions
 */
+ (bool)supportsAVX512ExponentialAndReciprocalInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Prefetch Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Prefetch Instructions
 */
+ (bool)supportsAVX512PrefetchInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Vector Length Extensions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Vector Length Extensions
 */
+ (bool)supportsAVX512VectorLengthExtensions;

/**
 * @brief Returns whether the CPU supports AVX-512 Doubleword and Quadword
 *	  Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Doubleword and Quadword Instructions
 */
+ (bool)supportsAVX512DoublewordAndQuadwordInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Byte and Word Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Byte and Word Instructions
 */
+ (bool)supportsAVX512ByteAndWordInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Integer Fused Multiply Add.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Integer Fused Multiply Add
 */
+ (bool)supportsAVX512IntegerFusedMultiplyAdd;

/**
 * @brief Returns whether the CPU supports AVX-512 Vector Byte Manipulation
 *	  Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Vector Byte Manipulation
 *	   Instructions
 */
+ (bool)supportsAVX512VectorByteManipulationInstructions;

/**
 * @brief Returns whether the CPU supports the AVX-512 Vector Population Count
 *	  Instruction.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 the Vector Population Count
 *	   Instruction
 */
+ (bool)supportsAVX512VectorPopulationCountInstruction;

/**
 * @brief Returns whether the CPU supports AVX-512 Vector Neural Network
 *	  Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Vector Neural Network Instructions
 */
+ (bool)supportsAVX512VectorNeuralNetworkInstructions;

/**
 * @brief Returns whether the CPU supports AVX-512 Vector Byte Manipulation
 *	  Instructions 2.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Vector Byte Manipulation
 *	   Instructions 2
 */
+ (bool)supportsAVX512VectorByteManipulationInstructions2;

/**
 * @brief Returns whether the CPU supports AVX-512 Bit Algorithms.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Bit Algorithms
 */
+ (bool)supportsAVX512BitAlgorithms;

/**
 * @brief Returns whether the CPU supports AVX-512 Float16 Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 Float16 Instructions
 */
+ (bool)supportsAVX512Float16Instructions;

/**
 * @brief Returns whether the CPU supports AVX-512 BFloat16 Instructions.
 *
 * @note This method is only available on AMD64 and x86.
 *
 * @return Whether the CPU supports AVX-512 BFloat16 Instructions
 */
+ (bool)supportsAVX512BFloat16Instructions;
#endif

#if defined(OF_POWERPC) || defined(OF_POWERPC64) || defined(DOXYGEN)
/**
 * @brief Returns whether the CPU and OS support AltiVec.
 *
 * @note This method is only available on PowerPC and PowerPC 64.
 *
 * @return Whether the CPU and OS support AltiVec
 */
+ (bool)supportsAltiVec;
#endif

#if defined(OF_WINDOWS) || defined(DOXYGEN)
/**
 * @brief Returns whether the application is running on Windows NT.
 *
 * @note This method is only available on Windows.
 *
 * @return Whether the application is running on Windows NT
 */
+ (bool)isWindowsNT;
#endif

+ (instancetype)alloc OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END

#ifdef OF_HAVE_SOCKETS
# import "OFSystemInfo+NetworkInterfaces.h"
#endif
