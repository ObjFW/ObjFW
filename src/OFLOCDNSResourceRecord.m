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

#import "OFLOCDNSResourceRecord.h"

@implementation OFLOCDNSResourceRecord
@synthesize size = _size, horizontalPrecision = _horizontalPrecision;
@synthesize verticalPrecision = _verticalPrecision, latitude = _latitude;
@synthesize longitude = _longitude, altitude = _altitude;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
			size: (uint8_t)size
	 horizontalPrecision: (uint8_t)horizontalPrecision
	   verticalPrecision: (uint8_t)verticalPrecision
		    latitude: (uint32_t)latitude
		   longitude: (uint32_t)longitude
		    altitude: (uint32_t)altitude
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeLOC
			       TTL: TTL];

	@try {
		_size = size;
		_horizontalPrecision = horizontalPrecision;
		_verticalPrecision = verticalPrecision;
		_latitude = latitude;
		_longitude = longitude;
		_altitude = altitude;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (bool)isEqual: (id)object
{
	OFLOCDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFLOCDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_size != _size)
		return false;

	if (record->_horizontalPrecision != _horizontalPrecision)
		return false;

	if (record->_verticalPrecision != _verticalPrecision)
		return false;

	if (record->_latitude != _latitude)
		return false;

	if (record->_longitude != _longitude)
		return false;

	if (record->_altitude != _altitude)
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
	OFHashAddByte(&hash, _size);
	OFHashAddByte(&hash, _horizontalPrecision);
	OFHashAddByte(&hash, _verticalPrecision);
	OFHashAddByte(&hash, _latitude >> 24);
	OFHashAddByte(&hash, _latitude >> 16);
	OFHashAddByte(&hash, _latitude >> 8);
	OFHashAddByte(&hash, _latitude);
	OFHashAddByte(&hash, _longitude >> 24);
	OFHashAddByte(&hash, _longitude >> 16);
	OFHashAddByte(&hash, _longitude >> 8);
	OFHashAddByte(&hash, _longitude);
	OFHashAddByte(&hash, _altitude >> 24);
	OFHashAddByte(&hash, _altitude >> 16);
	OFHashAddByte(&hash, _altitude >> 8);
	OFHashAddByte(&hash, _altitude);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tSize = %ue%u\n"
	    @"\tHorizontal precision = %ue%u\n"
	    @"\tVertical precision = %ue%u\n"
	    @"\tLatitude = %f\n"
	    @"\tLongitude = %f\n"
	    @"\tAltitude = %f\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass),
	    _size >> 4, _size & 0xF,
	    _horizontalPrecision >> 4, _horizontalPrecision & 0xF,
	    _verticalPrecision >> 4, _verticalPrecision & 0xF,
	    ((double)_latitude - 2147483648) / 3600000,
	    ((double)_longitude - 2147483648) / 3600000,
	    ((double)_altitude - 10000000) / 100, _TTL];
}
@end
