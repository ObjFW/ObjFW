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

#import "OFDNSResourceRecord.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

OFString *
of_dns_resource_record_class_to_string(
    of_dns_resource_record_class_t recordClass)
{
	switch (recordClass) {
	case OF_DNS_RESOURCE_RECORD_CLASS_IN:
		return @"IN";
	case OF_DNS_RESOURCE_RECORD_CLASS_ANY:
		return @"any";
	default:
		return [OFString stringWithFormat: @"%u", recordClass];
	}
}

OFString *
of_dns_resource_record_type_to_string(of_dns_resource_record_type_t recordType)
{
	switch (recordType) {
	case OF_DNS_RESOURCE_RECORD_TYPE_A:
		return @"A";
	case OF_DNS_RESOURCE_RECORD_TYPE_NS:
		return @"NS";
	case OF_DNS_RESOURCE_RECORD_TYPE_CNAME:
		return @"CNAME";
	case OF_DNS_RESOURCE_RECORD_TYPE_SOA:
		return @"SOA";
	case OF_DNS_RESOURCE_RECORD_TYPE_PTR:
		return @"PTR";
	case OF_DNS_RESOURCE_RECORD_TYPE_MX:
		return @"MX";
	case OF_DNS_RESOURCE_RECORD_TYPE_TXT:
		return @"TXT";
	case OF_DNS_RESOURCE_RECORD_TYPE_AAAA:
		return @"AAAA";
	case OF_DNS_RESOURCE_RECORD_TYPE_ALL:
		return @"all";
	default:
		return [OFString stringWithFormat: @"%u", recordType];
	}
}

@implementation OFDNSResourceRecord
@synthesize name = _name, recordClass = _recordClass, recordType = _recordType;
@synthesize data = _data, TTL = _TTL;

- (instancetype)initWithName: (OFString *)name
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
			data: (id)data
			 TTL: (uint32_t)TTL
{
	self = [super init];

	@try {
		_name = [name copy];
		_recordClass = recordClass;
		_recordType = recordType;
		_data = [data copy];
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
	[_data release];

	[super dealloc];
}

- (bool)isEqual: (id)otherObject
{
	OFDNSResourceRecord *otherRecord;

	if (![otherObject isKindOfClass: [OFDNSResourceRecord class]])
		return false;

	otherRecord = otherObject;

	if (otherRecord->_name != _name && ![otherRecord->_name isEqual: _name])
		return false;

	if (otherRecord->_recordClass != _recordClass)
		return false;

	if (otherRecord->_recordType != _recordType)
		return false;

	if (otherRecord->_data != _data && ![otherRecord->_data isEqual: _data])
		return false;

	if (otherRecord->_TTL != _TTL)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_name hash]);
	OF_HASH_ADD(hash, _recordClass >> 8);
	OF_HASH_ADD(hash, _recordClass);
	OF_HASH_ADD(hash, _recordType >> 8);
	OF_HASH_ADD(hash, _recordType);
	OF_HASH_ADD_HASH(hash, [_data hash]);
	OF_HASH_ADD(hash, _TTL >> 24);
	OF_HASH_ADD(hash, _TTL >> 16);
	OF_HASH_ADD(hash, _TTL >> 8);
	OF_HASH_ADD(hash, _TTL);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFDNSResourceRecord:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tType = %@\n"
	    @"\tData = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    _name, of_dns_resource_record_class_to_string(_recordClass),
	    of_dns_resource_record_type_to_string(_recordType), _data, _TTL];
}
@end
