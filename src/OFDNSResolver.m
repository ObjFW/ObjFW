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
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFLocalization.h"
#import "OFString.h"
#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFOpenItemFailedException.h"

#ifdef OF_WINDOWS
# define interface struct
# include <iphlpapi.h>
# undef interface
#endif

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
				  encoding: [OFLocalization encoding]];
}

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
#ifdef OF_WINDOWS
		void *pool;
		OFString *path;
#endif

		_minNumberOfDotsInAbsoluteName = 1;

#ifdef OF_HAVE_FILES
# if defined(OF_WINDOWS)
		pool = objc_autoreleasePoolPush();

		path = [[OFWindowsRegistryKey localMachineKey]
		    stringForValue: @"DataBasePath"
			subKeyPath: @"SYSTEM\\CurrentControlSet\\Services\\"
				    @"Tcpip\\Parameters"];
		path = [path stringByAppendingPathComponent: @"hosts"];

		if (path != nil)
			[self of_parseHosts: path];

		objc_autoreleasePoolPop(pool);
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
# ifndef OF_WINDOWS
		[self of_parseResolvConf: @"/etc/resolv.conf"];
		[self of_parseResolvConf: @"/etc/resolv.conf.tail"];
# endif
#endif
#ifdef OF_WINDOWS
		[self of_parseNetworkParams];
#endif

		if (_staticHosts == nil)
			_staticHosts = [[OFDictionary alloc] init];

		if (_nameServers == nil)
			_nameServers = [[OFArray alloc] initWithObjects:
			    @"127.0.0.1", @"::1", nil];

		if (_localDomain == nil)
			_localDomain = [domainFromHostname() copy];

		if (_searchDomains == nil) {
			if (_localDomain != nil)
				_searchDomains = [[OFArray alloc]
				    initWithObject: _localDomain];
			else
				_searchDomains = [[OFArray alloc] init];
		}
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
	of_string_encoding_t encoding = [OFLocalization encoding];
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
@end
