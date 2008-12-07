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

#import <stdlib.h>
#import <string.h>
#import <unistd.h>

#import "OFSocket.h"

@implementation OFSocketAddress
+ newWithHost: (const char*)host
      andPort: (uint16_t)port
    andFamily: (int)family
      andType: (int)type
  andProtocol: (int)protocol
{
	return [[OFSocketAddress alloc] initWithHost: host
					     andPort: port
					   andFamily: family
					     andType: type
					 andProtocol: protocol];
}

- initWithHost: (const char*)host
       andPort: (uint16_t)port
     andFamily: (int)family
       andType: (int)type
   andProtocol: (int)protocol
{
	if ((self = [super init])) {
		if (port == 0) {
			/* FIXME: Throw exception */
			[self free];
			return nil;
		}

		memset(&hints, 0, sizeof(struct addrinfo));
		hints.ai_family = family;
		hints.ai_socktype = type;
		hints.ai_protocol = protocol;

		hoststr = strdup(host);
		snprintf(portstr, 6, "%d", port);

		res = NULL;
	}

	return self;
}

- (struct addrinfo*)getAddressInfo
{
	if (res != NULL)
		return res;

	if (getaddrinfo(hoststr, portstr, &hints, &res)) {
		/* FIXME: Throw exception */
		return NULL;
	}

	return res;
}

- free
{
	free(hoststr);

	if (res != NULL)
		freeaddrinfo(res);

	return [super free];
}
@end

@implementation OFSocket
- free
{
	if (sock >= 0)
		close(sock);

	return [super free];
}

- connect: (OFSocketAddress*)addr
{
	struct addrinfo *ai, *iter;

	ai = [addr getAddressInfo];
	for (iter = ai; iter != NULL; iter = iter->ai_next) {
		if ((sock = socket(iter->ai_family, iter->ai_socktype,
		    iter->ai_protocol)) < 0)
			continue;

		if (connect(sock, iter->ai_addr, iter->ai_addrlen) < 0) {
			close(sock);
			sock = -1;
			continue;
		}

		break;
	}

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
	   fromBuffer: (uint8_t*)buf
{
	ssize_t ret;

	if ((ret = send(sock, buf, size, 0)) < 0) {
		/* FIXME: Throw exception */
		return 0;
	}

	/* This is safe, as we already checked < 0 */
	return ret;
}
@end
