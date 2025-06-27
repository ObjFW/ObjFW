/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OFHostAddressResolver.h"
#import "OFArray.h"
#import "OFDNSResolver.h"
#import "OFDNSResolverSettings.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFRunLoop.h"
#import "OFString.h"
#import "OFTimer.h"

#import "OFDNSQueryFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFResolveHostFailedException.h"

@interface OFHostAddressResolverDelegate: OFObject <OFDNSResolverHostDelegate>
{
@public
	bool _done;
	OFData *_addresses;
	id _exception;
}
@end

static const OFRunLoopMode resolveRunLoopMode =
    @"OFHostAddressResolverResolveRunLoopMode";

static bool
isFQDN(OFString *host, unsigned int minNumberOfDotsInAbsoluteName)
{
	const char *UTF8String;
	size_t length;
	unsigned int dots;

	if ([host hasSuffix: @"."])
		return true;

	UTF8String = host.UTF8String;
	length = host.UTF8StringLength;
	dots = 0;

	for (size_t i = 0; i < length; i++)
		if (UTF8String[i] == '.')
			dots++;

	return (dots >= minNumberOfDotsInAbsoluteName);
}

static bool
addressForRecord(OF_KINDOF(OFDNSResourceRecord *) record,
    const OFSocketAddress **address, OFSocketAddressFamily addressFamily)
{
	switch ([record recordType]) {
#ifdef OF_HAVE_IPV6
	case OFDNSRecordTypeAAAA:
		if (addressFamily != OFSocketAddressFamilyIPv6 &&
		    addressFamily != OFSocketAddressFamilyAny)
			return false;
		break;
#endif
	case OFDNSRecordTypeA:
		if (addressFamily != OFSocketAddressFamilyIPv4 &&
		    addressFamily != OFSocketAddressFamilyAny)
			return false;
		break;
	default:
		return false;
	}

	*address = [record address];
	return true;
}

static void
callDelegateInMode(OFRunLoopMode runLoopMode,
    id <OFDNSResolverHostDelegate> delegate, OFDNSResolver *resolver,
    OFString *host, OFData *addresses, id exception)
{
	SEL selector = @selector(resolver:didResolveHost:addresses:exception:);

	if ([delegate respondsToSelector: selector]) {
		OFTimer *timer = [OFTimer
		    timerWithTimeInterval: 0
				   target: delegate
				 selector: selector
				   object: resolver
				   object: host
				   object: addresses
				   object: exception
				  repeats: false];
		[[OFRunLoop currentRunLoop] addTimer: timer
					     forMode: runLoopMode];
	}
}

@implementation OFHostAddressResolver
- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (OFSocketAddressFamily)addressFamily
		    resolver: (OFDNSResolver *)resolver
		    settings: (OFDNSResolverSettings *)settings
		 runLoopMode: (OFRunLoopMode)runLoopMode
		    delegate: (id <OFDNSResolverHostDelegate>)delegate
{
	self = [super init];

	@try {
		_host = [host copy];
		_addressFamily = addressFamily;
		_resolver = objc_retain(resolver);
		_settings = [settings copy];
		_runLoopMode = [runLoopMode copy];
		_delegate = objc_retain(delegate);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_host);
	objc_release(_resolver);
	objc_release(_settings);
	objc_release(_runLoopMode);
	objc_release(_delegate);
	objc_release(_addresses);

	[super dealloc];
}

- (void)sendQueries
{
	OFString *domainName;

	if (!_isFQDN) {
		OFString *searchDomain = @"";

		if (_searchDomainIndex < _settings->_searchDomains.count)
			searchDomain = [_settings->_searchDomains
			    objectAtIndex: _searchDomainIndex];

		domainName = [OFString stringWithFormat: @"%@.%@",
							 _host, searchDomain];
	} else
		domainName = _host;

#ifdef OF_HAVE_IPV6
	if (_addressFamily == OFSocketAddressFamilyIPv6 ||
	    _addressFamily == OFSocketAddressFamilyAny) {
		OFDNSQuery *query = [OFDNSQuery
		    queryWithDomainName: domainName
			       DNSClass: OFDNSClassIN
			     recordType: OFDNSRecordTypeAAAA];
		_numExpectedResponses++;
		[_resolver asyncPerformQuery: query
				 runLoopMode: _runLoopMode
				    delegate: self];
	}
#endif

	if (_addressFamily == OFSocketAddressFamilyIPv4 ||
	    _addressFamily == OFSocketAddressFamilyAny) {
		OFDNSQuery *query = [OFDNSQuery
		    queryWithDomainName: domainName
			       DNSClass: OFDNSClassIN
			     recordType: OFDNSRecordTypeA];
		_numExpectedResponses++;
		[_resolver asyncPerformQuery: query
				 runLoopMode: _runLoopMode
				    delegate: self];
	}
}

-  (void)resolver: (OFDNSResolver *)resolver
  didPerformQuery: (OFDNSQuery *)query
	 response: (OFDNSResponse *)response
	exception: (id)exception
{
	_numExpectedResponses--;

	if ([exception isKindOfClass: [OFDNSQueryFailedException class]] &&
	    [exception errorCode] == OFDNSResolverErrorCodeServerNameError &&
	    !_isFQDN && _numExpectedResponses == 0 && _addresses.count == 0 &&
	    _searchDomainIndex + 1 < _settings->_searchDomains.count) {
		_searchDomainIndex++;
		[self sendQueries];
		return;
	}

	for (OF_KINDOF(OFDNSResourceRecord *) record in
	    [response.answerRecords objectForKey: query.domainName]) {
		const OFSocketAddress *address = NULL;
		OFDNSQuery *CNAMEQuery;

		if ([record DNSClass] != OFDNSClassIN)
			continue;

		if (addressForRecord(record, &address, _addressFamily)) {
			[_addresses addItem: address];
			continue;
		}

		if ([record recordType] != OFDNSRecordTypeCNAME)
			continue;

		/* FIXME: Check if it's already in answers */
		CNAMEQuery = [OFDNSQuery queryWithDomainName: [record alias]
						    DNSClass: OFDNSClassIN
						  recordType: query.recordType];
		_numExpectedResponses++;
		[_resolver asyncPerformQuery: CNAMEQuery
				 runLoopMode: _runLoopMode
				    delegate: self];
	}

	if (_numExpectedResponses > 0)
		return;

	[_addresses makeImmutable];

	if (_addresses.count == 0) {
		objc_release(_addresses);
		_addresses = nil;

		if ([exception isKindOfClass:
		    [OFDNSQueryFailedException class]])
			exception = [OFResolveHostFailedException
			    exceptionWithHost: _host
				addressFamily: _addressFamily
				    errorCode: [exception errorCode]];

		if (exception == nil)
			exception = [OFResolveHostFailedException
			    exceptionWithHost: _host
				addressFamily: _addressFamily
				    errorCode: OFDNSResolverErrorCodeNoResult];
	} else
		exception = nil;

	if ([_delegate respondsToSelector:
	    @selector(resolver:didResolveHost:addresses:exception:)])
		[_delegate resolver: _resolver
		     didResolveHost: _host
			  addresses: _addresses
			  exception: exception];
}

- (void)asyncResolve
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFString *) *aliases;

	@try {
		OFSocketAddress address = OFSocketAddressParseIP(_host, 0);
		OFData *addresses = nil;
		id exception = nil;

		if (_addressFamily == address.family ||
		    _addressFamily == OFSocketAddressFamilyAny)
			addresses = [OFData dataWithItems: &address
						    count: 1
						 itemSize: sizeof(address)];
		else
			exception = [OFInvalidArgumentException exception];

		callDelegateInMode(_runLoopMode, _delegate, _resolver, _host,
		    addresses, exception);

		objc_autoreleasePoolPop(pool);
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	if ((aliases = [_settings->_staticHosts objectForKey:
	    _host.lowercaseString]) != nil) {
		OFMutableData *addresses = [OFMutableData
		    dataWithItemSize: sizeof(OFSocketAddress)];
		id exception = nil;

		for (OFString *alias in aliases) {
			OFSocketAddress address;

			@try {
				address = OFSocketAddressParseIP(alias, 0);
			} @catch (OFInvalidFormatException *e) {
				continue;
			}

			if (_addressFamily != address.family &&
			    _addressFamily != OFSocketAddressFamilyAny)
				continue;

			[addresses addItem: &address];
		}

		[addresses makeImmutable];

		if (addresses.count == 0) {
			addresses = nil;
			exception = [OFResolveHostFailedException
			    exceptionWithHost: _host
				addressFamily: _addressFamily
				    errorCode: OFDNSResolverErrorCodeNoResult];
		}

		callDelegateInMode(_runLoopMode, _delegate, _resolver, _host,
		    addresses, exception);

		objc_autoreleasePoolPop(pool);
		return;
	}

	_isFQDN = isFQDN(_host, _settings->_minNumberOfDotsInAbsoluteName);
	_addresses = [[OFMutableData alloc]
	    initWithItemSize: sizeof(OFSocketAddress)];

	[self sendQueries];

	objc_autoreleasePoolPop(pool);
}

- (OFData *)resolve
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFHostAddressResolverDelegate *delegate;
	OFData *ret;

	delegate = [[OFHostAddressResolverDelegate alloc] init];
	_delegate = delegate;
	_runLoopMode = [resolveRunLoopMode copy];

	[self asyncResolve];

	while (!delegate->_done)
		[runLoop runMode: resolveRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: resolveRunLoopMode beforeDate: [OFDate date]];

	if (delegate->_exception != nil)
		@throw delegate->_exception;

	ret = [delegate->_addresses copy];
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
}
@end

@implementation OFHostAddressResolverDelegate
- (void)dealloc
{
	objc_release(_addresses);
	objc_release(_exception);

	[super dealloc];
}

- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (OFData *)addresses
       exception: (id)exception
{
	_addresses = [addresses copy];
	_exception = objc_retain(exception);
	_done = true;
}
@end
