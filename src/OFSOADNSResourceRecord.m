/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFSOADNSResourceRecord.h"

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
