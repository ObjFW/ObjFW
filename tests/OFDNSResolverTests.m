/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

	[of_stdout setForegroundColor: [OFColor lime]];

	for (OFString *host in resolver.staticHosts) {
		OFString *IPs;

		if (staticHosts.length > 0)
			[staticHosts appendString: @"; "];

		IPs = [[resolver.staticHosts objectForKey: host]
		    componentsJoinedByString: @", "];

		[staticHosts appendFormat: @"%@=(%@)", host, IPs];
	}
	[of_stdout writeFormat: @"[OFDNSResolver] Static hosts: %@\n",
	    staticHosts];

	[of_stdout writeFormat: @"[OFDNSResolver] Name servers: %@\n",
	    [resolver.nameServers componentsJoinedByString: @", "]];

	[of_stdout writeFormat: @"[OFDNSResolver] Local domain: %@\n",
	    resolver.localDomain];

	[of_stdout writeFormat: @"[OFDNSResolver] Search domains: %@\n",
	    [resolver.searchDomains componentsJoinedByString: @", "]];

	[of_stdout writeFormat: @"[OFDNSResolver] Timeout: %lf\n",
	    resolver.timeout];

	[of_stdout writeFormat: @"[OFDNSResolver] Max attempts: %u\n",
	    resolver.maxAttempts];

	[of_stdout writeFormat:
	    @"[OFDNSResolver] Min number of dots in absolute name: %u\n",
	    resolver.minNumberOfDotsInAbsoluteName];

	[of_stdout writeFormat: @"[OFDNSResolver] Uses TCP: %u\n",
	    resolver.usesTCP];

	[of_stdout writeFormat:
	    @"[OFDNSResolver] Config reload interval: %lf\n",
	    resolver.configReloadInterval];

	objc_autoreleasePoolPop(pool);
}
@end
