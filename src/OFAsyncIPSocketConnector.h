/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFDNSResolver.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"

OF_ASSUME_NONNULL_BEGIN

@protocol OFAsyncIPSocketConnecting
- (bool)of_createSocketForAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo;
- (bool)of_connectSocketToAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo;
- (void)of_closeSocket;
@end

@interface OFAsyncIPSocketConnector: OFObject <OFRunLoopConnectDelegate,
    OFDNSResolverHostDelegate>
{
	id _socket;
	OFString *_host;
	uint16_t _port;
	id _Nullable _delegate;
	id _Nullable _handler;
	id _Nullable _exception;
	OFData *_Nullable _socketAddresses;
	size_t _socketAddressesIndex;
}

- (instancetype)initWithSocket: (id)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (nullable id)delegate
		       handler: (nullable id)handler;
- (void)didConnect;
- (void)tryNextAddressWithRunLoopMode: (OFRunLoopMode)runLoopMode;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
@end

OF_ASSUME_NONNULL_END
