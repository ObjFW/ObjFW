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

#include "unistd_wrapper.h"

#import "OFDNSResolverSettings.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFLocale.h"
#import "OFString.h"
#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#ifdef OF_WINDOWS
# define interface struct
# include <iphlpapi.h>
# undef interface
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
#endif

#import "socket_helpers.h"

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

@implementation OFDNSResolverSettings
- (void)dealloc
{
	[_staticHosts release];
	[_nameServers release];
	[_localDomain release];
	[_searchDomains release];
	[_lastConfigReload release];

	[super dealloc];
}

- (id)copy
{
	OFDNSResolverSettings *copy = [[OFDNSResolverSettings alloc] init];

	@try {
		copy->_staticHosts = [_staticHosts copy];
		copy->_nameServers = [_nameServers copy];
		copy->_localDomain = [_localDomain copy];
		copy->_searchDomains = [_searchDomains copy];
		copy->_timeout = _timeout;
		copy->_maxAttempts = _maxAttempts;
		copy->_minNumberOfDotsInAbsoluteName =
		    _minNumberOfDotsInAbsoluteName;
		copy->_usesTCP = _usesTCP;
		copy->_configReloadInterval = _configReloadInterval;
		copy->_lastConfigReload = [_lastConfigReload copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (void)setDefaults
{
	[_staticHosts release];
	_staticHosts = nil;

	[_nameServers release];
	_nameServers = nil;

	[_localDomain release];
	_localDomain = nil;

	[_searchDomains release];
	_searchDomains = nil;

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

#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_3DS)
- (void)parseHosts: (OFString *)path
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
- (void)parseResolvConfOption: (OFString *)option
{
	@try {
		if ([option hasPrefix: @"ndots:"]) {
			unsigned long long number;

			option = [option substringWithRange:
			    of_range(6, option.length - 6)];
			number = option.unsignedLongLongValue;

			if (number > UINT_MAX)
				@throw [OFOutOfRangeException exception];

			_minNumberOfDotsInAbsoluteName = (unsigned int)number;
		} else if ([option hasPrefix: @"timeout:"]) {
			option = [option substringWithRange:
			    of_range(8, option.length - 8)];

			_timeout = option.unsignedLongLongValue;
		} else if ([option hasPrefix: @"attempts:"]) {
			unsigned long long number;

			option = [option substringWithRange:
			    of_range(9, option.length - 9)];
			number = option.unsignedLongLongValue;

			if (number > UINT_MAX)
				@throw [OFOutOfRangeException exception];

			_maxAttempts = (unsigned int)number;
		} else if ([option hasPrefix: @"reload-period:"]) {
			option = [option substringWithRange:
			    of_range(14, option.length - 14)];

			_configReloadInterval = option.unsignedLongLongValue;
		} else if ([option isEqual: @"tcp"])
			_usesTCP = true;
	} @catch (OFInvalidFormatException *e) {
	}
}

- (void)parseResolvConf: (OFString *)path
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
				[self parseResolvConfOption: argument];

		objc_autoreleasePoolPop(pool2);
	}

	[nameServers makeImmutable];

	[_nameServers release];
	_nameServers = [nameServers copy];

	objc_autoreleasePoolPop(pool);
}
# endif
#endif

#ifdef OF_WINDOWS
- (void)obtainWindowsSystemConfig
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
- (void)obtainAmigaOS4SystemConfig
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
- (void)obtainNintendo3DSSytemConfig
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

- (void)reload
{
	void *pool;
#ifdef OF_WINDOWS
	OFString *path;
#endif

	/*
	 * TODO: Rather than reparsing every time, check what actually changed
	 *	 (mtime) and only reset those.
	 */

	if (_lastConfigReload != nil && _configReloadInterval > 0 &&
	    _lastConfigReload.timeIntervalSinceNow < _configReloadInterval)
		return;

	pool = objc_autoreleasePoolPush();

	[self setDefaults];

#if defined(OF_WINDOWS)
# ifdef OF_HAVE_FILES
	OFWindowsRegistryKey *key = [[OFWindowsRegistryKey localMachineKey]
		   openSubkeyAtPath: @"SYSTEM\\CurrentControlSet\\Services\\"
				     @"Tcpip\\Parameters"
	    securityAndAccessRights: KEY_QUERY_VALUE];
	path = [[[key stringForValue: @"DataBasePath"]
	    stringByAppendingPathComponent: @"hosts"]
	    stringByExpandingWindowsEnvironmentStrings];

	if (path != nil)
		[self parseHosts: path];
# endif

	[self obtainWindowsSystemConfig];
#elif defined(OF_AMIGAOS4)
	[self parseHosts: HOSTS_PATH];
	[self obtainAmigaOS4SystemConfig];
#elif defined(OF_NINTENDO_3DS)
	[self obtainNintendo3DSSytemConfig];
#elif defined(OF_HAVE_FILES)
	[self parseHosts: HOSTS_PATH];
	[self parseResolvConf: RESOLV_CONF_PATH];
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

	objc_autoreleasePoolPop(pool);
}
@end
