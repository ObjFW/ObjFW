/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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
	of_udp_socket_address_t addr1, addr2, addr3;
	char buf[6];

	TEST(@"+[socket]", (sock = [OFUDPSocket socket]))

	TEST(@"-[bindToHost:port:]",
	    (port1 = [sock bindToHost: @"127.0.0.1"
				 port: 0]))

	TEST(@"+[resolveAddressForHost:port:address:]",
	    R([OFUDPSocket resolveAddressForHost: @"127.0.0.1"
					    port: port1
					 address: &addr1]))

	TEST(@"-[sendBuffer:length:receiver:]",
	    R([sock sendBuffer: "Hello"
			length: 6
		      receiver: &addr1]))

	TEST(@"-[receiveIntoBuffer:length:sender:]",
	    [sock receiveIntoBuffer: buf
			     length: 6
			     sender: &addr2] == 6 &&
	    !memcmp(buf, "Hello", 6))

	TEST(@"+[hostForAddress:port:]",
	    [[OFUDPSocket hostForAddress: &addr2
				    port: &port2] isEqual: @"127.0.0.1"] &&
	    port2 == port1)

	[OFUDPSocket resolveAddressForHost: @"127.0.0.1"
				      port: port1 + 1
				   address: &addr3];

	TEST(@"of_udp_socket_address_equal()",
	    of_udp_socket_address_equal(&addr1, &addr2) &&
	    !of_udp_socket_address_equal(&addr1, &addr3))

	TEST(@"of_udp_socket_address_hash()",
	    of_udp_socket_address_hash(&addr1) ==
	    of_udp_socket_address_hash(&addr2) &&
	    of_udp_socket_address_hash(&addr1) !=
	    of_udp_socket_address_hash(&addr3))

	[pool drain];
}
@end
