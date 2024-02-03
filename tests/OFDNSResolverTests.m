/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@implementation TestsAppDelegate (OFDNSResolverTests)
- (void)DNSResolverTests
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSResolver *resolver = [OFDNSResolver resolver];
	OFMutableString *staticHosts = [OFMutableString string];

	[OFStdOut setForegroundColor: [OFColor lime]];

	for (OFString *host in resolver.staticHosts) {
		OFString *IPs;

		if (staticHosts.length > 0)
			[staticHosts appendString: @"; "];

		IPs = [[resolver.staticHosts objectForKey: host]
		    componentsJoinedByString: @", "];

		[staticHosts appendFormat: @"%@=(%@)", host, IPs];
	}
	[OFStdOut writeFormat: @"[OFDNSResolver] Static hosts: %@\n",
	    staticHosts];

	[OFStdOut writeFormat: @"[OFDNSResolver] Name servers: %@\n",
	    [resolver.nameServers componentsJoinedByString: @", "]];

	[OFStdOut writeFormat: @"[OFDNSResolver] Local domain: %@\n",
	    resolver.localDomain];

	[OFStdOut writeFormat: @"[OFDNSResolver] Search domains: %@\n",
	    [resolver.searchDomains componentsJoinedByString: @", "]];

	[OFStdOut writeFormat: @"[OFDNSResolver] Timeout: %lf\n",
	    resolver.timeout];

	[OFStdOut writeFormat: @"[OFDNSResolver] Max attempts: %u\n",
	    resolver.maxAttempts];

	[OFStdOut writeFormat:
	    @"[OFDNSResolver] Min number of dots in absolute name: %u\n",
	    resolver.minNumberOfDotsInAbsoluteName];

	[OFStdOut writeFormat: @"[OFDNSResolver] Forces TCP: %u\n",
	    resolver.forcesTCP];

	[OFStdOut writeFormat:
	    @"[OFDNSResolver] Config reload interval: %lf\n",
	    resolver.configReloadInterval];

	objc_autoreleasePoolPop(pool);
}
@end
