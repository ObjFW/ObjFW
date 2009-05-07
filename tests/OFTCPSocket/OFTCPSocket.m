/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#import "OFTCPSocket.h"
#import "OFExceptions.h"

inline uint16_t get_port()
{
	uint16_t port = (uint16_t)rand();

	if (port < 1024)
		port += 1024;

	printf("Using port %d...\n", port);

	return port;
}

int
main()
{
	uint16_t port;

	srand(time(NULL));

	@try {
		OFTCPSocket *server = [OFTCPSocket tcpSocket];
		OFTCPSocket *client = [OFTCPSocket tcpSocket];
		OFTCPSocket *accepted;
		char buf[7];

		puts("== IPv4 ==");
		port = get_port();

		[server bindOn: "localhost"
		      withPort: port
		     andFamily: AF_INET];
		[server listen];

		[client connectTo: "localhost"
			   onPort: port];

		accepted = [server accept];

		[client writeCString: "Hallo!"];
		[accepted readNBytes: 6
			  intoBuffer: buf];
		buf[6] = 0;

		if (!strcmp(buf, "Hallo!"))
			puts("Received correct string!");
		else {
			puts("Received INCORRECT string!");
			return 1;
		}

#ifdef HAVE_IPV6
		memset(buf, 0, 7);

		[accepted release];
		[client close];
		[server close];

		puts("== IPv6 ==");
		port = get_port();

		[server bindOn: "::1"
		      withPort: port
		     andFamily: AF_INET6];
		[server listen];

		[client connectTo: "::1"
			   onPort: port];

		accepted = [server accept];

		[client writeCString: "IPv6:)"];
		[accepted readNBytes: 6
			  intoBuffer: buf];
		buf[6] = 0;

		if (!strcmp(buf, "IPv6:)"))
			puts("Received correct string!");
		else {
			puts("Received INCORRECT string!");
			return 1;
		}
#endif

		[accepted release];
	} @catch (OFException *e) {
		printf("EXCEPTION: %s\n", [e cString]);
		return 1;
	}

	return 0;
}
