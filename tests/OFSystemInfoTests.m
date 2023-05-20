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

@implementation TestsAppDelegate (OFSystemInfoTests)
- (void)systemInfoTests
{
	void *pool = objc_autoreleasePoolPush();
#ifdef OF_SYSTEM_INFO_HAS_NETWORK_INTERFACES
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

#if defined(OF_X86_64) || defined(OF_X86)
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
#endif

#ifdef OF_POWERPC
	[OFStdOut writeFormat: @"[OFSystemInfo] Supports AltiVec: %d\n",
	    [OFSystemInfo supportsAltiVec]];
#endif

#ifdef OF_SYSTEM_INFO_HAS_NETWORK_INTERFACES
	[OFStdOut writeString: @"[OFSystemInfo] Network interfaces: "];
	networkInterfaces = [OFSystemInfo networkInterfaces];
	for (OFString *name in networkInterfaces) {
		OFDictionary *interface = [networkInterfaces
		    objectForKey: name];
		OFData *etherAddr = [interface
		    objectForKey: OFNetworkInterfaceEthernetAddress];
		bool firstAddress = true;
		OFData *addrs;

		if (!firstInterface)
			[OFStdOut writeString: @"; "];
		firstInterface = false;

		[OFStdOut writeFormat: @"%@(", name];

		if (etherAddr.itemSize == 1 && etherAddr.count == 6) {
			const unsigned char *addr = etherAddr.items;
			[OFStdOut writeFormat:
			    @"MAC=%02X:%02X:%02X:%02X:%02X:%02X",
			    addr[0], addr[1], addr[2], addr[3], addr[4],
			    addr[5]];
			firstAddress = false;
		}

		addrs = [interface objectForKey: OFNetworkInterfaceAddresses];
		for (size_t i = 0; i < addrs.count; i++) {
			const OFSocketAddress *addr = [addrs itemAtIndex: i];
			OFString *string;

			@try {
				string = OFSocketAddressString(addr);
			} @catch (OFInvalidArgumentException *e) {
				continue;
			}

			if (!firstAddress)
				[OFStdOut writeString: @", "];
			firstAddress = nil;

			switch (addr->family) {
			case OFSocketAddressFamilyIPv4:
				[OFStdOut writeString: @"IPv4="];
				break;
			case OFSocketAddressFamilyIPv6:
				[OFStdOut writeString: @"IPv6="];
				break;
			case OFSocketAddressFamilyIPX:
				[OFStdOut writeString: @"IPX="];
				break;
			case OFSocketAddressFamilyAppleTalk:
				[OFStdOut writeString: @"AppleTalk="];
				break;
			default:
				[OFStdOut writeString: @"unknown="];
			}

			[OFStdOut writeString: string];
		}

		[OFStdOut writeString: @")"];
	}
	[OFStdOut writeString: @"\n"];
#endif

	objc_autoreleasePoolPop(pool);
}
@end
