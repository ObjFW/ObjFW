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

#include <string.h>

#import "OFUDPSocket.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFUDPSocket";

@implementation TestsAppDelegate (OFUDPSocketTests)
- (void)UDPSocketTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFUDPSocket *sock;
	uint16_t port1, port2;
	of_socket_address_t addr1, addr2, addr3;
	char buf[6];
	OFString *host;

	TEST(@"+[socket]", (sock = [OFUDPSocket socket]))

	TEST(@"-[bindToHost:port:]",
	    (port1 = [sock bindToHost: @"127.0.0.1"
				 port: 0]))

	addr1 = of_socket_address_parse_ip(@"127.0.0.1", port1);

	TEST(@"-[sendBuffer:length:receiver:]",
	    R([sock sendBuffer: "Hello"
			length: 6
		      receiver: &addr1]))

	TEST(@"-[receiveIntoBuffer:length:sender:]",
	    [sock receiveIntoBuffer: buf
			     length: 6
			     sender: &addr2] == 6 &&
	    !memcmp(buf, "Hello", 6) &&
	    (host = of_socket_address_ip_string(&addr2, &port2)) &&
	    [host isEqual: @"127.0.0.1"] && port2 == port1)

	addr3 = of_socket_address_parse_ip(@"127.0.0.1", port1 + 1);

	/*
	 * TODO: Move those tests elsewhere as soon as the DNS resolving part
	 *	 is no longer in OFUDPSocket.
	 */
	TEST(@"of_socket_address_equal()",
	    of_socket_address_equal(&addr1, &addr2) &&
	    !of_socket_address_equal(&addr1, &addr3))

	TEST(@"of_socket_address_hash()",
	    of_socket_address_hash(&addr1) == of_socket_address_hash(&addr2) &&
	    of_socket_address_hash(&addr1) != of_socket_address_hash(&addr3))

	[pool drain];
}
@end
