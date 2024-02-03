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

#import "OFDNSResourceRecord.h"
#import "OFArray.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

OFString *
OFDNSClassName(OFDNSClass DNSClass)
{
	switch (DNSClass) {
	case OFDNSClassIN:
		return @"IN";
	case OFDNSClassAny:
		return @"any";
	default:
		return [OFString stringWithFormat: @"%u", DNSClass];
	}
}

OFString *
OFDNSRecordTypeName(OFDNSRecordType recordType)
{
	switch (recordType) {
	case OFDNSRecordTypeA:
		return @"A";
	case OFDNSRecordTypeNS:
		return @"NS";
	case OFDNSRecordTypeCNAME:
		return @"CNAME";
	case OFDNSRecordTypeSOA:
		return @"SOA";
	case OFDNSRecordTypePTR:
		return @"PTR";
	case OFDNSRecordTypeHINFO:
		return @"HINFO";
	case OFDNSRecordTypeMX:
		return @"MX";
	case OFDNSRecordTypeTXT:
		return @"TXT";
	case OFDNSRecordTypeRP:
		return @"RP";
	case OFDNSRecordTypeAAAA:
		return @"AAAA";
	case OFDNSRecordTypeSRV:
		return @"SRV";
	case OFDNSRecordTypeAll:
		return @"all";
	default:
		return [OFString stringWithFormat: @"%u", recordType];
	}
}

OFDNSClass
OFDNSClassParseName(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSClass DNSClass;

	string = string.uppercaseString;

	if ([string isEqual: @"IN"])
		DNSClass = OFDNSClassIN;
	else {
		DNSClass =
		    (OFDNSClass)[string unsignedLongLongValueWithBase: 0];
	}

	objc_autoreleasePoolPop(pool);

	return DNSClass;
}

OFDNSRecordType
OFDNSRecordTypeParseName(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSRecordType recordType;

	string = string.uppercaseString;

	if ([string isEqual: @"A"])
		recordType = OFDNSRecordTypeA;
	else if ([string isEqual: @"NS"])
		recordType = OFDNSRecordTypeNS;
	else if ([string isEqual: @"CNAME"])
		recordType = OFDNSRecordTypeCNAME;
	else if ([string isEqual: @"SOA"])
		recordType = OFDNSRecordTypeSOA;
	else if ([string isEqual: @"PTR"])
		recordType = OFDNSRecordTypePTR;
	else if ([string isEqual: @"HINFO"])
		recordType = OFDNSRecordTypeHINFO;
	else if ([string isEqual: @"MX"])
		recordType = OFDNSRecordTypeMX;
	else if ([string isEqual: @"TXT"])
		recordType = OFDNSRecordTypeTXT;
	else if ([string isEqual: @"RP"])
		recordType = OFDNSRecordTypeRP;
	else if ([string isEqual: @"AAAA"])
		recordType = OFDNSRecordTypeAAAA;
	else if ([string isEqual: @"SRV"])
		recordType = OFDNSRecordTypeSRV;
	else if ([string isEqual: @"ALL"])
		recordType = OFDNSRecordTypeAll;
	else {
		recordType =
		    (OFDNSRecordType)[string unsignedLongLongValueWithBase: 0];
	}

	objc_autoreleasePoolPop(pool);

	return recordType;
}

@implementation OFDNSResourceRecord
@synthesize name = _name, DNSClass = _DNSClass, recordType = _recordType;
@synthesize TTL = _TTL;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	self = [super init];

	@try {
		_name = [name copy];
		_DNSClass = DNSClass;
		_recordType = recordType;
		_TTL = TTL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tType = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass),
	    OFDNSRecordTypeName(_recordType), _TTL];
}
@end

@implementation OFADNSResourceRecord
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		     address: (const OFSocketAddress *)address
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: OFDNSClassIN
			recordType: OFDNSRecordTypeA
			       TTL: TTL];

	_address = *address;

	return self;
}

- (const OFSocketAddress *)address
{
	return &_address;
}

- (bool)isEqual: (id)object
{
	OFADNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFADNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (!OFSocketAddressEqual(&record->_address, &_address))
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, OFSocketAddressHash(&_address));

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tAddress = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFSocketAddressString(&_address), _TTL];
}
@end

@implementation OFAAAADNSResourceRecord
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		     address: (const OFSocketAddress *)address
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: OFDNSClassIN
			recordType: OFDNSRecordTypeAAAA
			       TTL: TTL];

	_address = *address;

	return self;
}

- (const OFSocketAddress *)address
{
	return &_address;
}

- (bool)isEqual: (id)object
{
	OFAAAADNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFAAAADNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (!OFSocketAddressEqual(&record->_address, &_address))
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, OFSocketAddressHash(&_address));

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tAddress = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFSocketAddressString(&_address), _TTL];
}
@end

@implementation OFCNAMEDNSResourceRecord
@synthesize alias = _alias;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		       alias: (OFString *)alias
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeCNAME
			       TTL: TTL];

	@try {
		_alias = [alias copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_alias release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFCNAMEDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFCNAMEDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_alias != _alias && ![record->_alias isEqual: _alias])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _alias.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tAlias = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), _alias, _TTL];
}
@end

@implementation OFHINFODNSResourceRecord
@synthesize CPU = _CPU, OS = _OS;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
			 CPU: (OFString *)CPU
			  OS: (OFString *)OS
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeHINFO
			       TTL: TTL];

	@try {
		_CPU = [CPU copy];
		_OS = [OS copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_CPU release];
	[_OS release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFHINFODNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFHINFODNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_CPU != _CPU && ![record->_CPU isEqual: _CPU])
		return false;

	if (record->_OS != _OS && ![record->_OS isEqual: _OS])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _CPU.hash);
	OFHashAddHash(&hash, _OS.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tCPU = %@\n"
	    @"\tOS = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), _CPU, _OS, _TTL];
}
@end

@implementation OFMXDNSResourceRecord
@synthesize preference = _preference, mailExchange = _mailExchange;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  preference: (uint16_t)preference
		mailExchange: (OFString *)mailExchange
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeMX
			       TTL: TTL];

	@try {
		_preference = preference;
		_mailExchange = [mailExchange copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_mailExchange release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFMXDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMXDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_preference != _preference)
		return false;

	if (record->_mailExchange != _mailExchange &&
	    ![record->_mailExchange isEqual: _mailExchange])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddByte(&hash, _preference >> 8);
	OFHashAddByte(&hash, _preference);
	OFHashAddHash(&hash, _mailExchange.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tPreference = %" PRIu16 "\n"
	    @"\tMail Exchange = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), _preference,
	    _mailExchange, _TTL];
}
@end

@implementation OFNSDNSResourceRecord
@synthesize authoritativeHost = _authoritativeHost;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
	   authoritativeHost: (OFString *)authoritativeHost
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeNS
			       TTL: TTL];

	@try {
		_authoritativeHost = [authoritativeHost copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_authoritativeHost release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFNSDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFNSDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_authoritativeHost != _authoritativeHost &&
	    ![record->_authoritativeHost isEqual: _authoritativeHost])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _authoritativeHost.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tAuthoritative Host = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass),
	    _authoritativeHost, _TTL];
}
@end

@implementation OFPTRDNSResourceRecord
@synthesize domainName = _domainName;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  domainName: (OFString *)domainName
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypePTR
			       TTL: TTL];

	@try {
		_domainName = [domainName copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_domainName release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFPTRDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFPTRDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_domainName != _domainName &&
	    ![record->_domainName isEqual: _domainName])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _domainName.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tDomain Name = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), _domainName,
	    _TTL];
}
@end

@implementation OFRPDNSResourceRecord
@synthesize mailbox = _mailbox, TXTDomainName = _TXTDomainName;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		     mailbox: (OFString *)mailbox
	       TXTDomainName: (OFString *)TXTDomainName
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeRP
			       TTL: TTL];

	@try {
		_mailbox = [mailbox copy];
		_TXTDomainName = [TXTDomainName copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_mailbox release];
	[_TXTDomainName release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFRPDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFRPDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_mailbox != _mailbox &&
	    ![record->_mailbox isEqual: _mailbox])
		return false;

	if (record->_TXTDomainName != _TXTDomainName &&
	    ![record->_TXTDomainName isEqual: _TXTDomainName])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _mailbox.hash);
	OFHashAddHash(&hash, _TXTDomainName.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tMailbox = %@\n"
	    @"\tTXT Domain Name = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), _mailbox,
	    _TXTDomainName, _TTL];
}
@end

@implementation OFSOADNSResourceRecord
@synthesize primaryNameServer = _primaryNameServer;
@synthesize responsiblePerson = _responsiblePerson;
@synthesize serialNumber = _serialNumber, refreshInterval = _refreshInterval;
@synthesize retryInterval = _retryInterval;
@synthesize expirationInterval = _expirationInterval, minTTL = _minTTL;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
	   primaryNameServer: (OFString *)primaryNameServer
	   responsiblePerson: (OFString *)responsiblePerson
		serialNumber: (uint32_t)serialNumber
	     refreshInterval: (uint32_t)refreshInterval
	       retryInterval: (uint32_t)retryInterval
	  expirationInterval: (uint32_t)expirationInterval
		      minTTL: (uint32_t)minTTL
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeSOA
			       TTL: TTL];

	@try {
		_primaryNameServer = [primaryNameServer copy];
		_responsiblePerson = [responsiblePerson copy];
		_serialNumber = serialNumber;
		_refreshInterval = refreshInterval;
		_retryInterval = retryInterval;
		_expirationInterval = expirationInterval;
		_minTTL = minTTL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_primaryNameServer release];
	[_responsiblePerson release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFSOADNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFSOADNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_primaryNameServer != _primaryNameServer &&
	    ![record->_primaryNameServer isEqual: _primaryNameServer])
		return false;

	if (record->_responsiblePerson != _responsiblePerson &&
	    ![record->_responsiblePerson isEqual: _responsiblePerson])
		return false;

	if (record->_serialNumber != _serialNumber)
		return false;

	if (record->_refreshInterval != _refreshInterval)
		return false;

	if (record->_retryInterval != _retryInterval)
		return false;

	if (record->_expirationInterval != _expirationInterval)
		return false;

	if (record->_minTTL != _minTTL)
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _primaryNameServer.hash);
	OFHashAddHash(&hash, _responsiblePerson.hash);
	OFHashAddByte(&hash, _serialNumber >> 24);
	OFHashAddByte(&hash, _serialNumber >> 16);
	OFHashAddByte(&hash, _serialNumber >> 8);
	OFHashAddByte(&hash, _serialNumber);
	OFHashAddByte(&hash, _refreshInterval >> 24);
	OFHashAddByte(&hash, _refreshInterval >> 16);
	OFHashAddByte(&hash, _refreshInterval >> 8);
	OFHashAddByte(&hash, _refreshInterval);
	OFHashAddByte(&hash, _retryInterval >> 24);
	OFHashAddByte(&hash, _retryInterval >> 16);
	OFHashAddByte(&hash, _retryInterval >> 8);
	OFHashAddByte(&hash, _retryInterval);
	OFHashAddByte(&hash, _expirationInterval >> 24);
	OFHashAddByte(&hash, _expirationInterval >> 16);
	OFHashAddByte(&hash, _expirationInterval >> 8);
	OFHashAddByte(&hash, _expirationInterval);
	OFHashAddByte(&hash, _minTTL >> 24);
	OFHashAddByte(&hash, _minTTL >> 16);
	OFHashAddByte(&hash, _minTTL >> 8);
	OFHashAddByte(&hash, _minTTL);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tPrimary Name Server = %@\n"
	    @"\tResponsible Person = %@\n"
	    @"\tSerial Number = %" PRIu32 "\n"
	    @"\tRefresh Interval = %" PRIu32 "\n"
	    @"\tRetry Interval = %" PRIu32 "\n"
	    @"\tExpiration Interval = %" PRIu32 "\n"
	    @"\tMinimum TTL = %" PRIu32 "\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass),
	    _primaryNameServer, _responsiblePerson, _serialNumber,
	    _refreshInterval, _retryInterval, _expirationInterval, _minTTL,
	    _TTL];
}
@end

@implementation OFSRVDNSResourceRecord
@synthesize priority = _priority, weight = _weight, target = _target;
@synthesize port = _port;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    priority: (uint16_t)priority
		      weight: (uint16_t)weight
		      target: (OFString *)target
			port: (uint16_t)port
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: OFDNSClassIN
			recordType: OFDNSRecordTypeSRV
			       TTL: TTL];

	@try {
		_priority = priority;
		_weight = weight;
		_target = [target copy];
		_port = port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_target release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFSRVDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFSRVDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_priority != _priority)
		return false;

	if (record->_weight != _weight)
		return false;

	if (record->_target != _target && ![record->_target isEqual: _target])
		return false;

	if (record->_port != _port)
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddByte(&hash, _priority >> 8);
	OFHashAddByte(&hash, _priority);
	OFHashAddByte(&hash, _weight >> 8);
	OFHashAddByte(&hash, _weight);
	OFHashAddHash(&hash, _target.hash);
	OFHashAddByte(&hash, _port >> 8);
	OFHashAddByte(&hash, _port);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tPriority = %" PRIu16 "\n"
	    @"\tWeight = %" PRIu16 "\n"
	    @"\tTarget = %@\n"
	    @"\tPort = %" PRIu16 "\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, _priority, _weight, _target, _port, _TTL];
}
@end

@implementation OFTXTDNSResourceRecord
@synthesize textStrings = _textStrings;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		 textStrings: (OFArray OF_GENERIC(OFData *) *)textStrings
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeTXT
			       TTL: TTL];

	@try {
		_textStrings = [textStrings copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_textStrings release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFTXTDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFTXTDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_textStrings != _textStrings &&
	    ![record->_textStrings isEqual: _textStrings])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _textStrings.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableString *text = [OFMutableString string];
	bool first = true;
	OFString *ret;

	for (OFData *string in _textStrings) {
		const unsigned char *stringItems = string.items;
		size_t stringCount = string.count;

		if (first) {
			first = false;
			[text appendString: @"\""];
		} else
			[text appendString: @" \""];

		for (size_t i = 0; i < stringCount; i++) {
			if (stringItems[i] == '\\')
				[text appendString: @"\\\\"];
			else if (stringItems[i] == '"')
				[text appendString: @"\\\""];
			else if (stringItems[i] < 0x20)
				[text appendFormat: @"\\x%02X", stringItems[i]];
			else if (stringItems[i] < 0x7F)
				[text appendFormat: @"%c", stringItems[i]];
			else
				[text appendFormat: @"\\x%02X", stringItems[i]];
		}

		[text appendString: @"\""];
	}

	ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tText strings = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), text, _TTL];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
