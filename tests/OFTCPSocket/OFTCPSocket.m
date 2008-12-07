/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <string.h>

#import "OFTCPSocket.h"
#import "OFExceptions.h"

int
main()
{
	@try {
		OFTCPSocket *server = [OFTCPSocket new];
		OFTCPSocket *client = [OFTCPSocket new];
		OFTCPSocket *accepted;
		char buf[8];

		puts("== IPv4 ==");

		[server bindOn: "localhost"
		      withPort: 12345
		     andFamily: AF_INET];
		[server listen];

		[client connectTo: "localhost"
			   onPort: 12345];

		accepted = [server accept];

		[client writeCString: "Hallo!"];
		[accepted readNBytes: 7
			  intoBuffer: (uint8_t*)buf];
		buf[7] = 0;

		if (!strcmp(buf, "Hallo!"))
			puts("Received correct string!");
		else {
			puts("Received INCORRECT string!");
			return 1;
		}

		memset(buf, 0, 8);
		
		[accepted free];
		[client close];
		[server close];

		puts("== IPv6 ==");

		[server bindOn: "localhost"
		      withPort: 12345
		     andFamily: AF_INET6];
		[server listen];

		[client connectTo: "localhost"
			   onPort: 12345];

		accepted = [server accept];

		[client writeCString: "IPv6 :)"];
		[accepted readNBytes: 7
			  intoBuffer: (uint8_t*)buf];
		buf[7] = 0;

		if (!strcmp(buf, "IPv6 :)"))
			puts("Received correct string!");
		else {
			puts("Received INCORRECT string!");
			return 1;
		}

		[accepted free];
		[client close];
		[server close];
	} @catch(OFException *e) {
		printf("EXCEPTION: %s\n", [e cString]);
	}

	return 0;
}
