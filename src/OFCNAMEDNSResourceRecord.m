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

#import "OFCNAMEDNSResourceRecord.h"

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
