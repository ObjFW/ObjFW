/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#include <errno.h>
#include <string.h>
#include "unistd_wrapper.h"

#import "OFDNSResolver.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFPair.h"
#import "OFString.h"
#import "OFTimer.h"
#import "OFUDPSocket.h"
#import "OFUDPSocket+Private.h"
#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFResolveHostFailedException.h"
#import "OFTruncatedDataException.h"

#ifdef OF_WINDOWS
# define interface struct
# include <iphlpapi.h>
# undef interface
#endif

#import "socket_helpers.h"

#ifdef OF_NINTENDO_3DS
# include <3ds.h>
#endif

#ifndef SOCK_DNS
# define SOCK_DNS 0
#endif

#define BUFFER_LENGTH OF_DNS_RESOLVER_BUFFER_LENGTH

/*
 * RFC 1035 doesn't specify if pointers to pointers are allowed, and if so how
 * many. Since it's unspecified, we have to assume that it might happen, but we
 * also want to limit it to avoid DoS. Limiting it to 16 levels of pointers and
 * immediately rejecting pointers to itself seems like a fair balance.
 */
#define MAX_ALLOWED_POINTERS 16

#define CNAME_RECURSION 3

#if defined(OF_HAIKU)
# define HOSTS_PATH @"/system/settings/network/hosts"
# define RESOLV_CONF_PATH @"/system/settings/network/resolv.conf"
#elif defined(OF_MORPHOS)
# define HOSTS_PATH @"ENV:sys/net/hosts"
# define RESOLV_CONF_PATH @"ENV:sys/net/resolv.conf"
#elif defined(OF_AMIGAOS4)
# define HOSTS_PATH @"DEVS:Internet/hosts"
#elif defined(OF_AMIGAOS)
# define HOSTS_PATH @"AmiTCP:db/hosts"
# define RESOLV_CONF_PATH @"AmiTCP:db/resolv.conf"
#else
# define HOSTS_PATH @"/etc/hosts"
# define RESOLV_CONF_PATH @"/etc/resolv.conf"
#endif

/*
 * TODO:
 *
 *  - Fallback to TCP
 */

static const of_run_loop_mode_t resolveRunLoopMode =
    @"of_dns_resolver_resolve_mode";

@interface OFDNSResolverSettings: OFObject
{
@public
	OFArray OF_GENERIC(OFString *) *_nameServers, *_searchDomains;
	of_time_interval_t _timeout;
	unsigned int _maxAttempts, _minNumberOfDotsInAbsoluteName;
}

- (instancetype)
	      initWithNameServers: (OFArray *)nameServers
		    searchDomains: (OFArray *)searchDomains
			  timeout: (of_time_interval_t)timeout
		      maxAttempts: (unsigned int)maxAttempts
    minNumberOfDotsInAbsoluteName: (unsigned int)minNumberOfDotsInAbsoluteName;
@end

@interface OFDNSResolverQuery: OFObject
{
@public
	OFString *_host, *_domainName;
	of_dns_resource_record_class_t _recordClass;
	of_dns_resource_record_type_t _recordType;
	OFNumber *_ID;
	OFDNSResolverSettings *_settings;
	size_t _nameServersIndex, _searchDomainsIndex;
	unsigned int _attempt;
	id _target;
	SEL _selector;
	id _context;
	OFData *_queryData;
	of_socket_address_t _usedNameServer;
	OFTimer *_cancelTimer;
}

- (instancetype)initWithHost: (OFString *)host
		  domainName: (OFString *)domainName
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			  ID: (OFNumber *)ID
		    settings: (OFDNSResolverSettings *)settings
	    nameServersIndex: (size_t)nameServersIndex
	  searchDomainsIndex: (size_t)searchDomainsIndex
		      target: (id)target
		    selector: (SEL)selector
		     context: (id)context;
@end

@interface OFDNSResolverAsyncResolveSocketAddressesContext: OFObject
{
	OFString *_host;
	id _delegate;
	OFMutableArray OF_GENERIC(OF_KINDOF(OFDNSResourceRecord *)) *_records;
	OFDNSResolver *_resolver;
	OFString *_domainName;
@public
	unsigned int _expectedResponses;
}

- (instancetype)initWithHost: (OFString *)host
		    delegate: (id)delegate;
- (bool)parseRecords: (OFArray *)records
       answerRecords: (OFDictionary *)answerRecords
   additionalRecords: (OFDictionary *)additionalRecords
	  recordType: (of_dns_resource_record_type_t)recordType
	   recursion: (unsigned int)recursion
	      result: (OFMutableArray *)result;
- (void)resolveCNAME: (OFCNAMEDNSResourceRecord *)CNAME
       answerRecords: (OFDictionary *)answerRecords
   additionalRecords: (OFDictionary *)additionalRecords
	  recordType: (of_dns_resource_record_type_t)recordType
	   recursion: (unsigned int)recursion
	      result: (OFMutableArray *)result;
-    (void)resolver: (OFDNSResolver *)resolver
    didResolveCNAME: (OFString *)CNAME
      answerRecords: (OFDictionary *)answerRecords
   authorityRecords: (OFDictionary *)authorityRecords
  additionalRecords: (OFDictionary *)additionalRecords
	    context: (OFNumber *)context
	  exception: (id)exception;
- (void)done;
-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
	 answerRecords: (OFDictionary *)answerRecords
      authorityRecords: (OFDictionary *)authorityRecords
     additionalRecords: (OFDictionary *)additionalRecords
	       context: (OFNumber *)context
	     exception: (id)exception;
@end

@interface OFDNSResolverResolveSocketAddressesDelegate: OFObject
    <OFDNSResolverDelegate>
{
@public
	bool _done;
	OFData *_socketAddresses;
	id _exception;
}
@end

@interface OFDNSResolver () <OFUDPSocketDelegate>
- (void)of_setDefaults;
- (void)of_obtainSystemConfig;
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_3DS)
- (void)of_parseHosts: (OFString *)path;
# if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS4)
- (void)of_parseResolvConf: (OFString *)path;
- (void)of_parseResolvConfOption: (OFString *)option;
# endif
#endif
#ifdef OF_WINDOWS
- (void)of_obtainWindowsSystemConfig;
#endif
#ifdef OF_AMIGAOS4
- (void)of_obtainAmigaOS4SystemConfig;
#endif
#ifdef OF_NINTENDO_3DS
- (void)of_obtainNintendo3DSSytemConfig;
#endif
- (void)of_reloadSystemConfig;
- (void)of_resolveHost: (OFString *)host
	   recordClass: (of_dns_resource_record_class_t)recordClass
	    recordType: (of_dns_resource_record_type_t)recordType
	      settings: (OFDNSResolverSettings *)settings
      nameServersIndex: (size_t)nameServersIndex
    searchDomainsIndex: (size_t)searchDomainsIndex
	   runLoopMode: (of_run_loop_mode_t)runLoopMode
		target: (id)target
	      selector: (SEL)selector
	       context: (id)context;
- (void)of_asyncResolveHost: (OFString *)host
		recordClass: (of_dns_resource_record_class_t)recordClass
		 recordType: (of_dns_resource_record_type_t)recordType
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		     target: (id)target
		   selector: (SEL)selector
		    context: (id)context;
- (void)of_sendQuery: (OFDNSResolverQuery *)query
	 runLoopMode: (of_run_loop_mode_t)runLoopMode;
- (void)of_queryWithIDTimedOut: (OFDNSResolverQuery *)query;
@end

#ifndef OF_WII
static OFString *
domainFromHostname(void)
{
	char hostname[256];
	OFString *domain;

	if (gethostname(hostname, 256) != 0)
		return nil;

	domain = [OFString stringWithCString: hostname
				    encoding: [OFLocale encoding]];

	@try {
		of_socket_address_parse_ip(domain, 0);

		/*
		 * If we are still here, the host name is a valid IP address.
		 * We can't use that as local domain.
		 */
		return nil;
	} @catch (OFInvalidFormatException *e) {
		/* Not an IP address -> we can use it if it contains a dot. */
		size_t pos = [domain rangeOfString: @"."].location;

		if (pos == OF_NOT_FOUND)
			return nil;

		return [domain substringWithRange:
		    of_range(pos + 1, domain.length - pos - 1)];
	}
}
#endif

static bool
isFQDN(OFString *host, OFDNSResolverSettings *settings)
{
	const char *UTF8String = host.UTF8String;
	size_t length = host.UTF8StringLength;
	unsigned int dots = 0;

	if ([host hasSuffix: @"."])
		return true;

	for (size_t i = 0; i < length; i++)
		if (UTF8String[i] == '.')
			dots++;

	return (dots >= settings->_minNumberOfDotsInAbsoluteName);
}

static OFString *
parseString(const unsigned char *buffer, size_t length, size_t *i)
{
	uint8_t stringLength;
	OFString *string;

	if (*i >= length)
		@throw [OFTruncatedDataException exception];

	stringLength = buffer[(*i)++];

	if (*i + stringLength > length)
		@throw [OFTruncatedDataException exception];

	string = [OFString stringWithUTF8String: (char *)&buffer[*i]
					 length: stringLength];
	*i += stringLength;

	return string;
}

static OFString *
parseName(const unsigned char *buffer, size_t length, size_t *i,
    uint_fast8_t pointerLevel)
{
	OFMutableArray *components = [OFMutableArray array];
	uint8_t componentLength;

	do {
		OFString *component;

		if (*i >= length)
			@throw [OFTruncatedDataException exception];

		componentLength = buffer[(*i)++];

		if (componentLength & 0xC0) {
			size_t j;
			OFString *suffix;

			if (pointerLevel == 0)
				@throw [OFInvalidServerReplyException
				    exception];

			if (*i >= length)
				@throw [OFTruncatedDataException exception];

			j = ((componentLength & 0x3F) << 8) | buffer[(*i)++];

			if (j == *i - 2)
				/* Pointing to itself?! */
				@throw [OFInvalidServerReplyException
				    exception];

			suffix = parseName(buffer, length, &j,
			    pointerLevel - 1);

			if (components.count == 0)
				return suffix;
			else {
				[components addObject: suffix];
				return [components
				    componentsJoinedByString: @"."];
			}
		}

		if (*i + componentLength > length)
			@throw [OFTruncatedDataException exception];

		component = [OFString stringWithUTF8String: (char *)&buffer[*i]
						    length: componentLength];
		*i += componentLength;

		[components addObject: component];
	} while (componentLength > 0);

	return [components componentsJoinedByString: @"."];
}

static OF_KINDOF(OFDNSResourceRecord *)
parseResourceRecord(OFString *name, of_dns_resource_record_class_t recordClass,
    of_dns_resource_record_type_t recordType, uint32_t TTL,
    const unsigned char *buffer, size_t length, size_t i, uint16_t dataLength)
{
	if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_A &&
	    recordClass == OF_DNS_RESOURCE_RECORD_CLASS_IN) {
		of_socket_address_t address;

		if (dataLength != 4)
			@throw [OFInvalidServerReplyException exception];

		memset(&address, 0, sizeof(address));
		address.family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
		address.length = sizeof(address.sockaddr.in);

		address.sockaddr.in.sin_family = AF_INET;
		memcpy(&address.sockaddr.in.sin_addr.s_addr, buffer + i, 4);

		return [[[OFADNSResourceRecord alloc]
		    initWithName: name
			 address: &address
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_NS) {
		size_t j = i;
		OFString *authoritativeHost = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFNSDNSResourceRecord alloc]
			 initWithName: name
			  recordClass: recordClass
		    authoritativeHost: authoritativeHost
				  TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_CNAME) {
		size_t j = i;
		OFString *alias = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFCNAMEDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
			   alias: alias
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_SOA) {
		size_t j = i;
		OFString *primaryNameServer = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);
		OFString *responsiblePerson;
		uint32_t serialNumber, refreshInterval, retryInterval;
		uint32_t expirationInterval, minTTL;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		responsiblePerson = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (dataLength - (j - i) != 20)
			@throw [OFInvalidServerReplyException exception];

		serialNumber = (buffer[j] << 24) | (buffer[j + 1] << 16) |
		    (buffer[j + 2] << 8) | buffer[j + 3];
		refreshInterval = (buffer[j + 4] << 24) |
		    (buffer[j + 5] << 16) | (buffer[j + 6] << 8) |
		    buffer[j + 7];
		retryInterval = (buffer[j + 8] << 24) | (buffer[j + 9] << 16) |
		    (buffer[j + 10] << 8) | buffer[j + 11];
		expirationInterval = (buffer[j + 12] << 24) |
		    (buffer[j + 13] << 16) | (buffer[j + 14] << 8) |
		    buffer[j + 15];
		minTTL = (buffer[j + 16] << 24) | (buffer[j + 17] << 16) |
		    (buffer[j + 18] << 8) | buffer[j + 19];

		return [[[OFSOADNSResourceRecord alloc]
			  initWithName: name
			   recordClass: recordClass
		     primaryNameServer: primaryNameServer
		     responsiblePerson: responsiblePerson
			  serialNumber: serialNumber
		       refreshInterval: refreshInterval
			 retryInterval: retryInterval
		    expirationInterval: expirationInterval
				minTTL: minTTL
				   TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_PTR) {
		size_t j = i;
		OFString *domainName = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFPTRDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
		      domainName: domainName
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_HINFO) {
		size_t j = i;
		OFString *CPU = parseString(buffer, length, &j);
		OFString *OS;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		OS = parseString(buffer, length, &j);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFHINFODNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
			     CPU: CPU
			      OS: OS
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_MX) {
		uint16_t preference;
		size_t j;
		OFString *mailExchange;

		if (dataLength < 2)
			@throw [OFInvalidServerReplyException exception];

		preference = (buffer[i] << 8) | buffer[i + 1];

		j = i + 2;
		mailExchange = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFMXDNSResourceRecord alloc]
			    initWithName: name
			     recordClass: recordClass
			      preference: preference
			    mailExchange: mailExchange
				     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_TXT) {
		OFData *textData = [OFData dataWithItems: &buffer[i]
						   count: dataLength];

		return [[[OFTXTDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
			textData: textData
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_RP) {
		size_t j = i;
		OFString *mailbox = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);
		OFString *TXTDomainName;

		if (j > i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		TXTDomainName = parseName(buffer, length, &j,
		    MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFRPDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
			 mailbox: mailbox
		   TXTDomainName: TXTDomainName
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_AAAA &&
	    recordClass == OF_DNS_RESOURCE_RECORD_CLASS_IN) {
		of_socket_address_t address;

		if (dataLength != 16)
			@throw [OFInvalidServerReplyException exception];

		memset(&address, 0, sizeof(address));
		address.family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
		address.length = sizeof(address.sockaddr.in6);

#ifdef AF_INET6
		address.sockaddr.in6.sin6_family = AF_INET6;
#else
		address.sockaddr.in6.sin6_family = AF_UNSPEC;
#endif
		memcpy(address.sockaddr.in6.sin6_addr.s6_addr, buffer + i, 16);

		return [[[OFAAAADNSResourceRecord alloc]
		    initWithName: name
			 address: &address
			     TTL: TTL] autorelease];
	} else if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_SRV &&
	    recordClass == OF_DNS_RESOURCE_RECORD_CLASS_IN) {
		uint16_t priority, weight, port;
		size_t j;
		OFString *target;

		if (dataLength < 6)
			@throw [OFInvalidServerReplyException exception];

		priority = (buffer[i] << 8) | buffer[i + 1];
		weight = (buffer[i + 2] << 8) | buffer[i + 3];
		port = (buffer[i + 4] << 8) | buffer[i + 5];

		j = i + 6;
		target = parseName(buffer, length, &j, MAX_ALLOWED_POINTERS);

		if (j != i + dataLength)
			@throw [OFInvalidServerReplyException exception];

		return [[[OFSRVDNSResourceRecord alloc]
			    initWithName: name
				priority: priority
				  weight: weight
				  target: target
				    port: port
				     TTL: TTL] autorelease];
	} else
		return [[[OFDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
		      recordType: recordType
			     TTL: TTL] autorelease];
}

static OFDictionary *
parseSection(const unsigned char *buffer, size_t length, size_t *i,
    uint_fast16_t count)
{
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	OFEnumerator OF_GENERIC(OFMutableArray *) *objectEnumerator;
	OFMutableArray *array;

	for (uint_fast16_t j = 0; j < count; j++) {
		OFString *name = parseName(buffer, length, i,
		    MAX_ALLOWED_POINTERS);
		of_dns_resource_record_class_t recordClass;
		of_dns_resource_record_type_t recordType;
		uint32_t TTL;
		uint16_t dataLength;
		OFDNSResourceRecord *record;

		if (*i + 10 > length)
			@throw [OFTruncatedDataException exception];

		recordType = (buffer[*i] << 16) | buffer[*i + 1];
		recordClass = (buffer[*i + 2] << 16) | buffer[*i + 3];
		TTL = (buffer[*i + 4] << 24) | (buffer[*i + 5] << 16) |
		    (buffer[*i + 6] << 8) | buffer[*i + 7];
		dataLength = (buffer[*i + 8] << 16) | buffer[*i + 9];

		*i += 10;

		if (*i + dataLength > length)
			@throw [OFTruncatedDataException exception];

		record = parseResourceRecord(name, recordClass, recordType, TTL,
		    buffer, length, *i, dataLength);
		*i += dataLength;

		array = [ret objectForKey: name];

		if (array == nil) {
			array = [OFMutableArray array];
			[ret setObject: array
				forKey: name];
		}

		[array addObject: record];
	}

	objectEnumerator = [ret objectEnumerator];
	while ((array = [objectEnumerator nextObject]) != nil)
		[array makeImmutable];

	[ret makeImmutable];

	return ret;
}

static void callback(id target, SEL selector, OFDNSResolver *resolver,
    OFString *domainName, OFDictionary *answerRecords,
    OFDictionary *authorityRecords, OFDictionary *additionalRecords, id context,
    id exception)
{
	void (*method)(id, SEL, OFDNSResolver *, OFString *, OFDictionary *,
	    OFDictionary *, OFDictionary *, id, id) = (void (*)(id, SEL,
	    OFDNSResolver *, OFString *, OFDictionary *, OFDictionary *,
	    OFDictionary *, id, id))[target methodForSelector: selector];

	method(target, selector, resolver, domainName, answerRecords,
	    authorityRecords, additionalRecords, context, exception);
}

@implementation OFDNSResolverSettings
- (instancetype)initWithNameServers: (OFArray *)nameServers
		      searchDomains: (OFArray *)searchDomains
			    timeout: (of_time_interval_t)timeout
			maxAttempts: (unsigned int)maxAttempts
      minNumberOfDotsInAbsoluteName: (unsigned int)minNumberOfDotsInAbsoluteName
{
	self = [super init];

	@try {
		_nameServers = [nameServers copy];
		_searchDomains = [searchDomains copy];
		_timeout = timeout;
		_maxAttempts = maxAttempts;
		_minNumberOfDotsInAbsoluteName = minNumberOfDotsInAbsoluteName;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_nameServers release];
	[_searchDomains release];

	[super dealloc];
}
@end

@implementation OFDNSResolverQuery
- (instancetype)initWithHost: (OFString *)host
		  domainName: (OFString *)domainName
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			  ID: (OFNumber *)ID
		    settings: (OFDNSResolverSettings *)settings
	    nameServersIndex: (size_t)nameServersIndex
	  searchDomainsIndex: (size_t)searchDomainsIndex
		      target: (id)target
		    selector: (SEL)selector
		     context: (id)context
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableData *queryData;
		uint16_t tmp;

		_host = [host copy];
		_domainName = [domainName copy];
		_recordClass = recordClass;
		_recordType = recordType;
		_ID = [ID retain];
		_settings = [settings retain];
		_nameServersIndex = nameServersIndex;
		_searchDomainsIndex = searchDomainsIndex;
		_target = [target retain];
		_selector = selector;
		_context = [context retain];

		queryData = [OFMutableData dataWithCapacity: 512];

		/* Header */

		tmp = OF_BSWAP16_IF_LE(ID.uInt16Value);
		[queryData addItems: &tmp
			      count: 2];

		/* RD */
		tmp = OF_BSWAP16_IF_LE(1 << 8);
		[queryData addItems: &tmp
			      count: 2];

		/* QDCOUNT */
		tmp = OF_BSWAP16_IF_LE(1);
		[queryData addItems: &tmp
			      count: 2];

		/* ANCOUNT, NSCOUNT and ARCOUNT */
		[queryData increaseCountBy: 6];

		/* Question */

		/* QNAME */
		for (OFString *component in
		    [domainName componentsSeparatedByString: @"."]) {
			size_t length = component.UTF8StringLength;
			uint8_t length8;

			if (length > 63 || queryData.count + length > 512)
				@throw [OFOutOfRangeException exception];

			length8 = (uint8_t)length;
			[queryData addItem: &length8];
			[queryData addItems: component.UTF8String
				      count: length];
		}

		/* QTYPE */
		tmp = OF_BSWAP16_IF_LE(recordType);
		[queryData addItems: &tmp
			      count: 2];

		/* QCLASS */
		tmp = OF_BSWAP16_IF_LE(recordClass);
		[queryData addItems: &tmp
			 count: 2];

		[queryData makeImmutable];

		_queryData = [queryData copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];
	[_domainName release];
	[_ID release];
	[_settings release];
	[_target release];
	[_context release];
	[_queryData release];
	[_cancelTimer release];

	[super dealloc];
}
@end

@implementation OFDNSResolverAsyncResolveSocketAddressesContext
- (instancetype)initWithHost: (OFString *)host
		    delegate: (id)delegate
{
	self = [super init];

	@try {
		_host = [host copy];
		_delegate = [delegate retain];

		_records = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];
	[_delegate release];
	[_records release];
	[_resolver release];
	[_domainName release];

	[super dealloc];
}

- (bool)parseRecords: (OFArray *)records
       answerRecords: (OFDictionary *)answerRecords
   additionalRecords: (OFDictionary *)additionalRecords
	  recordType: (of_dns_resource_record_type_t)recordType
	   recursion: (unsigned int)recursion
	      result: (OFMutableArray *)result
{
	bool found = false;

	for (OFDNSResourceRecord *record in records) {
		if (record.recordClass != OF_DNS_RESOURCE_RECORD_CLASS_IN)
			continue;

		if (record.recordType == recordType) {
			[result addObject: record];
			found = true;
		} else if (record.recordType ==
		    OF_DNS_RESOURCE_RECORD_TYPE_CNAME) {
			[self	resolveCNAME: (OFCNAMEDNSResourceRecord *)record
			       answerRecords: answerRecords
			   additionalRecords: additionalRecords
				  recordType: recordType
				   recursion: recursion
				      result: result];
			found = true;
		}
	}

	return found;
}

- (void)resolveCNAME: (OFCNAMEDNSResourceRecord *)CNAME
       answerRecords: (OFDictionary *)answerRecords
   additionalRecords: (OFDictionary *)additionalRecords
	  recordType: (of_dns_resource_record_type_t)recordType
	   recursion: (unsigned int)recursion
	      result: (OFMutableArray *)result
{
	OFString *alias = CNAME.alias;
	bool found = false;

	if (recursion == 0)
		return;

	if ([self parseRecords: [answerRecords objectForKey: alias]
		 answerRecords: answerRecords
	     additionalRecords: additionalRecords
		    recordType: recordType
		     recursion: recursion - 1
			result: result])
		found = true;

	if ([self parseRecords: [additionalRecords objectForKey: alias]
		 answerRecords: answerRecords
	     additionalRecords: additionalRecords
		    recordType: recordType
		     recursion: recursion - 1
			result: result])
		found = true;

	if (!found) {
		of_run_loop_mode_t runLoopMode =
		    [OFRunLoop currentRunLoop].currentMode;
		OFNumber *recordTypeNumber =
		    [OFNumber numberWithInt: recordType];

		_expectedResponses++;

		[result addObject:
		    [OFPair pairWithFirstObject: CNAME
				   secondObject: recordTypeNumber]];

		[_resolver of_asyncResolveHost: alias
				   recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
				    recordType: recordType
				   runLoopMode: runLoopMode
					target: self
				      selector: @selector(resolver:
						    didResolveCNAME:
						    answerRecords:
						    authorityRecords:
						    additionalRecords:context:
						    exception:)
				       context: recordTypeNumber];
	}
}

-    (void)resolver: (OFDNSResolver *)resolver
    didResolveCNAME: (OFString *)CNAME
      answerRecords: (OFDictionary *)answerRecords
   authorityRecords: (OFDictionary *)authorityRecords
  additionalRecords: (OFDictionary *)additionalRecords
	    context: (OFNumber *)context
	  exception: (id)exception
{
	/*
	 * TODO: Error handling could be improved. Ignore error if there are
	 * responses, otherwise propagate error.
	 */

	of_dns_resource_record_type_t recordType = context.unsignedIntValue;
	bool found = false;
	OFMutableArray *records;
	size_t count;

	OF_ENSURE(resolver == _resolver);

	_expectedResponses--;

	if (exception != nil) {
		if (_expectedResponses == 0)
			[self done];

		return;
	}

	records = [OFMutableArray array];

	if ([self parseRecords: [answerRecords objectForKey: CNAME]
		 answerRecords: answerRecords
	     additionalRecords: additionalRecords
		    recordType: recordType
		     recursion: CNAME_RECURSION
			result: records])
		found = true;

	if ([self parseRecords: [additionalRecords objectForKey: CNAME]
		 answerRecords: answerRecords
	     additionalRecords: additionalRecords
		    recordType: recordType
		     recursion: CNAME_RECURSION
			result: records])
		found = true;

	if (!found) {
		if (_expectedResponses == 0)
			[self done];

		return;
	}

	count = _records.count;
	for (size_t i = 0; i < count; i++) {
		id object = [_records objectAtIndex: i];

		if (![object isKindOfClass: [OFPair class]])
			continue;

		if (![[[object firstObject] alias] isEqual: CNAME])
			continue;

		if ([[object secondObject] unsignedIntValue] != recordType)
			continue;

		[_records removeObjectAtIndex: i];
		[_records insertObjectsFromArray: records
					 atIndex: i];
		i += records.count - 1;
	}

	if (_expectedResponses == 0)
		[self done];
}

- (void)done
{
	OFMutableData *addresses =
	    [OFMutableData dataWithItemSize: sizeof(of_socket_address_t)];
	id exception = nil;

	for (id record in _records) {
		if (![record isKindOfClass: [OFDNSResourceRecord class]])
			continue;

		switch ([record recordType]) {
		case OF_DNS_RESOURCE_RECORD_TYPE_A:
		case OF_DNS_RESOURCE_RECORD_TYPE_AAAA:
			[addresses addItem: [record address]];
			break;
		default:
			break;
		}
	}

	[addresses makeImmutable];

	if (addresses.count == 0)
		exception = [OFResolveHostFailedException
		    exceptionWithHost: _host
			  recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
			   recordType: 0
				error: OF_DNS_RESOLVER_ERROR_UNKNOWN];

	if ([_delegate respondsToSelector: @selector(
	    resolver:didResolveDomainName:socketAddresses:exception:)])
		[_delegate	resolver: _resolver
		    didResolveDomainName: _domainName
			 socketAddresses: (exception == nil ? addresses : nil)
			       exception: exception];
}

-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
	 answerRecords: (OFDictionary *)answerRecords
      authorityRecords: (OFDictionary *)authorityRecords
     additionalRecords: (OFDictionary *)additionalRecords
	       context: (OFNumber *)context
	     exception: (id)exception
{
	/*
	 * TODO: Error handling could be improved. Ignore error if there are
	 * responses, otherwise propagate error.
	 */

	of_dns_resource_record_type_t recordType = context.unsignedIntValue;

	if (_resolver != nil)
		OF_ENSURE(resolver == _resolver);
	else
		_resolver = [resolver retain];

	_expectedResponses--;

	if (_domainName != nil) {
		if (![domainName isEqual: _domainName])
			/* Did the config change between requests? */
			return;
	} else
		_domainName = [domainName copy];

	if (exception != nil) {
		if (_expectedResponses == 0)
			[self done];

		return;
	}

	[self parseRecords: [answerRecords objectForKey: _domainName]
	     answerRecords: answerRecords
	 additionalRecords: additionalRecords
		recordType: recordType
		 recursion: CNAME_RECURSION
		    result: _records];

	if (_expectedResponses == 0)
		[self done];
}
@end

@implementation OFDNSResolverResolveSocketAddressesDelegate
- (void)dealloc
{
	[_socketAddresses release];
	[_exception release];

	[super dealloc];
}

-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
       socketAddresses: (OFData *)socketAddresses
	     exception: (id)exception
{
	_socketAddresses = [socketAddresses retain];
	_exception = [exception retain];
	_done = true;
}
@end

@implementation OFDNSResolver
@synthesize staticHosts = _staticHosts, nameServers = _nameServers;
@synthesize localDomain = _localDomain, searchDomains = _searchDomains;
@synthesize timeout = _timeout, maxAttempts = _maxAttempts;
@synthesize minNumberOfDotsInAbsoluteName = _minNumberOfDotsInAbsoluteName;
@synthesize usesTCP = _usesTCP, configReloadInterval = _configReloadInterval;

#ifdef OF_AMIGAOS
+ (void)initialize
{
	if (self != [OFDNSResolver class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (instancetype)resolver
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_queries = [[OFMutableDictionary alloc] init];

		[self of_obtainSystemConfig];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)of_setDefaults
{
	_timeout = 2;
	_maxAttempts = 3;
	_minNumberOfDotsInAbsoluteName = 1;
	_usesTCP = false;
#ifndef OF_NINTENDO_3DS
	_configReloadInterval = 2;
#else
	_configReloadInterval = 0;
#endif
}

- (void)of_obtainSystemConfig
{
	void *pool = objc_autoreleasePoolPush();
#ifdef OF_WINDOWS
	OFString *path;
#endif

	[self of_setDefaults];

#if defined(OF_WINDOWS)
# ifdef OF_HAVE_FILES
	path = [[OFWindowsRegistryKey localMachineKey]
	    stringForValue: @"DataBasePath"
		subkeyPath: @"SYSTEM\\CurrentControlSet\\Services\\"
			    @"Tcpip\\Parameters"];
	path = [path stringByAppendingPathComponent: @"hosts"];

	if (path != nil)
		[self of_parseHosts: path];
# endif

	[self of_obtainWindowsSystemConfig];
#elif defined(OF_AMIGAOS4)
	[self of_parseHosts: HOSTS_PATH];
	[self of_obtainAmigaOS4SystemConfig];
#elif defined(OF_NINTENDO_3DS)
	[self of_obtainNintendo3DSSytemConfig];
#elif defined(OF_HAVE_FILES)
	[self of_parseHosts: HOSTS_PATH];
	[self of_parseResolvConf: RESOLV_CONF_PATH];
#endif

	if (_staticHosts == nil) {
		OFArray *localhost =
#ifdef OF_HAVE_IPV6
		    [OFArray arrayWithObjects: @"::1", @"127.0.0.1", nil];
#else
		    [OFArray arrayWithObject: @"127.0.0.1"];
#endif

		_staticHosts = [[OFDictionary alloc]
		    initWithObject: localhost
			    forKey: @"localhost"];
	}

	if (_nameServers == nil)
#ifdef OF_HAVE_IPV6
		_nameServers = [[OFArray alloc]
		    initWithObjects: @"127.0.0.1", @"::1", nil];
#else
		_nameServers = [[OFArray alloc] initWithObject: @"127.0.0.1"];
#endif

#ifndef OF_WII
	if (_localDomain == nil)
		_localDomain = [domainFromHostname() copy];
#endif

	if (_searchDomains == nil) {
		if (_localDomain != nil)
			_searchDomains = [[OFArray alloc]
			    initWithObject: _localDomain];
		else
			_searchDomains = [[OFArray alloc] init];
	}

	_lastConfigReload = [[OFDate alloc] init];

	objc_autoreleasePoolPop(pool);
}

- (void)dealloc
{
	[self close];

	[_staticHosts release];
	[_nameServers release];
	[_localDomain release];
	[_searchDomains release];
	[_lastConfigReload release];
	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket release];
#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket release];
#endif
	[_queries release];

	[super dealloc];
}

#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_3DS)
- (void)of_parseHosts: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *whitespaceCharacterSet =
	    [OFCharacterSet whitespaceCharacterSet];
	OFMutableDictionary *staticHosts;
	OFFile *file;
	OFString *line;
	OFEnumerator *enumerator;
	OFMutableArray *addresses;

	@try {
		file = [OFFile fileWithPath: path
				       mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	staticHosts = [OFMutableDictionary dictionary];

	while ((line = [file readLine]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		OFArray *components, *hosts;
		size_t pos;
		OFString *address;

		pos = [line rangeOfString: @"#"].location;
		if (pos != OF_NOT_FOUND)
			line = [line substringWithRange: of_range(0, pos)];

		components = [line
		    componentsSeparatedByCharactersInSet: whitespaceCharacterSet
						 options: OF_STRING_SKIP_EMPTY];

		if (components.count < 2) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		address = components.firstObject;
		hosts = [components objectsInRange:
		    of_range(1, components.count - 1)];

		for (OFString *host in hosts) {
			addresses = [staticHosts objectForKey: host];

			if (addresses == nil) {
				addresses = [OFMutableArray array];
				[staticHosts setObject: addresses
						forKey: host];
			}

			[addresses addObject: address];
		}

		objc_autoreleasePoolPop(pool2);
	}

	enumerator = [staticHosts objectEnumerator];
	while ((addresses = [enumerator nextObject]) != nil)
		[addresses makeImmutable];

	[staticHosts makeImmutable];

	[_staticHosts release];
	_staticHosts = [staticHosts copy];

	objc_autoreleasePoolPop(pool);
}

# if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS4)
- (void)of_parseResolvConf: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *whitespaceCharacterSet =
	    [OFCharacterSet whitespaceCharacterSet];
	OFCharacterSet *commentCharacters = [OFCharacterSet
	    characterSetWithCharactersInString: @"#;"];
	OFMutableArray *nameServers = [[_nameServers mutableCopy] autorelease];
	OFFile *file;
	OFString *line;

	@try {
		file = [OFFile fileWithPath: path
				       mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (nameServers == nil)
		nameServers = [OFMutableArray array];

	while ((line = [file readLine]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		size_t pos;
		OFArray *components, *arguments;
		OFString *option;

		pos = [line indexOfCharacterFromSet: commentCharacters];
		if (pos != OF_NOT_FOUND)
			line = [line substringWithRange: of_range(0, pos)];

		components = [line
		    componentsSeparatedByCharactersInSet: whitespaceCharacterSet
						 options: OF_STRING_SKIP_EMPTY];

		if (components.count < 2) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		option = components.firstObject;
		arguments = [components objectsInRange:
		    of_range(1, components.count - 1)];

		if ([option isEqual: @"nameserver"]) {
			if (arguments.count != 1) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}

			[nameServers addObject: [arguments firstObject]];
		} else if ([option isEqual: @"domain"]) {
			if (arguments.count != 1) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}

			[_localDomain release];
			_localDomain = [arguments.firstObject copy];
		} else if ([option isEqual: @"search"]) {
			[_searchDomains release];
			_searchDomains = [arguments copy];
		} else if ([option isEqual: @"options"])
			for (OFString *argument in arguments)
				[self of_parseResolvConfOption: argument];

		objc_autoreleasePoolPop(pool2);
	}

	[nameServers makeImmutable];

	[_nameServers release];
	_nameServers = [nameServers copy];

	objc_autoreleasePoolPop(pool);
}

- (void)of_parseResolvConfOption: (OFString *)option
{
	@try {
		if ([option hasPrefix: @"ndots:"]) {
			option = [option substringWithRange:
			    of_range(6, option.length - 6)];

			_minNumberOfDotsInAbsoluteName =
			    (unsigned int)option.decimalValue;
		} else if ([option hasPrefix: @"timeout:"]) {
			option = [option substringWithRange:
			    of_range(8, option.length - 8)];

			_timeout = option.decimalValue;
		} else if ([option hasPrefix: @"attempts:"]) {
			option = [option substringWithRange:
			    of_range(9, option.length - 9)];

			_maxAttempts = (unsigned int)option.decimalValue;
		} else if ([option hasPrefix: @"reload-period:"]) {
			option = [option substringWithRange:
			    of_range(14, option.length - 14)];

			_configReloadInterval = option.decimalValue;
		} else if ([option isEqual: @"tcp"])
			_usesTCP = true;
	} @catch (OFInvalidFormatException *e) {
	}
}
# endif
#endif

#ifdef OF_WINDOWS
- (void)of_obtainWindowsSystemConfig
{
	of_string_encoding_t encoding = [OFLocale encoding];
	OFMutableArray *nameServers;
	/*
	 * We need more space than FIXED_INFO in case we have more than one
	 * name server, but we also want it to be properly aligned, meaning we
	 * can't just get a buffer of bytes. Thus, we just get space for 8.
	 */
	FIXED_INFO fixedInfo[8];
	ULONG length = sizeof(fixedInfo);
	PIP_ADDR_STRING iter;

	if (GetNetworkParams(fixedInfo, &length) != ERROR_SUCCESS)
		return;

	nameServers = [OFMutableArray array];

	for (iter = &fixedInfo->DnsServerList; iter != NULL; iter = iter->Next)
		[nameServers addObject:
		    [OFString stringWithCString: iter->IpAddress.String
				       encoding: encoding]];

	if (nameServers.count > 0) {
		[nameServers makeImmutable];
		_nameServers = [nameServers copy];
	}

	if (fixedInfo->DomainName[0] != '\0')
		_localDomain = [[OFString alloc]
		    initWithCString: fixedInfo->DomainName
			   encoding: encoding];
}
#endif

#ifdef OF_AMIGAOS4
- (void)of_obtainAmigaOS4SystemConfig
{
	OFMutableArray *nameServers = [OFMutableArray array];
	of_string_encoding_t encoding = [OFLocale encoding];
	struct List *nameServerList = ObtainDomainNameServerList();
	char buffer[MAXHOSTNAMELEN];

	if (nameServerList == NULL)
		@throw [OFOutOfMemoryException exception];

	@try {
		struct DomainNameServerNode *iter =
		    (struct DomainNameServerNode *)&nameServerList->lh_Head;

		while (iter->dnsn_MinNode.mln_Succ != NULL) {
			if (iter->dnsn_UseCount != 0 &&
			    iter->dnsn_Address != NULL) {
				OFString *address = [OFString
				    stringWithCString: iter->dnsn_Address
					     encoding: encoding];

				[nameServers addObject: address];
			}

			iter = (struct DomainNameServerNode *)
			    iter->dnsn_MinNode.mln_Succ;
		}
	} @finally {
		ReleaseDomainNameServerList(nameServerList);
	}

	if (nameServers.count > 0) {
		[nameServers makeImmutable];
		_nameServers = [nameServers copy];
	}

	if (GetDefaultDomainName(buffer, sizeof(buffer)))
		_localDomain = [[OFString alloc] initWithCString: buffer
							encoding: encoding];
}
#endif

#ifdef OF_NINTENDO_3DS
- (void)of_obtainNintendo3DSSytemConfig
{
	OFMutableArray *nameServers = [OFMutableArray array];
	union {
		/*
		 * For some unknown reason, this needs a 336 bytes buffer and
		 * always returns 336 bytes.
		 */
		char bytes[336];
		SOCU_DNSTableEntry entries[2];
	} buffer;
	socklen_t optLen = sizeof(buffer);

	if (SOCU_GetNetworkOpt(SOL_CONFIG, NETOPT_DNS_TABLE,
	    &buffer, &optLen) != 0)
		return;

	/*
	 * We're fine if this gets smaller in a future release (unlikely), as
	 * long as two entries still fit.
	 */
	if (optLen < sizeof(buffer.entries))
		return;

	for (uint_fast8_t i = 0; i < 2; i++) {
		uint32_t ip = OF_BSWAP32_IF_LE(buffer.entries[i].ip.s_addr);

		if (ip == 0)
			continue;

		[nameServers addObject: [OFString stringWithFormat:
		    @"%u.%u.%u.%u", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF,
		    (ip >> 8) & 0xFF, ip & 0xFF]];
	}

	if (nameServers.count > 0) {
		[nameServers makeImmutable];
		_nameServers = [nameServers copy];
	}
}
#endif

- (void)of_reloadSystemConfig
{
	/*
	 * TODO: Rather than reparsing every time, check what actually changed
	 *	 (mtime) and only reset those.
	 */

	if (_lastConfigReload != nil && _configReloadInterval > 0 &&
	    _lastConfigReload.timeIntervalSinceNow < _configReloadInterval)
		return;

	[_staticHosts release];
	_staticHosts = nil;

	[_nameServers release];
	_nameServers = nil;

	[_localDomain release];
	_localDomain = nil;

	[_searchDomains release];
	_searchDomains = nil;

	[self of_setDefaults];

	[_lastConfigReload release];
	_lastConfigReload = nil;

	[self of_obtainSystemConfig];
}

- (void)of_resolveHost: (OFString *)host
	   recordClass: (of_dns_resource_record_class_t)recordClass
	    recordType: (of_dns_resource_record_type_t)recordType
	      settings: (OFDNSResolverSettings *)settings
      nameServersIndex: (size_t)nameServersIndex
    searchDomainsIndex: (size_t)searchDomainsIndex
	   runLoopMode: (of_run_loop_mode_t)runLoopMode
		target: (id)target
	      selector: (SEL)selector
	       context: (id)context
{
	void *pool = objc_autoreleasePoolPush();
	OFNumber *ID;
	OFString *domainName;
	OFDNSResolverQuery *query;

	[self of_reloadSystemConfig];

	/* Random, unused ID */
	do {
		ID = [OFNumber numberWithUInt16: (uint16_t)of_random()];
	} while ([_queries objectForKey: ID] != nil);

	if (isFQDN(host, settings)) {
		domainName = host;

		if (![domainName hasSuffix: @"."])
			domainName = [domainName stringByAppendingString: @"."];
	} else {
		OFString *searchDomain = [settings->_searchDomains
		    objectAtIndex: searchDomainsIndex];

		domainName = [OFString stringWithFormat: @"%@.%@.",
		    host, searchDomain];
	}

	if (domainName.UTF8StringLength > 253)
		@throw [OFOutOfRangeException exception];

	query = [[[OFDNSResolverQuery alloc]
		  initWithHost: host
		    domainName: domainName
		   recordClass: recordClass
		    recordType: recordType
			    ID: ID
		      settings: settings
	      nameServersIndex: nameServersIndex
	    searchDomainsIndex: searchDomainsIndex
			target: target
		      selector: selector
		       context: context] autorelease];
	[_queries setObject: query
		     forKey: ID];

	[self of_sendQuery: query
	       runLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

-    (void)of_resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
	 answerRecords: (of_dns_resolver_records_t)answerRecords
      authorityRecords: (of_dns_resolver_records_t)authorityRecords
     additionalRecords: (of_dns_resolver_records_t)additionalRecords
	       context: (id)delegate
	     exception: (id)exception
{
	if ([delegate respondsToSelector: @selector(resolver:
	    didResolveDomainName:answerRecords:authorityRecords:
	    additionalRecords:exception:)])
		[delegate	resolver: resolver
		    didResolveDomainName: domainName
			   answerRecords: answerRecords
			authorityRecords: authorityRecords
		       additionalRecords: additionalRecords
			       exception: exception];
}

- (void)asyncResolveHost: (OFString *)host
		delegate: (id <OFDNSResolverDelegate>)delegate
{
	[self of_asyncResolveHost: host
		      recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
		       recordType: OF_DNS_RESOURCE_RECORD_TYPE_ALL
		      runLoopMode: of_run_loop_mode_default
			   target: self
			 selector: @selector(of_resolver:didResolveDomainName:
				       answerRecords:authorityRecords:
				       additionalRecords:context:exception:)
			  context: delegate];
}

- (void)asyncResolveHost: (OFString *)host
	     recordClass: (of_dns_resource_record_class_t)recordClass
	      recordType: (of_dns_resource_record_type_t)recordType
		delegate: (id <OFDNSResolverDelegate>)delegate
{
	[self of_asyncResolveHost: host
		      recordClass: recordClass
		       recordType: recordType
		      runLoopMode: of_run_loop_mode_default
			   target: self
			 selector: @selector(of_resolver:didResolveDomainName:
				       answerRecords:authorityRecords:
				       additionalRecords:context:exception:)
			  context: delegate];
}

- (void)asyncResolveHost: (OFString *)host
	     recordClass: (of_dns_resource_record_class_t)recordClass
	      recordType: (of_dns_resource_record_type_t)recordType
	     runLoopMode: (of_run_loop_mode_t)runLoopMode
		delegate: (id <OFDNSResolverDelegate>)delegate
{
	[self of_asyncResolveHost: host
		      recordClass: recordClass
		       recordType: recordType
		      runLoopMode: runLoopMode
			   target: self
			 selector: @selector(of_resolver:didResolveDomainName:
				       answerRecords:authorityRecords:
				       additionalRecords:context:exception:)
			  context: delegate];
}

- (void)of_asyncResolveHost: (OFString *)host
		recordClass: (of_dns_resource_record_class_t)recordClass
		 recordType: (of_dns_resource_record_type_t)recordType
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		     target: (id)target
		   selector: (SEL)selector
		    context: (id)context
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSResolverSettings *settings = [[[OFDNSResolverSettings alloc]
		      initWithNameServers: _nameServers
			    searchDomains: _searchDomains
				  timeout: _timeout
			      maxAttempts: _maxAttempts
	    minNumberOfDotsInAbsoluteName: _minNumberOfDotsInAbsoluteName]
	    autorelease];

	[self of_resolveHost: host
		 recordClass: recordClass
		  recordType: recordType
		    settings: settings
	    nameServersIndex: 0
	  searchDomainsIndex: 0
		 runLoopMode: runLoopMode
		      target: target
		    selector: selector
		     context: context];

	objc_autoreleasePoolPop(pool);
}

- (void)of_sendQuery: (OFDNSResolverQuery *)query
	 runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFUDPSocket *sock;
	OFString *nameServer;

	[query->_cancelTimer invalidate];
	[query->_cancelTimer release];
	query->_cancelTimer = nil;
	query->_cancelTimer = [[OFTimer alloc]
	    initWithFireDate: [OFDate dateWithTimeIntervalSinceNow:
				  query->_settings->_timeout]
		    interval: query->_settings->_timeout
		      target: self
		    selector: @selector(of_queryWithIDTimedOut:)
		      object: query
		     repeats: false];
	[[OFRunLoop currentRunLoop] addTimer: query->_cancelTimer
				     forMode: runLoopMode];

	nameServer = [query->_settings->_nameServers
	    objectAtIndex: query->_nameServersIndex];
	query->_usedNameServer = of_socket_address_parse_ip(nameServer, 53);

	switch (query->_usedNameServer.family) {
#ifdef OF_HAVE_IPV6
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		if (_IPv6Socket == nil) {
			of_socket_address_t address =
			    of_socket_address_parse_ip(@"::", 0);

			_IPv6Socket = [[OFUDPSocket alloc] init];
			[_IPv6Socket of_bindToAddress: &address
					    extraType: SOCK_DNS];
			_IPv6Socket.blocking = false;
			_IPv6Socket.delegate = self;
			[_IPv6Socket asyncReceiveIntoBuffer: _buffer
						     length: BUFFER_LENGTH];
		}

		sock = _IPv6Socket;
		break;
#endif
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
		if (_IPv4Socket == nil) {
			of_socket_address_t address =
			    of_socket_address_parse_ip(@"0.0.0.0", 0);

			_IPv4Socket = [[OFUDPSocket alloc] init];
			[_IPv4Socket of_bindToAddress: &address
					    extraType: SOCK_DNS];
			_IPv4Socket.blocking = false;
			_IPv4Socket.delegate = self;
			[_IPv4Socket asyncReceiveIntoBuffer: _buffer
						     length: BUFFER_LENGTH];
		}

		sock = _IPv4Socket;
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	[sock asyncSendData: query->_queryData
		   receiver: &query->_usedNameServer
		runLoopMode: runLoopMode];
}

- (void)of_queryWithIDTimedOut: (OFDNSResolverQuery *)query
{
	OFResolveHostFailedException *exception;

	if (query == nil)
		return;

	if (query->_nameServersIndex + 1 <
	    query->_settings->_nameServers.count) {
		query->_nameServersIndex++;
		[self of_sendQuery: query
		       runLoopMode: [OFRunLoop currentRunLoop].currentMode];
		return;
	}

	if (query->_attempt < query->_settings->_maxAttempts) {
		query->_attempt++;
		query->_nameServersIndex = 0;
		[self of_sendQuery: query
		       runLoopMode: [OFRunLoop currentRunLoop].currentMode];
		return;
	}

	query = [[query retain] autorelease];
	[_queries removeObjectForKey: query->_ID];

	/*
	 * Cancel any pending requests, to avoid a send being still pending and
	 * trying to access the query once it no longer exists.
	 */
	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket asyncReceiveIntoBuffer: _buffer
				     length: BUFFER_LENGTH];
#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket asyncReceiveIntoBuffer: _buffer
				     length: BUFFER_LENGTH];
#endif

	exception = [OFResolveHostFailedException
	    exceptionWithHost: query->_host
		  recordClass: query->_recordClass
		   recordType: query->_recordType
			error: OF_DNS_RESOLVER_ERROR_TIMEOUT];

	callback(query->_target, query->_selector, self, query->_domainName,
	    nil, nil, nil, query->_context, exception);
}

-	  (bool)socket: (OFUDPSocket *)sock
  didReceiveIntoBuffer: (void *)buffer_
		length: (size_t)length
		sender: (const of_socket_address_t *)sender
	     exception: (id)exception
{
	unsigned char *buffer = buffer_;
	OFDictionary *answerRecords = nil, *authorityRecords = nil;
	OFDictionary *additionalRecords = nil;
	OFNumber *ID;
	OFDNSResolverQuery *query;

	if (exception != nil)
		return true;

	if (length < 2)
		/* We can't get the ID to get the query. Ignore packet. */
		return true;

	ID = [OFNumber numberWithUInt16: (buffer[0] << 8) | buffer[1]];
	query = [[[_queries objectForKey: ID] retain] autorelease];

	if (query == nil)
		return true;

	if (!of_socket_address_equal(sender, &query->_usedNameServer))
		return true;

	[query->_cancelTimer invalidate];
	[query->_cancelTimer release];
	query->_cancelTimer = nil;
	[_queries removeObjectForKey: ID];

	@try {
		const unsigned char *queryDataBuffer;
		size_t i;
		of_dns_resolver_error_t error;
		uint16_t numQuestions, numAnswers, numAuthorityRecords;
		uint16_t numAdditionalRecords;

		if (length < 12)
			@throw [OFTruncatedDataException exception];

		if (query->_queryData.itemSize != 1 ||
		    query->_queryData.count < 12)
			@throw [OFInvalidArgumentException exception];

		queryDataBuffer = query->_queryData.items;

		/* QR */
		if ((buffer[2] & 0x80) == 0)
			@throw [OFInvalidServerReplyException exception];

		/* Opcode */
		if ((buffer[2] & 0x78) != (queryDataBuffer[2] & 0x78))
			@throw [OFInvalidServerReplyException exception];

		/* TC */
		if (buffer[2] & 0x02)
			@throw [OFTruncatedDataException exception];

		/* RCODE */
		switch (buffer[3] & 0x0F) {
		case 0:
			break;
		case 1:
			error = OF_DNS_RESOLVER_ERROR_SERVER_INVALID_FORMAT;
			break;
		case 2:
			error = OF_DNS_RESOLVER_ERROR_SERVER_FAILURE;
			break;
		case 3:
			if (query->_searchDomainsIndex + 1 <
			    query->_settings->_searchDomains.count) {
				of_run_loop_mode_t runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;

				query->_searchDomainsIndex++;

				[self of_resolveHost: query->_host
					 recordClass: query->_recordClass
					  recordType: query->_recordType
					    settings: query->_settings
				    nameServersIndex: query->_nameServersIndex
				  searchDomainsIndex: query->_searchDomainsIndex
					 runLoopMode: runLoopMode
					      target: query->_target
					    selector: query->_selector
					     context: query->_context];

				return true;
			}

			error = OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR;
			break;
		case 4:
			error = OF_DNS_RESOLVER_ERROR_SERVER_NOT_IMPLEMENTED;
			break;
		case 5:
			error = OF_DNS_RESOLVER_ERROR_SERVER_REFUSED;
			break;
		default:
			error = OF_DNS_RESOLVER_ERROR_UNKNOWN;
			break;
		}

		if (buffer[3] & 0x0F)
			@throw [OFResolveHostFailedException
			    exceptionWithHost: query->_host
				  recordClass: query->_recordClass
				   recordType: query->_recordType
					error: error];

		numQuestions = (buffer[4] << 8) | buffer[5];
		numAnswers = (buffer[6] << 8) | buffer[7];
		numAuthorityRecords = (buffer[8] << 8) | buffer[9];
		numAdditionalRecords = (buffer[10] << 8) | buffer[11];

		i = 12;

		/*
		 * Skip over the questions - we use the ID to identify the
		 * query.
		 *
		 * TODO: Compare to our query, just in case?
		 */
		for (uint_fast16_t j = 0; j < numQuestions; j++) {
			parseName(buffer, length, &i, MAX_ALLOWED_POINTERS);
			i += 4;
		}

		answerRecords = parseSection(buffer, length, &i, numAnswers);
		authorityRecords = parseSection(buffer, length, &i,
		    numAuthorityRecords);
		additionalRecords = parseSection(buffer, length, &i,
		    numAdditionalRecords);
	} @catch (id e) {
		callback(query->_target, query->_selector, self,
		    query->_domainName, nil, nil, nil, query->_context, e);
		return true;
	}

	callback(query->_target, query->_selector, self, query->_domainName,
	    answerRecords, authorityRecords, additionalRecords,
	    query->_context, nil);

	return true;
}

- (void)asyncResolveSocketAddressesForHost: (OFString *)host
				  delegate: (id <OFDNSResolverDelegate>)delegate
{
	[self asyncResolveSocketAddressesForHost: host
				   addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY
				     runLoopMode: of_run_loop_mode_default
					delegate: delegate];
}

- (void)asyncResolveSocketAddressesForHost: (OFString *)host
			     addressFamily: (of_socket_address_family_t)
						addressFamily
				  delegate: (id <OFDNSResolverDelegate>)delegate
{
	[self asyncResolveSocketAddressesForHost: host
				   addressFamily: addressFamily
				     runLoopMode: of_run_loop_mode_default
					delegate: delegate];
}

- (void)asyncResolveSocketAddressesForHost: (OFString *)host
			     addressFamily: (of_socket_address_family_t)
						addressFamily
			       runLoopMode: (of_run_loop_mode_t)runLoopMode
				  delegate: (id <OFDNSResolverDelegate>)delegate
{
	OFArray OF_GENERIC(OFString *) *aliases;
	void *pool;
	OFDNSResolverAsyncResolveSocketAddressesContext *context;

	@try {
		of_socket_address_t address =
		    of_socket_address_parse_ip(host, 0);
		OFData *addresses = nil;
		id exception = nil;

		if (addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY ||
		    addressFamily == address.family)
			addresses = [OFData dataWithItems: &address
						 itemSize: sizeof(address)
						    count: 1];
		else
			exception = [OFInvalidArgumentException exception];

		if ([delegate respondsToSelector: @selector(resolver:
		    didResolveDomainName:socketAddresses:exception:)]) {
			OFTimer *timer = [OFTimer
			    timerWithTimeInterval: 0
					   target: delegate
					 selector: @selector(resolver:
						       didResolveDomainName:
						       socketAddresses:
						       exception:)
					   object: self
					   object: host
					   object: addresses
					   object: exception
					  repeats: false];
			[[OFRunLoop currentRunLoop] addTimer: timer
						     forMode: runLoopMode];
		}

		return;
	} @catch (OFInvalidFormatException *e) {
	}

	if ((aliases = [_staticHosts objectForKey: host]) != nil) {
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

			if (addressFamily != OF_SOCKET_ADDRESS_FAMILY_ANY &&
			    address.family != addressFamily)
				continue;

			[addresses addItem: &address];
		}

		[addresses makeImmutable];

		if (addresses.count == 0) {
			of_dns_resource_record_type_t recordType = 0;

			addresses = nil;

			switch (addressFamily) {
			case OF_SOCKET_ADDRESS_FAMILY_ANY:
				recordType = OF_DNS_RESOURCE_RECORD_TYPE_ALL;
				break;
			case OF_SOCKET_ADDRESS_FAMILY_IPV4:
				recordType = OF_DNS_RESOURCE_RECORD_TYPE_A;
				break;
			case OF_SOCKET_ADDRESS_FAMILY_IPV6:
				recordType = OF_DNS_RESOURCE_RECORD_TYPE_AAAA;
				break;
			default:
				exception =
				    [OFInvalidArgumentException exception];
				break;
			}

			if (exception == nil) {
				of_dns_resource_record_class_t recordClass =
				    OF_DNS_RESOURCE_RECORD_CLASS_IN;
				of_dns_resolver_error_t error =
				    OF_DNS_RESOLVER_ERROR_NO_RESULT;

				exception = [OFResolveHostFailedException
				    exceptionWithHost: host
					  recordClass: recordClass
					   recordType: recordType
						error: error];
			}
		}

		if ([delegate respondsToSelector: @selector(resolver:
		    didResolveDomainName:socketAddresses:exception:)]) {
			OFTimer *timer = [OFTimer
			    timerWithTimeInterval: 0
					   target: delegate
					 selector: @selector(resolver:
						       didResolveDomainName:
						       socketAddresses:
						       exception:)
					   object: self
					   object: host
					   object: addresses
					   object: exception
					  repeats: false];
			[[OFRunLoop currentRunLoop] addTimer: timer
						     forMode: runLoopMode];
		}

		return;
	}

	pool = objc_autoreleasePoolPush();

	context = [[[OFDNSResolverAsyncResolveSocketAddressesContext alloc]
	    initWithHost: host
		delegate: delegate] autorelease];

	switch (addressFamily) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
#ifdef OF_HAVE_IPV6
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
#endif
		context->_expectedResponses = 1;
		break;
	case OF_SOCKET_ADDRESS_FAMILY_ANY:
#ifdef OF_HAVE_IPV6
		context->_expectedResponses = 2;
#else
		context->_expectedResponses = 1;
#endif
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

#ifdef OF_HAVE_IPV6
	if (addressFamily == OF_SOCKET_ADDRESS_FAMILY_IPV6 ||
	    addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY) {
		OFNumber *recordTypeNumber =
		    [OFNumber numberWithInt: OF_DNS_RESOURCE_RECORD_TYPE_AAAA];

		[self of_asyncResolveHost: host
			      recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
			       recordType: OF_DNS_RESOURCE_RECORD_TYPE_AAAA
			      runLoopMode: runLoopMode
				   target: context
				 selector: @selector(resolver:
					       didResolveDomainName:
					       answerRecords:authorityRecords:
					       additionalRecords:context:
					       exception:)
				  context: recordTypeNumber];
	}
#endif

	if (addressFamily == OF_SOCKET_ADDRESS_FAMILY_IPV4 ||
	    addressFamily == OF_SOCKET_ADDRESS_FAMILY_ANY)
		[self of_asyncResolveHost: host
			      recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
			       recordType: OF_DNS_RESOURCE_RECORD_TYPE_A
			      runLoopMode: runLoopMode
				   target: context
				 selector: @selector(resolver:
					       didResolveDomainName:
					       answerRecords:authorityRecords:
					       additionalRecords:context:
					       exception:)
				  context: [OFNumber numberWithInt:
					       OF_DNS_RESOURCE_RECORD_TYPE_A]];

	objc_autoreleasePoolPop(pool);
}

- (OFData *)resolveSocketAddressesForHost: (OFString *)host
			    addressFamily: (of_socket_address_family_t)
					       addressFamily
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFDNSResolverResolveSocketAddressesDelegate *delegate;
	OFData *ret;

	delegate = [[[OFDNSResolverResolveSocketAddressesDelegate
	    alloc] init] autorelease];

	[self asyncResolveSocketAddressesForHost: host
				   addressFamily: addressFamily
				     runLoopMode: resolveRunLoopMode
					delegate: delegate];

	while (!delegate->_done)
		[runLoop runMode: resolveRunLoopMode
		      beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: resolveRunLoopMode
	      beforeDate: [OFDate date]];

	if (delegate->_exception != nil)
		@throw delegate->_exception;

	ret = [delegate->_socketAddresses retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)close
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator OF_GENERIC(OFDNSResolverQuery *) *enumerator;
	OFDNSResolverQuery *query;

	[_IPv4Socket cancelAsyncRequests];
	[_IPv4Socket release];
	_IPv4Socket = nil;

#ifdef OF_HAVE_IPV6
	[_IPv6Socket cancelAsyncRequests];
	[_IPv6Socket release];
	_IPv6Socket = nil;
#endif

	enumerator = [_queries objectEnumerator];
	while ((query = [enumerator nextObject]) != nil) {
		OFResolveHostFailedException *exception;

		exception = [OFResolveHostFailedException
		    exceptionWithHost: query->_host
			  recordClass: query->_recordClass
			   recordType: query->_recordType
				error: OF_DNS_RESOLVER_ERROR_CANCELED];

		callback(query->_target, query->_selector, self,
		    query->_domainName, nil, nil, nil, query->_context,
		    exception);
	}

	[_queries removeAllObjects];

	objc_autoreleasePoolPop(pool);
}
@end
