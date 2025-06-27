/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFSRVDNSResourceRecord.h"

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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_target);

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
