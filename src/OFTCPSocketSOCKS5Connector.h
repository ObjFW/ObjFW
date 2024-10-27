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

#import "OFTCPSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

@interface OFTCPSocketSOCKS5Connector: OFObject <OFTCPSocketDelegate>
{
	OFTCPSocket *_socket;
	OFString *_host;
	uint16_t _port;
	id <OFTCPSocketDelegate> _Nullable _delegate;
#ifdef OF_HAVE_BLOCKS
	OFTCPSocketConnectedHandler _Nullable _handler;
#endif
	id _Nullable _exception;
	uint_least8_t _SOCKS5State;
	/* Longest read is domain name (max 255 bytes) + port */
	unsigned char _buffer[257];
	OFMutableData *_Nullable _request;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (nullable id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
		       handler: (nullable OFTCPSocketConnectedHandler)handler
#endif
;
- (void)didConnect;
@end

OF_ASSUME_NONNULL_END
