/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFSystemInfoTests: OTTestCase
@end

#ifdef OF_HAVE_SOCKETS
static void
appendAddresses(OFMutableString *string, OFData *addresses, bool *firstAddress)
{
	size_t count = addresses.count;

	for (size_t i = 0; i < count; i++) {
		const OFSocketAddress *address = [addresses itemAtIndex: i];

		if (!*firstAddress)
			[string appendString: @", "];

		*firstAddress = false;

		[string appendString: OFSocketAddressString(address)];
	}
}
#endif

@implementation OFSystemInfoTests
+ (OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *)summary
{
	OFMutableArray *summary = [OFMutableArray array];
#ifdef OF_HAVE_SOCKETS
	OFDictionary *networkInterfaces;
	OFMutableString *networkInterfacesString;
	bool firstInterface = true;
#endif

#define ADD(name, value)						\
	[summary addObject: [OFPair pairWithFirstObject: name		\
					   secondObject: value]];
#define ADD_UINT(name, value)						\
	ADD(name, [OFNumber numberWithUnsignedInt: value]);
#define ADD_ULONGLONG(name, value)					\
	ADD(name, [OFNumber numberWithUnsignedLongLong: value]);
#define ADD_BOOL(name, value)						\
	ADD(name, [OFNumber numberWithBool: value]);

	ADD(@"ObjFW version", [OFSystemInfo ObjFWVersion])
	ADD_UINT(@"ObjFW version major", [OFSystemInfo ObjFWVersionMajor])
	ADD_UINT(@"ObjFW version minor", [OFSystemInfo ObjFWVersionMinor])
	ADD(@"Operating system name", [OFSystemInfo operatingSystemName]);
	ADD(@"Operating system version", [OFSystemInfo operatingSystemVersion]);
#ifdef OF_WINDOWS
	ADD(@"Wine version", [OFSystemInfo wineVersion]);
#endif
	ADD_ULONGLONG(@"Page size", [OFSystemInfo pageSize]);
	ADD_ULONGLONG(@"Number of CPUs", [OFSystemInfo numberOfCPUs]);
	ADD(@"User config IRI", [OFSystemInfo userConfigIRI].string);
	ADD(@"User data IRI", [OFSystemInfo userDataIRI].string);
	ADD(@"Temporary directory IRI",
	    [OFSystemInfo temporaryDirectoryIRI].string);
	ADD(@"CPU vendor", [OFSystemInfo CPUVendor]);
	ADD(@"CPU model", [OFSystemInfo CPUModel]);

#if defined(OF_AMD64) || defined(OF_X86)
	ADD_BOOL(@"Supports MMX", [OFSystemInfo supportsMMX]);
	ADD_BOOL(@"Supports 3DNow!", [OFSystemInfo supports3DNow]);
	ADD_BOOL(@"Supports enhanced 3DNow!",
	    [OFSystemInfo supportsEnhanced3DNow]);
	ADD_BOOL(@"Supports SSE", [OFSystemInfo supportsSSE]);
	ADD_BOOL(@"Supports SSE2", [OFSystemInfo supportsSSE2]);
	ADD_BOOL(@"Supports SSE3", [OFSystemInfo supportsSSE3]);
	ADD_BOOL(@"Supports SSSE3", [OFSystemInfo supportsSSSE3]);
	ADD_BOOL(@"Supports SSE4.1", [OFSystemInfo supportsSSE41]);
	ADD_BOOL(@"Supports SSE4.2", [OFSystemInfo supportsSSE42]);
	ADD_BOOL(@"Supports AVX", [OFSystemInfo supportsAVX]);
	ADD_BOOL(@"Supports AVX2", [OFSystemInfo supportsAVX2]);
	ADD_BOOL(@"Supports AES-NI", [OFSystemInfo supportsAESNI]);
	ADD_BOOL(@"Supports SHA extensions",
	    [OFSystemInfo supportsSHAExtensions]);
	ADD_BOOL(@"Supports fused multiply-add",
	    [OFSystemInfo supportsFusedMultiplyAdd]);
	ADD_BOOL(@"Supports F16C", [OFSystemInfo supportsF16C]);
	ADD_BOOL(@"Supports AVX-512 Foundation",
	    [OFSystemInfo supportsAVX512Foundation]);
	ADD_BOOL(@"Supports AVX-512 Conflict Detection Instructions",
	    [OFSystemInfo supportsAVX512ConflictDetectionInstructions]);
	ADD_BOOL(@"Supports AVX-512 Exponential and Reciprocal Instructions",
	    [OFSystemInfo supportsAVX512ExponentialAndReciprocalInstructions]);
	ADD_BOOL(@"Supports AVX-512 Prefetch Instructions",
	    [OFSystemInfo supportsAVX512PrefetchInstructions]);
	ADD_BOOL(@"Supports AVX-512 Vector Length Extensions",
	    [OFSystemInfo supportsAVX512VectorLengthExtensions]);
	ADD_BOOL(@"Supports AVX-512 Doubleword and Quadword Instructions",
	    [OFSystemInfo supportsAVX512DoublewordAndQuadwordInstructions]);
	ADD_BOOL(@"Supports AVX-512 Byte and Word Instructions",
	    [OFSystemInfo supportsAVX512ByteAndWordInstructions]);
	ADD_BOOL(@"Supports AVX-512 Integer Fused Multiply Add",
	    [OFSystemInfo supportsAVX512IntegerFusedMultiplyAdd]);
	ADD_BOOL(@"Supports AVX-512 Vector Byte Manipulation Instructions",
	    [OFSystemInfo supportsAVX512VectorByteManipulationInstructions]);
	ADD_BOOL(@"Supports AVX-512 Vector Population Count Instruction",
	    [OFSystemInfo supportsAVX512VectorPopulationCountInstruction]);
	ADD_BOOL(@"Supports AVX-512 Vector Neural Network Instructions",
	    [OFSystemInfo supportsAVX512VectorNeuralNetworkInstructions]);
	ADD_BOOL(@"Supports AVX-512 Vector Byte Manipulation Instructions 2",
	    [OFSystemInfo supportsAVX512VectorByteManipulationInstructions2]);
	ADD_BOOL(@"Supports AVX-512 Bit Algorithms",
	    [OFSystemInfo supportsAVX512BitAlgorithms]);
	ADD_BOOL(@"Supports AVX-512 Float16 Instructions",
	    [OFSystemInfo supportsAVX512Float16Instructions]);
	ADD_BOOL(@"Supports AVX-512 BFloat16 Instructions",
	    [OFSystemInfo supportsAVX512BFloat16Instructions]);
#endif

#if defined(OF_POWERPC) || defined(OF_POWERPC64)
	ADD_BOOL(@"Supports AltiVec", [OFSystemInfo supportsAltiVec]);
#endif

#ifdef OF_LOONGARCH64
	ADD_BOOL(@"Supports LSX", [OFSystemInfo supportsLSX]);
	ADD_BOOL(@"Supports LASX", [OFSystemInfo supportsLASX]);
#endif

#undef ADD
#undef ADD_UINT
#undef ADD_ULONGLONG
#undef ADD_BOOL

#ifdef OF_HAVE_SOCKETS
	networkInterfaces = [OFSystemInfo networkInterfaces];
	networkInterfacesString = [OFMutableString string];
	for (OFString *name in networkInterfaces) {
		bool firstAddress = true;
		OFNetworkInterface interface;
		OFData *hardwareAddress;

		if (!firstInterface)
			[networkInterfacesString appendString: @"; "];

		firstInterface = false;

		[networkInterfacesString appendFormat: @"%@(", name];

		interface = [networkInterfaces objectForKey: name];

		appendAddresses(networkInterfacesString,
		    [interface objectForKey: OFNetworkInterfaceIPv4Addresses],
		    &firstAddress);
# ifdef OF_HAVE_IPV6
		appendAddresses(networkInterfacesString,
		    [interface objectForKey: OFNetworkInterfaceIPv6Addresses],
		    &firstAddress);
# endif
# ifdef OF_HAVE_IPX
		appendAddresses(networkInterfacesString,
		    [interface objectForKey: OFNetworkInterfaceIPXAddresses],
		    &firstAddress);
# endif
# ifdef OF_HAVE_APPLETALK
		appendAddresses(networkInterfacesString,
		    [interface objectForKey:
		    OFNetworkInterfaceAppleTalkAddresses], &firstAddress);
# endif

		hardwareAddress = [interface
		    objectForKey: OFNetworkInterfaceHardwareAddress];
		if (hardwareAddress != nil) {
			const unsigned char *bytes = hardwareAddress.items;
			size_t length = hardwareAddress.count;

			if (!firstAddress)
				[networkInterfacesString appendString: @", "];

			for (size_t i = 0; i < length; i++) {
				if (i > 0)
					[networkInterfacesString
					    appendString: @":"];

				[networkInterfacesString
				    appendFormat: @"%02X", bytes[i]];
			}
		}

		[networkInterfacesString appendString: @")"];
	}
	[summary addObject:
	    [OFPair pairWithFirstObject: @"Network interfaces"
			   secondObject: networkInterfacesString]];
#endif

	return summary;
}
@end
