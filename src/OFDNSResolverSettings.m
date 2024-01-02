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

#include "config.h"

#include "unistd_wrapper.h"

#import "OFDNSResolverSettings.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFDate.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFLocale.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#ifdef OF_WINDOWS
# import "OFOpenWindowsRegistryKeyFailedException.h"
#endif
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFUndefinedKeyException.h"

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

#if defined(OF_AMIGAOS_M68K) || defined(OF_AMIGAOS4)
# define Class IntuitionClass
# include <proto/dos.h>
# undef Class
#endif
#ifdef OF_MORPHOS
# include <proto/rexxsyslib.h>
# include <rexx/errors.h>
# include <rexx/storage.h>
#endif

#if defined(OF_HAIKU)
# define HOSTS_PATH @"/system/settings/network/hosts"
# define RESOLV_CONF_PATH @"/system/settings/network/resolv.conf"
#else
# define HOSTS_PATH @"/etc/hosts"
# define RESOLV_CONF_PATH @"/etc/resolv.conf"
#endif

#ifndef HOST_NAME_MAX
# define HOST_NAME_MAX 255
#endif

#ifndef OF_WII
static OFString *
domainFromHostname(OFString *hostname)
{
	OFString *ret;

	if (hostname == nil)
		return nil;

	@try {
		OFSocketAddressParseIP(hostname, 0);

		/*
		 * If we are still here, the host name is a valid IP address.
		 * We can't use that as local domain.
		 */
		ret = nil;
	} @catch (OFInvalidFormatException *e) {
		/* Not an IP address -> we can use it if it contains a dot. */
		size_t pos = [hostname rangeOfString: @"."].location;

		if (pos != OFNotFound)
			ret = [hostname substringFromIndex: pos + 1];
		else
			ret = nil;
	}

	return ret;
}
#endif

#if !defined(OF_WII) && !defined(OF_MORPHOS)
static OFString *
obtainHostname(void)
{
	char hostname[HOST_NAME_MAX + 1];

	if (gethostname(hostname, HOST_NAME_MAX + 1) != 0)
		return nil;

	return [OFString stringWithCString: hostname
				  encoding: [OFLocale encoding]];
}
#endif

#ifdef OF_AMIGAOS_M68K
static bool
assignExists(const char *assign)
{
	struct DosList *list = LockDosList(LDF_ASSIGNS | LDF_READ);
	bool found = (FindDosEntry(list, assign, LDF_ASSIGNS) != NULL);
	UnLockDosList(LDF_ASSIGNS | LDF_READ);
	return found;
}
#endif

#ifdef OF_MORPHOS
static OFString *
arexxCommand(const char *port, const char *command)
{
	struct Library *RexxSysBase;
	struct MsgPort *replyPort = NULL;
	struct RexxMsg *msg = NULL;

	if ((RexxSysBase = OpenLibrary("rexxsyslib.library", 36)) == NULL)
		return nil;

	@try {
		struct MsgPort *rexxPort;

		if ((replyPort = CreateMsgPort()) == NULL)
			return nil;

		if ((msg = CreateRexxMsg(replyPort, NULL, port)) == NULL)
			return nil;

		msg->rm_Action = RXCOMM | RXFF_RESULT;

		if ((msg->rm_Args[0] = (char *)CreateArgstring(
		    command, strlen(command))) == NULL)
			return nil;

		Forbid();

		if ((rexxPort = FindPort(port)) == NULL) {
			Permit();
			return nil;
		}

		PutMsg(rexxPort, &msg->rm_Node);
		Permit();
		WaitPort(replyPort);
		GetMsg(replyPort);

		if (msg->rm_Result1 != RC_OK || msg->rm_Result2 == 0)
			return nil;

		return [OFString stringWithCString: (char *)msg->rm_Result2
					  encoding: [OFLocale encoding]];
	} @finally {
		if (msg != NULL) {
			if (msg->rm_Args[0] != NULL)
				DeleteArgstring(msg->rm_Args[0]);
			if (msg->rm_Result2 != 0)
				DeleteArgstring((char *)msg->rm_Result2);

			DeleteRexxMsg(msg);
		}

		if (replyPort != NULL)
			DeleteMsgPort(replyPort);

		CloseLibrary(RexxSysBase);
	}
}

static OFArray OF_GENERIC(OFString *) *
parseNetStackArray(OFString *string)
{
	if (![string hasPrefix: @"["] || ![string hasSuffix: @"]"])
		return nil;

	string = [string substringWithRange: OFMakeRange(1, string.length - 2)];

	return [string componentsSeparatedByString: @"|"];
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
		copy->_forcesTCP = _forcesTCP;
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
	_forcesTCP = false;
#ifndef OF_NINTENDO_3DS
	_configReloadInterval = 2;
#else
	_configReloadInterval = 0;
#endif
}

#if defined(OF_HAVE_FILES) && !defined(OF_MORPHOS) && !defined(OF_NINTENDO_3DS)
- (void)parseHosts: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *whitespaceCharacterSet =
	    [OFCharacterSet whitespaceCharacterSet];
	OFCharacterSet *commentCharacters =
	    [OFCharacterSet characterSetWithCharactersInString: @"#;"];
	OFMutableDictionary *staticHosts;
	OFFile *file;
	OFString *line;

	@try {
		file = [OFFile fileWithPath: path mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	staticHosts = [OFMutableDictionary dictionary];

	while ((line =
	    [file readLineWithEncoding: [OFLocale encoding]]) != nil) {
		OFArray *components, *hosts;
		size_t pos;
		OFString *address;

		pos = [line indexOfCharacterFromSet: commentCharacters];
		if (pos != OFNotFound)
			line = [line substringToIndex: pos];

		components = [line
		    componentsSeparatedByCharactersInSet: whitespaceCharacterSet
		    options: OFStringSkipEmptyComponents];

		if (components.count < 2)
			continue;

		address = components.firstObject;
		hosts = [components objectsInRange:
		    OFMakeRange(1, components.count - 1)];

		for (OFString *host in hosts) {
			OFMutableArray *addresses;

			host = host.lowercaseString;
			addresses = [staticHosts objectForKey: host];

			if (addresses == nil) {
				addresses = [OFMutableArray array];
				[staticHosts setObject: addresses forKey: host];
			}

			[addresses addObject: address];
		}
	}
	for (OFMutableArray *addresses in [staticHosts objectEnumerator])
		[addresses makeImmutable];

	[staticHosts makeImmutable];
	_staticHosts = [staticHosts copy];

	objc_autoreleasePoolPop(pool);
}

# ifndef OF_WINDOWS
- (void)parseResolvConfOption: (OFString *)option
{
	@try {
		if ([option hasPrefix: @"ndots:"]) {
			unsigned long long number;

			option = [option substringFromIndex: 6];
			number = option.unsignedLongLongValue;

			if (number > UINT_MAX)
				@throw [OFOutOfRangeException exception];

			_minNumberOfDotsInAbsoluteName = (unsigned int)number;
		} else if ([option hasPrefix: @"timeout:"]) {
			option = [option substringFromIndex: 8];

			_timeout = option.unsignedLongLongValue;
		} else if ([option hasPrefix: @"attempts:"]) {
			unsigned long long number;

			option = [option substringFromIndex: 9];
			number = option.unsignedLongLongValue;

			if (number > UINT_MAX)
				@throw [OFOutOfRangeException exception];

			_maxAttempts = (unsigned int)number;
		} else if ([option hasPrefix: @"reload-period:"]) {
			option = [option substringFromIndex: 14];

			_configReloadInterval = option.unsignedLongLongValue;
		} else if ([option isEqual: @"tcp"])
			_forcesTCP = true;
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
		file = [OFFile fileWithPath: path mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (nameServers == nil)
		nameServers = [OFMutableArray array];

	while ((line =
	    [file readLineWithEncoding: [OFLocale encoding]]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		size_t pos;
		OFArray *components, *arguments;
		OFString *option;

		pos = [line indexOfCharacterFromSet: commentCharacters];
		if (pos != OFNotFound)
			line = [line substringToIndex: pos];

		components = [line
		    componentsSeparatedByCharactersInSet: whitespaceCharacterSet
		    options: OFStringSkipEmptyComponents];

		if (components.count < 2) {
			objc_autoreleasePoolPop(pool2);
			continue;
		}

		option = [components.firstObject lowercaseString];
		arguments = [components objectsInRange:
		    OFMakeRange(1, components.count - 1)];

		if ([option isEqual: @"nameserver"]) {
			if (arguments.count != 1) {
				objc_autoreleasePoolPop(pool2);
				continue;
			}

			[nameServers addObject: arguments.firstObject];
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
	OFStringEncoding encoding = [OFLocale encoding];
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

	for (iter = &fixedInfo->DnsServerList; iter != NULL;
	    iter = iter->Next) {
		OFString *nameServer =
		    [OFString stringWithCString: iter->IpAddress.String
				       encoding: encoding];

		if (nameServer.length > 0)
			[nameServers addObject: nameServer];
	}

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

#ifdef OF_MORPHOS
- (void)obtainMorphOSSystemConfig
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *staticHosts;

	_nameServers = [parseNetStackArray(arexxCommand("NETSTACK",
	    "QUERY NAMESERVERS")) copy];
	_localDomain = [domainFromHostname(arexxCommand("NETSTACK",
	    "QUERY HOSTNAME")) copy];
	_searchDomains = [parseNetStackArray(arexxCommand("NETSTACK",
	    "QUERY DOMAINS")) copy];

	staticHosts = [OFMutableDictionary dictionary];

	for (OFString *entry in parseNetStackArray(arexxCommand("NETSTACK",
	    "QUERY HOSTS"))) {
		OFArray *components = [entry componentsSeparatedByString: @" "];
		OFString *address;
		OFArray *hosts;

		if (components.count < 2)
			continue;

		address = components.firstObject;
		hosts = [components objectsInRange:
		    OFMakeRange(1, components.count - 1)];

		for (OFString *host in hosts) {
			OFMutableArray *addresses;

			host = host.lowercaseString;
			addresses = [staticHosts objectForKey: host];

			if (addresses == nil) {
				addresses = [OFMutableArray array];
				[staticHosts setObject: addresses forKey: host];
			}

			[addresses addObject: address];
		}
	}
	for (OFMutableArray *addresses in [staticHosts objectEnumerator])
		[addresses makeImmutable];

	[staticHosts makeImmutable];
	_staticHosts = [staticHosts copy];

	objc_autoreleasePoolPop(pool);
}
#endif

#if defined(OF_AMIGAOS_M68K) || defined(OF_AMIGAOS4)
- (bool)obtainRoadshowSystemConfig
{
	OFMutableArray *nameServers;
	OFStringEncoding encoding;
	struct List *nameServerList;
	char buffer[MAXHOSTNAMELEN];
	LONG hasDNSAPI;

	if (SocketBaseTags(SBTM_GETREF(SBTC_HAVE_DNS_API), (ULONG)&hasDNSAPI,
	    TAG_END) != 0 || !hasDNSAPI)
		return false;

	nameServers = [OFMutableArray array];
	encoding = [OFLocale encoding];
	nameServerList = ObtainDomainNameServerList();

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

	return true;
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
		uint32_t ip = OFFromBigEndian32(buffer.entries[i].ip.s_addr);

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
#ifdef OF_WINDOWS
	OFString *path = nil;
#endif
#if (defined(OF_AMIGAOS_M68K) || defined(OF_AMIGAOS4)) && defined(OF_HAVE_FILES)
	OFFileManager *fileManager = [OFFileManager defaultManager];
#endif
	void *pool;

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
	@try {
		OFWindowsRegistryKey *key;

		key = [[OFWindowsRegistryKey localMachineKey]
		    openSubkeyAtPath: @"SYSTEM\\CurrentControlSet\\Services\\"
				      @"Tcpip\\Parameters"
			accessRights: KEY_QUERY_VALUE
			     options: 0];
		path = [[[key stringForValueNamed: @"DataBasePath"]
		   stringByAppendingPathComponent: @"hosts"]
		   stringByExpandingWindowsEnvironmentStrings];
	} @catch (OFOpenWindowsRegistryKeyFailedException *e) {
		/* Ignore */
	} @catch (OFUndefinedKeyException *e) {
		/* Ignore */
	}

	if (path != nil)
		[self parseHosts: path];
# endif

	[self obtainWindowsSystemConfig];
#elif defined(OF_MORPHOS)
	[self obtainMorphOSSystemConfig];
#elif defined(OF_AMIGAOS_M68K) || defined(OF_AMIGAOS4)
# ifdef OF_HAVE_FILES
	if (![self obtainRoadshowSystemConfig]) {
		if (assignExists("AmiTCP"))
			/*
			 * FIXME: The installer puts it there, but theoretically
			 *	  it could also be in AmiTCP:db/netdb or any of
			 *	  the files included there.
			 */
			[self parseResolvConf: @"AmiTCP:db/netdb-myhost"];
	}

	if ([fileManager fileExistsAtPath: @"DEVS:Internet/hosts"])
		[self parseHosts: @"DEVS:Internet/hosts"];
	else if (assignExists("AmiTCP"))
		[self parseHosts: @"AmiTCP:db/hosts"];
# else
	[self obtainRoadshowSystemConfig];
# endif
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

#if !defined(OF_WII) && !defined(OF_MORPHOS)
	if (_localDomain == nil)
		_localDomain = [domainFromHostname(obtainHostname()) copy];
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
