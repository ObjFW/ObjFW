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

#import "OFObject.h"
#import "OFDNSResolver.h"
#import "OFRunLoop.h"
#import "OFSocket.h"

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
