/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
#ifdef OF_HAVE_FILES
	OFString *userConfigPath, *userDataPath;
#endif

	[of_stdout setForegroundColor: [OFColor lime]];

	[of_stdout writeFormat: @"[OFSystemInfo] Page size: %zd\n",
	    [OFSystemInfo pageSize]];

	[of_stdout writeFormat: @"[OFSystemInfo] Number of CPUs: %zd\n",
	    [OFSystemInfo numberOfCPUs]];

	[of_stdout writeFormat: @"[OFSystemInfo] ObjFW version: %@\n",
	    [OFSystemInfo ObjFWVersion]];

	[of_stdout writeFormat: @"[OFSystemInfo] ObjFW version major: %u\n",
	    [OFSystemInfo ObjFWVersionMajor]];

	[of_stdout writeFormat: @"[OFSystemInfo] ObjFW version minor: %u\n",
	    [OFSystemInfo ObjFWVersionMinor]];

	[of_stdout writeFormat: @"[OFSystemInfo] Operating system name: %@\n",
	    [OFSystemInfo operatingSystemName]];

	[of_stdout writeFormat:
	    @"[OFSystemInfo] Operating system version: %@\n",
	    [OFSystemInfo operatingSystemVersion]];

#ifdef OF_HAVE_FILES
	@try {
		userConfigPath = [OFSystemInfo userConfigPath];
	} @catch (OFNotImplementedException *e) {
		userConfigPath = @"Not implemented";
	}
	[of_stdout writeFormat: @"[OFSystemInfo] User config path: %@\n",
	    userConfigPath];

	@try {
		userDataPath = [OFSystemInfo userDataPath];
	} @catch (OFNotImplementedException *e) {
		userDataPath = @"Not implemented";
	}
	[of_stdout writeFormat: @"[OFSystemInfo] User data path: %@\n",
	    userDataPath];
#endif

	[of_stdout writeFormat: @"[OFSystemInfo] CPU vendor: %@\n",
	    [OFSystemInfo CPUVendor]];

	[of_stdout writeFormat: @"[OFSystemInfo] CPU model: %@\n",
	    [OFSystemInfo CPUModel]];

#if defined(OF_X86_64) || defined(OF_X86)
	[of_stdout writeFormat: @"[OFSystemInfo] Supports MMX: %d\n",
	    [OFSystemInfo supportsMMX]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSE: %d\n",
	    [OFSystemInfo supportsSSE]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSE2: %d\n",
	    [OFSystemInfo supportsSSE2]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSE3: %d\n",
	    [OFSystemInfo supportsSSE3]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSSE3: %d\n",
	    [OFSystemInfo supportsSSSE3]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSE4.1: %d\n",
	    [OFSystemInfo supportsSSE41]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SSE4.2: %d\n",
	    [OFSystemInfo supportsSSE42]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports AVX: %d\n",
	    [OFSystemInfo supportsAVX]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports AVX2: %d\n",
	    [OFSystemInfo supportsAVX2]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports AES-NI: %d\n",
	    [OFSystemInfo supportsAESNI]];

	[of_stdout writeFormat: @"[OFSystemInfo] Supports SHA extensions: %d\n",
	    [OFSystemInfo supportsSHAExtensions]];
#endif

#ifdef OF_POWERPC
	[of_stdout writeFormat: @"[OFSystemInfo] Supports AltiVec: %d\n",
	    [OFSystemInfo supportsAltiVec]];
#endif

	objc_autoreleasePoolPop(pool);
}
@end
