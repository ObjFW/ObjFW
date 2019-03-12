/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDNSResolver.h"
#import "OFSandbox.h"
#import "OFStdIOStream.h"

@interface OFDNS: OFObject <OFApplicationDelegate, OFDNSResolverDelegate>
@end

OF_APPLICATION_DELEGATE(OFDNS)

@implementation OFDNS
-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
	 answerRecords: (of_dns_resolver_records_t)answerRecords
      authorityRecords: (of_dns_resolver_records_t)authorityRecords
     additionalRecords: (of_dns_resolver_records_t)additionalRecords
	     exception: (id)exception
{
	if (exception != nil) {
		[of_stderr writeFormat: @"Failed to resolve: %@\n", exception];
		[OFApplication terminateWithStatus: 1];
	}

	[of_stdout writeFormat: @"FQDN: %@\n"
				@"Answer records: %@\n"
				@"Authority records: %@\n"
				@"Additional records: %@\n",
				domainName, answerRecords, authorityRecords,
				additionalRecords];

	[OFApplication terminate];
}

- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString *) *arguments = [OFApplication arguments];
	of_dns_resource_record_class_t recordClass =
	    OF_DNS_RESOURCE_RECORD_CLASS_ANY;
	of_dns_resource_record_type_t recordType =
	    OF_DNS_RESOURCE_RECORD_TYPE_ALL;
	OFDNSResolver *resolver;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [[OFSandbox alloc] init];
	@try {
		sandbox.allowsStdIO = true;
		sandbox.allowsDNS = true;

		[OFApplication activateSandbox: sandbox];
	} @finally {
		[sandbox release];
	}
#endif

	if (arguments.count < 1 || arguments.count > 4) {
		[of_stderr writeFormat:
		    @"Usage: %@ host [type [class [server]]]\n",
		    [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	resolver = [OFDNSResolver resolver];

	if (arguments.count >= 2)
		recordType = of_dns_resource_record_type_parse(
		    [arguments objectAtIndex: 1]);

	if (arguments.count >= 3)
		recordClass = of_dns_resource_record_class_parse(
		    [arguments objectAtIndex: 2]);

	if (arguments.count >= 4) {
		resolver.configReloadInterval = 0;
		resolver.nameServers =
		    [arguments objectsInRange: of_range(3, 1)];
	}

	[resolver asyncResolveHost: [arguments objectAtIndex: 0]
		       recordClass: recordClass
			recordType: recordType
			  delegate: self];
}
@end
