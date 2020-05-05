/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

@protocol OFIPSocketAsyncConnecting
- (bool)of_createSocketForAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo;
- (bool)of_connectSocketToAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo;
- (void)of_closeSocket;
@end

@interface OFIPSocketAsyncConnector: OFObject <OFRunLoopConnectDelegate,
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

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (nullable id)delegate
			 block: (nullable id)block;
- (void)didConnect;
- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
@end

OF_ASSUME_NONNULL_END
