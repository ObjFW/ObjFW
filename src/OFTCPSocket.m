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

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>

#import "OFTCPSocket.h"
#import "OFExceptions.h"

@implementation OFTCPSocket
- free
{
	if (sock >= 0)
		close(sock);

	return [super free];
}

- connectTo: (const char*)host
     onPort: (uint16_t)port
{
	struct addrinfo hints, *res, *res0;
	char portstr[6];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res0)) {
		/* FIXME: Throw exception */
		return NULL;
	}

	for (res = res0; res != NULL; res = res->ai_next) {
		if ((sock = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol)) < 0)
			continue;

		if (connect(sock, res->ai_addr, res->ai_addrlen) < 0) {
			close(sock);
			sock = -1;
			continue;
		}

		break;
	}
	
	freeaddrinfo(res0);

	if (sock < 0) {
		/* FIXME: Throw exception */
		return nil;
	}

	return self;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (uint8_t*)buf
{
	ssize_t ret;

	if ((ret = recv(sock, buf, size, 0)) < 0) {
		/* FIXME: Throw exception */
		return 0;
	}

	/* This is safe, as we already checked < 0 */
	return ret;
}

- (uint8_t*)readNBytes: (size_t)size
{
	uint8_t *ret;

	ret = [self getMemWithSize: size];

	@try {
		[self readNBytes: size
		      intoBuffer: ret];
	} @catch (id exception) {
		[self freeMem: ret];
		@throw exception;
	}

	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const uint8_t*)buf
{
	ssize_t ret;

	if ((ret = send(sock, buf, size, 0)) < 0) {
		/* FIXME: Throw exception */
		return 0;
	}

	/* This is safe, as we already checked < 0 */
	return ret;
}

- (size_t)writeCString: (const char*)str
{
	return [self writeNBytes: strlen(str)
		      fromBuffer: (const uint8_t*)str];
}

- close
{
	if (sock < 0) {
		/* FIXME: Throw exception */
		return nil;
	}

	return self;
}
@end
