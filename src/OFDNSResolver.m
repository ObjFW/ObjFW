/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <string.h>
#include "unistd_wrapper.h"

#import "OFDNSResolver.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFUDPSocket.h"
#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

#ifdef OF_WINDOWS
# define interface struct
# include <iphlpapi.h>
# undef interface
#endif

/*
 * RFC 1035 doesn't specify if pointers to pointers are allowed, and if so how
 * many. Since it's unspecified, we have to assume that it might happen, but we
 * also want to limit it to avoid DoS. Limiting it to 16 levels of pointers and
 * immediately rejecting pointers to itself seems like a fair balance.
 */
#define MAX_ALLOWED_POINTERS 16

/*
 * TODO:
 *
 *  - Timeouts
 *  - Resolve with each search domain
 *  - Iterate through name servers
 *  - IPv6 for talking to the name servers
 *  - Fallback to TCP
 *  - More record types
 */

@interface OFDNSResolver_context: OFObject
{
	OFString *_host;
	OFArray OF_GENERIC(OFString *) *_nameServers, *_searchDomains;
	size_t _nameServersIndex, _searchDomainsIndex;
	OFMutableData *_queryData;
	id _target;
	SEL _selector;
	id _userContext;
}

@property (readonly, nonatomic) OFString *host;
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *nameServers;
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *searchDomains;
@property (nonatomic) size_t nameServersIndex;
@property (nonatomic) size_t searchDomainsIndex;
@property (readonly, nonatomic) OFMutableData *queryData;
@property (readonly, nonatomic) id target;
@property (readonly, nonatomic) SEL selector;
@property (readonly, nonatomic) id userContext;

- (instancetype)initWithHost: (OFString *)host
		 nameServers: (OFArray OF_GENERIC(OFString *) *)nameServers
	       searchDomains: (OFArray OF_GENERIC(OFString *) *)searchDomains
		   queryData: (OFMutableData *)queryData
		      target: (id)target
		    selector: (SEL)selector
		 userContext: (id)userContext;
@end

@interface OFDNSResolver ()
#ifdef OF_HAVE_FILES
- (void)of_parseHosts: (OFString *)path;
# ifndef OF_WINDOWS
- (void)of_parseResolvConf: (OFString *)path;
- (void)of_parseResolvConfOption: (OFString *)option;
# endif
#endif
#ifdef OF_WINDOWS
- (void)of_parseNetworkParams;
#endif
@end

static OFString *
domainFromHostname(void)
{
	char hostname[256];
	char *domain;

	if (gethostname(hostname, 256) != 0)
		return nil;

	if ((domain = strchr(hostname, '.')) == NULL)
		return nil;

	return [OFString stringWithCString: domain + 1
				  encoding: [OFLocale encoding]];
}

static OFString *
parseString(const unsigned char *buffer, size_t length, size_t *idx)
{
	size_t i = *idx;
	uint8_t stringLength;
	OFString *string;

	if (i >= length)
		@throw [OFTruncatedDataException exception];

	stringLength = buffer[i++];

	if (i + stringLength > length)
		@throw [OFTruncatedDataException exception];

	string = [OFString stringWithUTF8String: (char *)&buffer[i]
					 length: stringLength];
	i += stringLength;

	*idx = i;

	return string;
}

static OFString *
parseName(const unsigned char *buffer, size_t length, size_t *idx,
    uint_fast8_t pointerLevel)
{
	size_t i = *idx;
	OFMutableArray *components = [OFMutableArray array];
	uint8_t componentLength;

	do {
		OFString *component;

		if (i >= length)
			@throw [OFTruncatedDataException exception];

		componentLength = buffer[i++];

		if (componentLength & 0xC0) {
			size_t j;
			OFString *suffix;

			if (pointerLevel == 0)
				@throw [OFInvalidServerReplyException
				    exception];

			if (i >= length)
				@throw [OFTruncatedDataException exception];

			j = ((componentLength & 0x3F) << 8) | buffer[i++];
			*idx = i;

			if (j == i - 2)
				/* Pointing to itself?! */
				@throw [OFInvalidServerReplyException
				    exception];

			suffix = parseName(buffer, length, &j,
			    pointerLevel - 1);

			if ([components count] == 0)
				return suffix;
			else {
				[components addObject: suffix];
				return [components
				    componentsJoinedByString: @"."];
			}
		}

		if (i + componentLength > length)
			@throw [OFTruncatedDataException exception];

		component = [OFString stringWithUTF8String: (char *)&buffer[i]
						    length: componentLength];
		i += componentLength;

		[components addObject: component];
	} while (componentLength > 0);

	*idx = i;

	return [components componentsJoinedByString: @"."];
}

static OFString *
parseAAAAData(const unsigned char *buffer)
{
	OFMutableString *data = [OFMutableString string];
	int_fast8_t zerosStart = -1, maxZerosStart = -1;
	uint_fast8_t zerosCount = 0, maxZerosCount = 0;
	bool first = true;

	for (uint_fast8_t i = 0; i < 16; i += 2) {
		if (buffer[i] == 0 && buffer[i + 1] == 0) {
			if (zerosStart >= 0)
				zerosCount++;
			else {
				zerosStart = i;
				zerosCount = 1;
			}
		} else {
			if (zerosCount > maxZerosCount) {
				maxZerosStart = zerosStart;
				maxZerosCount = zerosCount;
			}

			zerosStart = -1;
		}
	}
	if (zerosCount > maxZerosCount) {
		maxZerosStart = zerosStart;
		maxZerosCount = zerosCount;
	}

	if (maxZerosCount >= 2) {
		for (uint_fast8_t i = 0; i < maxZerosStart; i += 2) {
			[data appendFormat: (first ? @"%x" : @":%x"),
					    (buffer[i] << 8) | buffer[i + 1]];
			first = false;
		}

		[data appendString: @"::"];
		first = true;

		for (uint_fast8_t i = maxZerosStart + (maxZerosCount * 2);
		    i < 16; i += 2) {
			[data appendFormat: (first ? @"%x" : @":%x"),
					    (buffer[i] << 8) | buffer[i + 1]];
			first = false;
		}
	} else {
		for (uint_fast8_t i = 0; i < 16; i += 2) {
			[data appendFormat: (first ? @"%x" : @":%x"),
					    (buffer[i] << 8) | buffer[i + 1]];
			first = false;
		}
	}

	[data makeImmutable];

	return data;
}

static OF_KINDOF(OFDNSResourceRecord *)
createResourceRecord(OFString *name, of_dns_resource_record_class_t recordClass,
    of_dns_resource_record_type_t recordType, uint32_t TTL,
    const unsigned char *buffer, size_t length, size_t i, uint16_t dataLength)
{
	if (recordType == OF_DNS_RESOURCE_RECORD_TYPE_A &&
	    recordClass == OF_DNS_RESOURCE_RECORD_CLASS_IN) {
		OFString *address;

		if (dataLength != 4)
			@throw [OFInvalidServerReplyException exception];

		address = [OFString stringWithFormat: @"%u.%u.%u.%u",
		    buffer[i], buffer[i + 1], buffer[i + 2], buffer[i + 3]];

		return [[[OFADNSResourceRecord alloc]
		    initWithName: name
			 address: address
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
		OFString *address;

		if (dataLength != 16)
			@throw [OFInvalidServerReplyException
			    exception];

		address = parseAAAAData(&buffer[i]);

		return [[[OFAAAADNSResourceRecord alloc]
		    initWithName: name
			 address: address
			     TTL: TTL] autorelease];
	} else
		return [[[OFDNSResourceRecord alloc]
		    initWithName: name
		     recordClass: recordClass
		      recordType: recordType
			     TTL: TTL] autorelease];
}

@implementation OFDNSResolver_context
@synthesize host = _host, nameServers = _nameServers;
@synthesize searchDomains = _searchDomains;
@synthesize nameServersIndex = _nameServersIndex;
@synthesize searchDomainsIndex = _searchDomainsIndex, queryData = _queryData;
@synthesize target = _target, selector = _selector, userContext = _userContext;

- (instancetype)initWithHost: (OFString *)host
		 nameServers: (OFArray OF_GENERIC(OFString *) *)nameServers
	       searchDomains: (OFArray OF_GENERIC(OFString *) *)searchDomains
		   queryData: (OFMutableData *)queryData
		      target: (id)target
		    selector: (SEL)selector
		 userContext: (id)userContext
{
	self = [super init];

	@try {
		_host = [host copy];
		_nameServers = [nameServers copy];
		_searchDomains = [searchDomains copy];
		_queryData = [queryData retain];
		_target = [target retain];
		_selector = selector;
		_userContext = [userContext retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];
	[_nameServers release];
	[_searchDomains release];
	[_queryData release];
	[_target release];
	[_userContext release];

	[super dealloc];
}
@end

@implementation OFDNSResolver
@synthesize staticHosts = _staticHosts, nameServers = _nameServers;
@synthesize localDomain = _localDomain, searchDomains = _searchDomains;
@synthesize minNumberOfDotsInAbsoluteName = _minNumberOfDotsInAbsoluteName;
@synthesize usesTCP = _usesTCP;

+ (instancetype)resolver
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
#ifdef OF_WINDOWS
		OFString *path;
#endif

		_minNumberOfDotsInAbsoluteName = 1;

#ifdef OF_HAVE_FILES
# if defined(OF_WINDOWS)
		path = [[OFWindowsRegistryKey localMachineKey]
		    stringForValue: @"DataBasePath"
			subKeyPath: @"SYSTEM\\CurrentControlSet\\Services\\"
				    @"Tcpip\\Parameters"];
		path = [path stringByAppendingPathComponent: @"hosts"];

		if (path != nil)
			[self of_parseHosts: path];
# elif defined(OF_HAIKU)
		[self of_parseHosts: @"/boot/common/settings/network/hosts"];
# elif defined(OF_MORPHOS)
		[self of_parseHosts: @"ENVARC:sys/net/hosts"];
# elif defined(OF_AMIGAOS4)
		[self of_parseHosts: @"DEVS:Internet/hosts"];
# elif defined(OF_AMIGAOS)
		[self of_parseHosts: @"AmiTCP:db/hosts"];
# else
		[self of_parseHosts: @"/etc/hosts"];
# endif

# if defined(OF_MORPHOS)
		[self of_parseResolvConf: @"ENV:sys/net/resolv.conf"];
# elif !defined(OF_WINDOWS)
		[self of_parseResolvConf: @"/etc/resolv.conf"];
		[self of_parseResolvConf: @"/etc/resolv.conf.tail"];
# endif
#endif
#ifdef OF_WINDOWS
		[self of_parseNetworkParams];
#endif

		if (_staticHosts == nil) {
			OFArray *localhost =

#ifdef HAVE_IPV6
			localhost = [OFArray arrayWithObjects:
			    @"::1", @"127.0.0.1", nil];
#else
			localhost = [OFArray arrayWithObject: @"127.0.0.1"];
#endif

			_staticHosts = [[OFDictionary alloc]
			    initWithObject: localhost
				    forKey: @"localhost"];
		}

		if (_nameServers == nil)
#ifdef HAVE_IPV6
			_nameServers = [[OFArray alloc]
			    initWithObjects: @"127.0.0.1", @"::1", nil];
#else
			_nameServers = [[OFArray alloc]
			    initWithObject: @"127.0.0.1"];
#endif

		if (_localDomain == nil)
			_localDomain = [domainFromHostname() copy];

		if (_searchDomains == nil) {
			if (_localDomain != nil)
				_searchDomains = [[OFArray alloc]
				    initWithObject: _localDomain];
			else
				_searchDomains = [[OFArray alloc] init];
		}

		_queries = [[OFMutableDictionary alloc] init];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_staticHosts release];
	[_nameServers release];
	[_localDomain release];
	[_searchDomains release];
	[_queries release];

	[super dealloc];
}

#ifdef OF_HAVE_FILES
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

		if ([components count] < 2) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		address = [components firstObject];
		hosts = [components objectsInRange:
		    of_range(1, [components count] - 1)];

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

# ifndef OF_WINDOWS
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

		if ([components count] < 2) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		option = [components firstObject];
		arguments = [components objectsInRange:
		    of_range(1, [components count] - 1)];

		if ([option isEqual: @"nameserver"]) {
			if ([arguments count] != 1) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}

			[nameServers addObject: [arguments firstObject]];
		} else if ([option isEqual: @"domain"]) {
			if ([arguments count] != 1) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}

			[_localDomain release];
			_localDomain = [[arguments firstObject] copy];
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
	if ([option hasPrefix: @"ndots:"]) {
		option = [option substringWithRange:
		    of_range(6, [option length] - 6)];

		@try {
			_minNumberOfDotsInAbsoluteName =
			    (size_t)[option decimalValue];
		} @catch (id e) {
			return;
		}
	} else if ([option isEqual: @"tcp"])
		_usesTCP = true;
}
# endif
#endif

#ifdef OF_WINDOWS
- (void)of_parseNetworkParams
{
	void *pool = objc_autoreleasePoolPush();
	of_string_encoding_t encoding = [OFLocale encoding];
	OFMutableArray *nameServers;
	OFString *localDomain;
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
	localDomain = [OFString stringWithCString: fixedInfo->DomainName
					 encoding: encoding];

	for (iter = &fixedInfo->DnsServerList; iter != NULL; iter = iter->Next)
		[nameServers addObject:
		    [OFString stringWithCString: iter->IpAddress.String
				       encoding: encoding]];

	if ([nameServers count] > 0) {
		[nameServers makeImmutable];
		_nameServers = [nameServers copy];
	}

	if ([localDomain length] > 0)
		_localDomain = [localDomain copy];

	objc_autoreleasePoolPop(pool);
}
#endif

-      (bool)of_socket: (OFUDPSocket *)sock
  didReceiveIntoBuffer: (unsigned char *)buffer
		length: (size_t)length
		sender: (of_socket_address_t)sender
	       context: (id)context
	     exception: (id)exception
{
	OFMutableArray *answers = nil;
	OFNumber *ID;
	OFDNSResolver_context *DNSResolverContext;
	id target;
	SEL selector;
	void (*callback)(id, SEL, OFArray *, id, id);
	OFData *queryData;

	if (exception != nil)
		return false;

	if (length < 2)
		/* We can't get the ID to get the context. Give up. */
		return false;

	ID = [OFNumber numberWithUInt16: (buffer[0] << 8) | buffer[1]];
	DNSResolverContext = [[[_queries objectForKey: ID] retain] autorelease];

	if (DNSResolverContext == nil)
		return false;

	[_queries removeObjectForKey: ID];

	target = [DNSResolverContext target];
	selector = [DNSResolverContext selector];
	callback = (void (*)(id, SEL, OFArray *, id, id))
	    [target methodForSelector: selector];
	queryData = [DNSResolverContext queryData];

	@try {
		const unsigned char *queryBuffer;
		size_t i;
		uint16_t numQuestions, numAnswers;

		if (length < 12)
			@throw [OFTruncatedDataException exception];

		if ([queryData itemSize] != 1 || [queryData count] < 12)
			@throw [OFInvalidArgumentException exception];

		queryBuffer = [queryData items];

		/* QR */
		if ((buffer[2] & 0x80) == 0)
			@throw [OFInvalidServerReplyException exception];

		/* Opcode */
		if ((buffer[2] & 0x78) != (queryBuffer[2] & 0x78))
			@throw [OFInvalidServerReplyException exception];

		/* TC */
		if (buffer[2] & 0x02)
			@throw [OFTruncatedDataException exception];

		/* RA */
		if ((buffer[3] & 0x80) == 0)
			/* Server doesn't handle recursive queries */
			/* TODO: Better exception */
			@throw [OFInvalidServerReplyException exception];

		/* RCODE */
		switch (buffer[3] & 0x0F) {
		case 0:
			break;
		default:
			/* TODO: Better exception */
			@throw [OFInvalidServerReplyException exception];
		}

		numQuestions = (buffer[4] << 8) | buffer[5];

		numAnswers = (buffer[6] << 8) | buffer[7];
		answers = [OFMutableArray arrayWithCapacity: numAnswers];

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

		for (uint_fast16_t j = 0; j < numAnswers; j++) {
			OFString *name = parseName(buffer, length, &i,
			    MAX_ALLOWED_POINTERS);
			of_dns_resource_record_class_t recordClass;
			of_dns_resource_record_type_t recordType;
			uint32_t TTL;
			uint16_t dataLength;
			OFDNSResourceRecord *record;

			if (i + 10 > length)
				@throw [OFTruncatedDataException exception];

			recordType = (buffer[i] << 16) | buffer[i + 1];
			recordClass = (buffer[i + 2] << 16) | buffer[i + 3];
			TTL = (buffer[i + 4] << 24) | (buffer[i + 5] << 16) |
			    (buffer[i + 6] << 8) | buffer[i + 7];
			dataLength = (buffer[i + 8] << 16) | buffer[i + 9];

			i += 10;

			if (i + dataLength > length)
				@throw [OFTruncatedDataException exception];

			record = createResourceRecord(name, recordClass,
			    recordType, TTL, buffer, length, i, dataLength);
			i += dataLength;

			[answers addObject: record];
		}
	} @catch (id e) {
		callback(target, selector, nil,
		    [DNSResolverContext userContext], e);
		return false;
	}

	callback(target, selector, answers, [DNSResolverContext userContext],
	    nil);

	return false;
}

- (size_t)of_socket: (OFUDPSocket *)sock
      didSendBuffer: (void **)buffer
	  bytesSent: (size_t)bytesSent
	   receiver: (of_socket_address_t *)receiver
	    context: (id)context
	  exception: (id)exception
{
	if (exception != nil)
		return 0;

	[sock asyncReceiveIntoBuffer: [self allocMemoryWithSize: 512]
			      length: 512
			      target: self
			    selector: @selector(of_socket:didReceiveIntoBuffer:
					  length:sender:context:exception:)
			     context: nil];

	return 0;
}

- (void)asyncResolveHost: (OFString *)host
		  target: (id)target
		selector: (SEL)selector
		 context: (id)context
{
	[self asyncResolveHost: host
		   recordClass: OF_DNS_RESOURCE_RECORD_CLASS_IN
		    recordType: OF_DNS_RESOURCE_RECORD_TYPE_ALL
			target: target
		      selector: selector
		       context: context];
}

- (void)asyncResolveHost: (OFString *)host
	     recordClass: (of_dns_resource_record_class_t)recordClass
	      recordType: (of_dns_resource_record_type_t)recordType
		  target: (id)target
		selector: (SEL)selector
		 context: (id)context
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = [OFMutableData dataWithCapacity: 512];
	OFDNSResolver_context *DNSResolverContext;
	OFNumber *ID;
	uint16_t tmp;
	OFUDPSocket *sock;
	of_socket_address_t address;

	/* TODO: Properly try all search domains */
	if (![host hasSuffix: @"."])
		host = [host stringByAppendingString: @"."];

	if ([host UTF8StringLength] > 253)
		@throw [OFOutOfRangeException exception];

	/* Header */

	/* Random, unused ID */
	do {
		ID = [OFNumber numberWithUInt16: (uint16_t)of_random()];
	} while ([_queries objectForKey: ID] != nil);

	tmp = OF_BSWAP16_IF_LE([ID uInt16Value]);
	[data addItems: &tmp
		 count: 2];

	/* RD */
	tmp = OF_BSWAP16_IF_LE(1 << 8);
	[data addItems: &tmp
		 count: 2];

	/* QDCOUNT */
	tmp = OF_BSWAP16_IF_LE(1);
	[data addItems: &tmp
		 count: 2];

	/* ANCOUNT, NSCOUNT and ARCOUNT */
	[data increaseCountBy: 6];

	/* Question */

	/* QNAME */
	for (OFString *component in [host componentsSeparatedByString: @"."]) {
		size_t length = [component UTF8StringLength];
		uint8_t length8;

		if (length > 63 || [data count] + length > 512)
			@throw [OFOutOfRangeException exception];

		length8 = (uint8_t)length;
		[data addItem: &length8];
		[data addItems: [component UTF8String]
			 count: length];
	}

	/* QTYPE */
	tmp = OF_BSWAP16_IF_LE(recordType);
	[data addItems: &tmp
		 count: 2];

	/* QCLASS */
	tmp = OF_BSWAP16_IF_LE(recordClass);
	[data addItems: &tmp
		 count: 2];

	DNSResolverContext = [[[OFDNSResolver_context alloc]
	    initWithHost: host
	     nameServers: _nameServers
	   searchDomains: _searchDomains
	       queryData: data
		  target: target
		selector: selector
	     userContext: context] autorelease];
	[_queries setObject: DNSResolverContext
		     forKey: ID];

	sock = [OFUDPSocket socket];
	[sock bindToHost: @"0.0.0.0"
		    port: 0];

	address = of_socket_address_parse_ip(
	    [[DNSResolverContext nameServers] firstObject], 53);

	[sock asyncSendBuffer: [data items]
		       length: [data count]
		     receiver: address
		       target: self
		     selector: @selector(of_socket:didSendBuffer:bytesSent:
				   receiver:context:exception:)
		      context: nil];

	objc_autoreleasePoolPop(pool);
}
@end
