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

static const of_run_loop_mode_t resolveRunLoopMode =
    @"of_host_address_resolver_resolve_mode";

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
    const of_socket_address_t **address,
    of_socket_address_family_t addressFamily)
{
	switch ([record recordType]) {
#ifdef OF_HAVE_IPV6
	case OF_DNS_RECORD_TYPE_AAAA:
		if (addressFamily != OF_SOCKET_ADDRESS_FAMILY_IPV6 &&
		    addressFamily != OF_SOCKET_ADDRESS_FAMILY_ANY)
			return false;
		break;
#endif
	case OF_DNS_RECORD_TYPE_A:
		if (addressFamily != OF_SOCKET_ADDRESS_FAMILY_IPV4 &&
		    addressFamily != OF_SOCKET_ADDRESS_FAMILY_ANY)
			return false;
		break;
	default:
		return false;
	}

	*address = [record address];
	return true;
}

static void
callDelegateInMode(of_run_loop_mode_t runLoopMode,
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

@implementation OFHostAddressResolver: OFObject
- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (of_socket_address_family_t)addressFamily
		    resolver: (OFDNSResolver *)resolver
		    settings: (OFDNSResolverSettings *)settings
		 runLoopMode: (of_run_loop_mode_t)runLoopMode
		    delegate: (id <OFDNSResolverHostDelegate>)delegate
{
	self = [super init];

	@try {
		_host = [host copy];
		_addressFamily = addressFamily;
		_resolver = [resolver retain];
		_settings = [settings copy];
		_runLoopMode = [runLoopMode copy];
		_delegate = [delegate retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];
	[_resolver release];
	[_settings release];
	[_runLoopMode release];
	[_delegate release];
	[_addresses release];

	[super dealloc];
}

- (void)sendQueries
{
	OFString *domainName;

	if (!_isFQDN) {
		OFString *searchDomain = [_settings->_searchDomains
		    objectAtIndex: _searchDomainIndex];

		domainName = [OFString stringWithFormat: @"%@.%@",
							 _host, searchDomain];
	} else
		domainName = _host;

#ifdef OF_HAVE_IPV6
	if (_addressFamily == OF_SOCKET_ADDRESS_FAMILY_IPV6 ||
	    _addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY) {
		OFDNSQuery *query = [OFDNSQuery
		    queryWithDomainName: domainName
			       DNSClass: OF_DNS_CLASS_IN
			     recordType: OF_DNS_RECORD_TYPE_AAAA];
		_numExpectedResponses++;
		[_resolver asyncPerformQuery: query
				 runLoopMode: _runLoopMode
				    delegate: self];
	}
#endif

	if (_addressFamily == OF_SOCKET_ADDRESS_FAMILY_IPV4 ||
	    _addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY) {
		OFDNSQuery *query = [OFDNSQuery
		    queryWithDomainName: domainName
			       DNSClass: OF_DNS_CLASS_IN
			     recordType: OF_DNS_RECORD_TYPE_A];
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
	    [exception error] == OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR &&
	    !_isFQDN && _numExpectedResponses == 0 && _addresses.count == 0 &&
	    _searchDomainIndex + 1 < _settings->_searchDomains.count) {
		_searchDomainIndex++;
		[self sendQueries];
		return;
	}

	for (OF_KINDOF(OFDNSResourceRecord *) record in
	    [response.answerRecords objectForKey: query.domainName]) {
		const of_socket_address_t *address;
		OFDNSQuery *CNAMEQuery;

		if ([record DNSClass] != OF_DNS_CLASS_IN)
			continue;

		if (addressForRecord(record, &address, _addressFamily)) {
			[_addresses addItem: address];
			continue;
		}

		if ([record recordType] != OF_DNS_RECORD_TYPE_CNAME)
			continue;

		/* FIXME: Check if it's already in answers */
		CNAMEQuery = [OFDNSQuery queryWithDomainName: [record alias]
						    DNSClass: OF_DNS_CLASS_IN
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
		[_addresses release];
		_addresses = nil;

		if (exception == nil)
			exception = [OFResolveHostFailedException
			    exceptionWithHost: _host
				addressFamily: _addressFamily
					error: OF_DNS_RESOLVER_ERROR_NO_RESULT];
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
		of_socket_address_t address =
		    of_socket_address_parse_ip(_host, 0);
		OFData *addresses = nil;
		id exception = nil;

		if (_addressFamily == address.family ||
		    _addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY)
			addresses = [OFData dataWithItems: &address
						 itemSize: sizeof(address)
						    count: 1];
		else
			exception = [OFInvalidArgumentException exception];

		callDelegateInMode(_runLoopMode, _delegate, _resolver, _host,
		    addresses, exception);

		objc_autoreleasePoolPop(pool);
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	if ((aliases = [_settings->_staticHosts objectForKey: _host]) != nil) {
		OFMutableData *addresses = [OFMutableData
		    dataWithItemSize: sizeof(of_socket_address_t)];
		id exception = nil;

		for (OFString *alias in aliases) {
			of_socket_address_t address;

			@try {
				address = of_socket_address_parse_ip(alias, 0);
			} @catch (OFInvalidFormatException *e) {
				continue;
			}

			if (_addressFamily != address.family &&
			    _addressFamily != OF_SOCKET_ADDRESS_FAMILY_ANY)
				continue;

			[addresses addItem: &address];
		}

		[addresses makeImmutable];

		if (addresses.count == 0) {
			addresses = nil;
			exception = [OFResolveHostFailedException
			    exceptionWithHost: _host
				addressFamily: _addressFamily
					error: OF_DNS_RESOLVER_ERROR_NO_RESULT];
		}

		callDelegateInMode(_runLoopMode, _delegate, _resolver, _host,
		    addresses, exception);

		objc_autoreleasePoolPop(pool);
		return;
	}

	_isFQDN = isFQDN(_host, _settings->_minNumberOfDotsInAbsoluteName);
	_addresses = [[OFMutableData alloc]
	    initWithItemSize: sizeof(of_socket_address_t)];

	[self sendQueries];

	objc_autoreleasePoolPop(pool);
}

- (OFData *)resolve
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFHostAddressResolverDelegate *delegate;
	OFData *ret;

	delegate = [[[OFHostAddressResolverDelegate alloc] init] autorelease];
	_runLoopMode = [resolveRunLoopMode copy];
	_delegate = [delegate retain];

	[self asyncResolve];

	while (!delegate->_done)
		[runLoop runMode: resolveRunLoopMode
		      beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: resolveRunLoopMode
	      beforeDate: [OFDate date]];

	if (delegate->_exception != nil)
		@throw delegate->_exception;

	ret = [delegate->_addresses copy];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end

@implementation OFHostAddressResolverDelegate
- (void)dealloc
{
	[_addresses release];
	[_exception release];

	[super dealloc];
}

- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (OFData *)addresses
       exception: (id)exception
{
	_addresses = [addresses copy];
	_exception = [exception retain];
	_done = true;
}
@end
