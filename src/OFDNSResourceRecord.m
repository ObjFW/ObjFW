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

#import "OFDNSResourceRecord.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

OFString *
of_dns_class_to_string(of_dns_class_t DNSClass)
{
	switch (DNSClass) {
	case OF_DNS_CLASS_IN:
		return @"IN";
	case OF_DNS_CLASS_ANY:
		return @"any";
	default:
		return [OFString stringWithFormat: @"%u", DNSClass];
	}
}

OFString *
of_dns_record_type_to_string(of_dns_record_type_t recordType)
{
	switch (recordType) {
	case OF_DNS_RECORD_TYPE_A:
		return @"A";
	case OF_DNS_RECORD_TYPE_NS:
		return @"NS";
	case OF_DNS_RECORD_TYPE_CNAME:
		return @"CNAME";
	case OF_DNS_RECORD_TYPE_SOA:
		return @"SOA";
	case OF_DNS_RECORD_TYPE_PTR:
		return @"PTR";
	case OF_DNS_RECORD_TYPE_HINFO:
		return @"HINFO";
	case OF_DNS_RECORD_TYPE_MX:
		return @"MX";
	case OF_DNS_RECORD_TYPE_TXT:
		return @"TXT";
	case OF_DNS_RECORD_TYPE_RP:
		return @"RP";
	case OF_DNS_RECORD_TYPE_AAAA:
		return @"AAAA";
	case OF_DNS_RECORD_TYPE_SRV:
		return @"SRV";
	case OF_DNS_RECORD_TYPE_ALL:
		return @"all";
	default:
		return [OFString stringWithFormat: @"%u", recordType];
	}
}

of_dns_class_t of_dns_class_parse(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	of_dns_class_t DNSClass;

	string = string.uppercaseString;

	if ([string isEqual: @"IN"])
		DNSClass = OF_DNS_CLASS_IN;
	else {
		@try {
			DNSClass = (of_dns_class_t)[string decimalValue];
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidArgumentException exception];
		}
	}

	objc_autoreleasePoolPop(pool);

	return DNSClass;
}

of_dns_record_type_t of_dns_record_type_parse(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	of_dns_record_type_t recordType;

	string = string.uppercaseString;

	if ([string isEqual: @"A"])
		recordType = OF_DNS_RECORD_TYPE_A;
	else if ([string isEqual: @"NS"])
		recordType = OF_DNS_RECORD_TYPE_NS;
	else if ([string isEqual: @"CNAME"])
		recordType = OF_DNS_RECORD_TYPE_CNAME;
	else if ([string isEqual: @"SOA"])
		recordType = OF_DNS_RECORD_TYPE_SOA;
	else if ([string isEqual: @"PTR"])
		recordType = OF_DNS_RECORD_TYPE_PTR;
	else if ([string isEqual: @"HINFO"])
		recordType = OF_DNS_RECORD_TYPE_HINFO;
	else if ([string isEqual: @"MX"])
		recordType = OF_DNS_RECORD_TYPE_MX;
	else if ([string isEqual: @"TXT"])
		recordType = OF_DNS_RECORD_TYPE_TXT;
	else if ([string isEqual: @"RP"])
		recordType = OF_DNS_RECORD_TYPE_RP;
	else if ([string isEqual: @"AAAA"])
		recordType = OF_DNS_RECORD_TYPE_AAAA;
	else if ([string isEqual: @"SRV"])
		recordType = OF_DNS_RECORD_TYPE_SRV;
	else {
		@try {
			recordType =
			    (of_dns_record_type_t)[string decimalValue];
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidArgumentException exception];
		}
	}

	objc_autoreleasePoolPop(pool);

	return recordType;
}

@implementation OFDNSResourceRecord
@synthesize name = _name, DNSClass = _DNSClass, recordType = _recordType;
@synthesize TTL = _TTL;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
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
	    self.className, _name, of_dns_class_to_string(_DNSClass),
	    of_dns_record_type_to_string(_recordType), _TTL];
}
@end

@implementation OFADNSResourceRecord
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		     address: (const of_socket_address_t *)address
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: OF_DNS_CLASS_IN
			recordType: OF_DNS_RECORD_TYPE_A
			       TTL: TTL];

	_address = *address;

	return self;
}

- (const of_socket_address_t *)address
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

	if (!of_socket_address_equal(&record->_address, &_address))
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, of_socket_address_hash(&_address));

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name,
	    of_socket_address_ip_string(&_address, NULL), _TTL];
}
@end

@implementation OFAAAADNSResourceRecord
- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		     address: (const of_socket_address_t *)address
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: OF_DNS_CLASS_IN
			recordType: OF_DNS_RECORD_TYPE_AAAA
			       TTL: TTL];

	_address = *address;

	return self;
}

- (const of_socket_address_t *)address
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

	if (!of_socket_address_equal(&record->_address, &_address))
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, of_socket_address_hash(&_address));

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name,
	    of_socket_address_ip_string(&_address, NULL), _TTL];
}
@end

@implementation OFCNAMEDNSResourceRecord
@synthesize alias = _alias;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		       alias: (OFString *)alias
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_CNAME
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _alias.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass), _alias,
	    _TTL];
}
@end

@implementation OFHINFODNSResourceRecord
@synthesize CPU = _CPU, OS = _OS;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
			 CPU: (OFString *)CPU
			  OS: (OFString *)OS
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_HINFO
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _CPU.hash);
	OF_HASH_ADD_HASH(hash, _OS.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass), _CPU, _OS,
	    _TTL];
}
@end

@implementation OFMXDNSResourceRecord
@synthesize preference = _preference, mailExchange = _mailExchange;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  preference: (uint16_t)preference
		mailExchange: (OFString *)mailExchange
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_MX
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD(hash, _preference >> 8);
	OF_HASH_ADD(hash, _preference);
	OF_HASH_ADD_HASH(hash, _mailExchange.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass),
	    _preference, _mailExchange, _TTL];
}
@end

@implementation OFNSDNSResourceRecord
@synthesize authoritativeHost = _authoritativeHost;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
	   authoritativeHost: (OFString *)authoritativeHost
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_NS
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _authoritativeHost.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass),
	    _authoritativeHost, _TTL];
}
@end

@implementation OFPTRDNSResourceRecord
@synthesize domainName = _domainName;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  domainName: (OFString *)domainName
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_PTR
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _domainName.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass),
	    _domainName, _TTL];
}
@end

@implementation OFRPDNSResourceRecord
@synthesize mailbox = _mailbox, TXTDomainName = _TXTDomainName;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		     mailbox: (OFString *)mailbox
	       TXTDomainName: (OFString *)TXTDomainName
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_RP
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _mailbox.hash);
	OF_HASH_ADD_HASH(hash, _TXTDomainName.hash);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass), _mailbox,
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
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
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
			recordType: OF_DNS_RECORD_TYPE_SOA
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _primaryNameServer.hash);
	OF_HASH_ADD_HASH(hash, _responsiblePerson.hash);
	OF_HASH_ADD(hash, _serialNumber >> 24);
	OF_HASH_ADD(hash, _serialNumber >> 16);
	OF_HASH_ADD(hash, _serialNumber >> 8);
	OF_HASH_ADD(hash, _serialNumber);
	OF_HASH_ADD(hash, _refreshInterval >> 24);
	OF_HASH_ADD(hash, _refreshInterval >> 16);
	OF_HASH_ADD(hash, _refreshInterval >> 8);
	OF_HASH_ADD(hash, _refreshInterval);
	OF_HASH_ADD(hash, _retryInterval >> 24);
	OF_HASH_ADD(hash, _retryInterval >> 16);
	OF_HASH_ADD(hash, _retryInterval >> 8);
	OF_HASH_ADD(hash, _retryInterval);
	OF_HASH_ADD(hash, _expirationInterval >> 24);
	OF_HASH_ADD(hash, _expirationInterval >> 16);
	OF_HASH_ADD(hash, _expirationInterval >> 8);
	OF_HASH_ADD(hash, _expirationInterval);
	OF_HASH_ADD(hash, _minTTL >> 24);
	OF_HASH_ADD(hash, _minTTL >> 16);
	OF_HASH_ADD(hash, _minTTL >> 8);
	OF_HASH_ADD(hash, _minTTL);

	OF_HASH_FINALIZE(hash);

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
	    self.className, _name, of_dns_class_to_string(_DNSClass),
	    _primaryNameServer, _responsiblePerson, _serialNumber,
	    _refreshInterval, _retryInterval, _expirationInterval, _minTTL,
	    _TTL];
}
@end

@implementation OFSRVDNSResourceRecord
@synthesize priority = _priority, weight = _weight, target = _target;
@synthesize port = _port;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
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
			  DNSClass: OF_DNS_CLASS_IN
			recordType: OF_DNS_RECORD_TYPE_SRV
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD(hash, _priority >> 8);
	OF_HASH_ADD(hash, _priority);
	OF_HASH_ADD(hash, _weight >> 8);
	OF_HASH_ADD(hash, _weight);
	OF_HASH_ADD_HASH(hash, _target.hash);
	OF_HASH_ADD(hash, _port >> 8);
	OF_HASH_ADD(hash, _port);

	OF_HASH_FINALIZE(hash);

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
@synthesize textData = _textData;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		  recordType: (of_dns_record_type_t)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (of_dns_class_t)DNSClass
		    textData: (OFData *)textData
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OF_DNS_RECORD_TYPE_TXT
			       TTL: TTL];

	@try {
		_textData = [textData copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_textData release];

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

	if (record->_textData != _textData &&
	    ![record->_textData isEqual: _textData])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, _DNSClass >> 8);
	OF_HASH_ADD(hash, _DNSClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, _textData.hash);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tText Data = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, of_dns_class_to_string(_DNSClass), _textData,
	    _TTL];
}
@end
