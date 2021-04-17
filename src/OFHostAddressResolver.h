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

#import "OFObject.h"
#import "OFDNSResolver.h"
#import "OFRunLoop.h"

#import "socket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDNSResolverSettings;
@class OFDNSResourceRecord;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableData;
@class OFString;

@interface OFHostAddressResolver: OFObject <OFDNSResolverQueryDelegate>
{
	OFString *_host;
	OFSocketAddressFamily _addressFamily;
	OFDNSResolver *_resolver;
	OFDNSResolverSettings *_settings;
	OFRunLoopMode _Nullable _runLoopMode;
	id <OFDNSResolverHostDelegate> _Nullable _delegate;
	bool _isFQDN;
	size_t _searchDomainIndex;
	unsigned int _numExpectedResponses;
	OFMutableData *_addresses;
}

- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (OFSocketAddressFamily)addressFamily
		    resolver: (OFDNSResolver *)resolver
		    settings: (OFDNSResolverSettings *)settings
		 runLoopMode: (nullable OFRunLoopMode)runLoopMode
		    delegate: (nullable id <OFDNSResolverHostDelegate>)delegate;
- (void)asyncResolve;
- (OFData *)resolve;
@end

OF_ASSUME_NONNULL_END
