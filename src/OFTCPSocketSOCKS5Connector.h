/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
	of_tcp_socket_async_connect_block_t _Nullable _block;
#endif
	id _Nullable _exception;
	enum {
		OF_SOCKS5_STATE_SEND_AUTHENTICATION = 1,
		OF_SOCKS5_STATE_READ_VERSION,
		OF_SOCKS5_STATE_SEND_REQUEST,
		OF_SOCKS5_STATE_READ_RESPONSE,
		OF_SOCKS5_STATE_READ_ADDRESS,
		OF_SOCKS5_STATE_READ_ADDRESS_LENGTH,
	} _SOCKS5State;
	/* Longest read is domain name (max 255 bytes) + port */
	unsigned char _buffer[257];
	OFMutableData *_Nullable _request;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (nullable id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
			 block: (nullable of_tcp_socket_async_connect_block_t)
				    block
#endif
;
- (void)didConnect;
@end

OF_ASSUME_NONNULL_END
