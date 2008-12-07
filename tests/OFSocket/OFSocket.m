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

#import "OFSocket.h"
#import "OFExceptions.h"

int
main()
{
	OFSocketAddress *addr;
	OFSocket *sock;

	@try {
		addr = [OFSocketAddress newWithHost: "webkeks.org"
					    andPort: 80
					  andFamily: AF_UNSPEC
					    andType: SOCK_STREAM
					andProtocol: 0];
		sock = [OFSocket new];
		[sock connect: addr];
		[addr free];

		[sock writeCString: "GET / HTTP/1.1\r\n"
				    "Host: webkeks.org\r\n\r\n"];
		puts((char*)[sock readNBytes: 1024]);

		[sock free];
	} @catch(OFException *e) {
		printf("EXCEPTION: %s\n", [e cString]);
	}

	return 0;
}
