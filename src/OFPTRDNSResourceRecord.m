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

#import "OFPTRDNSResourceRecord.h"

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
