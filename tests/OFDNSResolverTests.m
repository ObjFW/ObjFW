/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@interface OFDNSResolverTests: OTTestCase
@end

@implementation OFDNSResolverTests
+ (OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *)summary
{
	OFMutableArray *summary = [OFMutableArray array];
	OFDNSResolver *resolver = [OFDNSResolver resolver];
	OFMutableString *staticHosts = [OFMutableString string];

#define ADD(name, value)						\
	[summary addObject: [OFPair pairWithFirstObject: name		\
					   secondObject: value]];
#define ADD_DOUBLE(name, value)						\
	ADD(name, [OFNumber numberWithDouble: value])
#define ADD_UINT(name, value)						\
	ADD(name, [OFNumber numberWithUnsignedInt: value]);
#define ADD_BOOL(name, value)						\
	ADD(name, [OFNumber numberWithBool: value]);

	for (OFString *host in resolver.staticHosts) {
		OFString *IPs;

		if (staticHosts.length > 0)
			[staticHosts appendString: @"; "];

		IPs = [[resolver.staticHosts objectForKey: host]
		    componentsJoinedByString: @", "];

		[staticHosts appendFormat: @"%@=(%@)", host, IPs];
	}
	ADD(@"Static hosts", staticHosts)

	ADD(@"Name servers",
	    [resolver.nameServers componentsJoinedByString: @", "]);
	ADD(@"Local domain", resolver.localDomain);
	ADD(@"Search domains",
	    [resolver.searchDomains componentsJoinedByString: @", "]);

	ADD_DOUBLE(@"Timeout", resolver.timeout);
	ADD_UINT(@"Max attempts", resolver.maxAttempts);
	ADD_UINT(@"Min number of dots in absolute name",
	    resolver.minNumberOfDotsInAbsoluteName);
	ADD_BOOL(@"Forces TCP", resolver.forcesTCP);
	ADD_DOUBLE(@"Config reload interval", resolver.configReloadInterval);

#undef ADD
#undef ADD_DOUBLE
#undef ADD_UINT
#undef ADD_BOOL

	return summary;
}
@end
