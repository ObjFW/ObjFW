/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
	id _Nullable _block;
	id _Nullable _exception;
	OFData *_Nullable _socketAddresses;
	size_t _socketAddressesIndex;
}

- (instancetype)initWithSocket: (id)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (nullable id)delegate
			 block: (nullable id)block;
- (void)didConnect;
- (void)tryNextAddressWithRunLoopMode: (OFRunLoopMode)runLoopMode;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
@end

OF_ASSUME_NONNULL_END
