/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

	[OFStdOut writeFormat: @"[OFSystemInfo] User config URL: %@\n",
	    [OFSystemInfo userConfigURL].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] User data URL: %@\n",
	    [OFSystemInfo userDataURL].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] Temporary directory URL: %@\n",
	    [OFSystemInfo temporaryDirectoryURL].string];

	[OFStdOut writeFormat: @"[OFSystemInfo] CPU vendor: %@\n",
	    [OFSystemInfo CPUVendor]];

	[OFStdOut writeFormat: @"[OFSystemInfo] CPU model: %@\n",
	    [OFSystemInfo CPUModel]];

#if defined(OF_X86_64) || defined(OF_X86)
	[OFStdOut writeFormat: @"[OFSystemInfo] Supports MMX: %d\n",
	    [OFSystemInfo supportsMMX]];

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

	objc_autoreleasePoolPop(pool);
}
@end
