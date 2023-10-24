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

#include "config.h"

#import "TestsAppDelegate.h"

#ifdef OF_HAVE_SOCKETS
static void
printAddresses(OFData *addresses, bool *firstAddress)
{
	size_t count = addresses.count;

	for (size_t i = 0; i < count; i++) {
		const OFSocketAddress *address = [addresses itemAtIndex: i];

		if (!*firstAddress)
			[OFStdOut writeString: @", "];

		*firstAddress = false;

		[OFStdOut writeString: OFSocketAddressString(address)];
	}
}
#endif

@implementation TestsAppDelegate (OFSystemInfoTests)
- (void)systemInfoTests
{
	void *pool = objc_autoreleasePoolPush();
#ifdef OF_HAVE_SOCKETS
	OFDictionary *networkInterfaces;
	bool firstInterface = true;
#endif

	[OFStdOut setForegroundColor: [OFColor lime]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Page size: %zd\n",
	    [OFSystemInfo pageSize]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Number of CPUs: %zd\n",
	    [OFSystemInfo numberOfCPUs]];

	[OFStdOut writeFormat: @"[OFSystemInfo] ObjFW version: %@\n",
	    [OFSystemInfo ObjFWVersion]];

	[OFStdOut writeFormat: @"[OFSystemInfo] ObjFW version major: %u\n",
	    [OFSystemInfo ObjFWVersionMajor]];

	[OFStdOut writeFormat: @"[OFSystemInfo] ObjFW version minor: %u\n",
	    [OFSystemInfo ObjFWVersionMinor]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Operating system name: %@\n",
	    [OFSystemInfo operatingSystemName]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Operating system version: %@\n",
	    [OFSystemInfo operatingSystemVersion]];

	[OFStdOut writeFormat: @"[OFSystemInfo] User config IRI: %@\n",
	    [OFSystemInfo userConfigIRI].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] User data IRI: %@\n",
	    [OFSystemInfo userDataIRI].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] Temporary directory IRI: %@\n",
	    [OFSystemInfo temporaryDirectoryIRI].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] CPU vendor: %@\n",
	    [OFSystemInfo CPUVendor]];

	[OFStdOut writeFormat: @"[OFSystemInfo] CPU model: %@\n",
	    [OFSystemInfo CPUModel]];

#if defined(OF_AMD64) || defined(OF_X86)
	[OFStdOut writeFormat: @"[OFSystemInfo] Supports MMX: %d\n",
	    [OFSystemInfo supportsMMX]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports 3DNow!: %d\n",
	    [OFSystemInfo supports3DNow]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports enhanced 3DNow!: %d\n",
	    [OFSystemInfo supportsEnhanced3DNow]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSE: %d\n",
	    [OFSystemInfo supportsSSE]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSE2: %d\n",
	    [OFSystemInfo supportsSSE2]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSE3: %d\n",
	    [OFSystemInfo supportsSSE3]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSSE3: %d\n",
	    [OFSystemInfo supportsSSSE3]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSE4.1: %d\n",
	    [OFSystemInfo supportsSSE41]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SSE4.2: %d\n",
	    [OFSystemInfo supportsSSE42]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports AVX: %d\n",
	    [OFSystemInfo supportsAVX]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports AVX2: %d\n",
	    [OFSystemInfo supportsAVX2]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports AES-NI: %d\n",
	    [OFSystemInfo supportsAESNI]];

	[OFStdOut writeFormat: @"[OFSystemInfo] Supports SHA extensions: %d\n",
	    [OFSystemInfo supportsSHAExtensions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Foundation: %d\n",
	    [OFSystemInfo supportsAVX512Foundation]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Conflict Detection Instructions: "
	    @"%d\n",
	    [OFSystemInfo supportsAVX512ConflictDetectionInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Exponential and Reciprocal "
	    @"Instructions: %d\n",
	    [OFSystemInfo supportsAVX512ExponentialAndReciprocalInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Prefetch Instructions: %d\n",
	    [OFSystemInfo supportsAVX512PrefetchInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Vector Length Extensions: %d\n",
	    [OFSystemInfo supportsAVX512VectorLengthExtensions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Doubleword and Quadword "
	    @"Instructions: %d\n",
	    [OFSystemInfo supportsAVX512DoublewordAndQuadwordInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Byte and Word Instructions: %d\n",
	    [OFSystemInfo supportsAVX512ByteAndWordInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Integer Fused Multiply Add: %d\n",
	    [OFSystemInfo supportsAVX512IntegerFusedMultiplyAdd]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Vector Byte Manipulation "
	    @"Instructions: %d\n",
	    [OFSystemInfo supportsAVX512VectorByteManipulationInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Vector Population Count "
	    @"Instruction: %d\n",
	    [OFSystemInfo supportsAVX512VectorPopulationCountInstruction]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Vector Neutral Network "
	    @"Instructions: %d\n",
	    [OFSystemInfo supportsAVX512VectorNeuralNetworkInstructions]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Vector Byte Manipulation "
	    @"Instructions 2: %d\n",
	    [OFSystemInfo supportsAVX512VectorByteManipulationInstructions2]];

	[OFStdOut writeFormat:
	    @"[OFSystemInfo] Supports AVX-512 Bit Algorithms: %d\n",
	    [OFSystemInfo supportsAVX512BitAlgorithms]];
#endif

#ifdef OF_POWERPC
	[OFStdOut writeFormat: @"[OFSystemInfo] Supports AltiVec: %d\n",
	    [OFSystemInfo supportsAltiVec]];
#endif

#ifdef OF_HAVE_SOCKETS
	networkInterfaces = [OFSystemInfo networkInterfaces];
	[OFStdOut writeString: @"[OFSystemInfo] Network interfaces: "];
	for (OFString *name in networkInterfaces) {
		bool firstAddress = true;
		OFNetworkInterface interface;
		OFData *hardwareAddress;

		if (!firstInterface)
			[OFStdOut writeString: @"; "];

		firstInterface = false;

		[OFStdOut writeFormat: @"%@(", name];

		interface = [networkInterfaces objectForKey: name];

		printAddresses([interface objectForKey:
		    OFNetworkInterfaceIPv4Addresses], &firstAddress);
# ifdef OF_HAVE_IPV6
		printAddresses([interface objectForKey:
		    OFNetworkInterfaceIPv6Addresses], &firstAddress);
# endif
# ifdef OF_HAVE_IPX
		printAddresses([interface objectForKey:
		    OFNetworkInterfaceIPXAddresses], &firstAddress);
# endif
# ifdef OF_HAVE_APPLETALK
		printAddresses([interface objectForKey:
		    OFNetworkInterfaceAppleTalkAddresses], &firstAddress);
# endif

		hardwareAddress = [interface
		    objectForKey: OFNetworkInterfaceHardwareAddress];
		if (hardwareAddress != nil) {
			const unsigned char *bytes = hardwareAddress.items;
			size_t length = hardwareAddress.count;

			if (!firstAddress)
				[OFStdOut writeString: @", "];

			for (size_t i = 0; i < length; i++) {
				if (i > 0)
					[OFStdOut writeString: @":"];

				[OFStdOut writeFormat: @"%02X", bytes[i]];
			}
		}

		[OFStdOut writeString: @")"];
	}
	[OFStdOut writeString: @"\n"];
#endif

	objc_autoreleasePoolPop(pool);
}
@end
