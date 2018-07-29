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

@implementation OFDNSResourceRecord
@synthesize name = _name, type = _type, dataClass = _dataClass, data = _data;
@synthesize TTL = _TTL;

- (instancetype)initWithName: (OFString *)name
			type: (uint16_t)type
		   dataClass: (uint16_t)dataClass
			data: (OFData *)data
			 TTL: (uint32_t)TTL
{
	self = [super init];

	@try {
		_name = [name copy];
		_type = type;
		_dataClass = dataClass;
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

	if (otherRecord->_type != _type)
		return false;

	if (otherRecord->_dataClass != _dataClass)
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
	OF_HASH_ADD(hash, _type >> 8);
	OF_HASH_ADD(hash, _type);
	OF_HASH_ADD(hash, _dataClass >> 8);
	OF_HASH_ADD(hash, _dataClass);
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
	id data = _data;

	if (_dataClass == 1 && _type == 1)
		data = [self IPAddress];

	return [OFString stringWithFormat:
	    @"<OFDNSResourceRecord:\n"
	    @"\tName = %@,\n"
	    @"\tType = %" PRIu16 "\n"
	    @"\tData Class = %" PRIu16 "\n"
	    @"\tData = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    _name, _type, _dataClass, data, _TTL];
}

- (OFString *)IPAddress
{
	const unsigned char *dataItems;

	if (_dataClass != 1)
		@throw [OFInvalidFormatException exception];

	if ([_data itemSize] != 1)
		@throw [OFInvalidFormatException exception];

	dataItems = [_data items];

	switch (_type) {
	case 1:
		if ([_data count] != 4)
			@throw [OFInvalidFormatException exception];

		return [OFString stringWithFormat: @"%u.%u.%u.%u",
		    dataItems[0], dataItems[1], dataItems[2], dataItems[3]];
	case 28:
		/* TODO: Implement */
	default:
		@throw [OFInvalidFormatException exception];
	}
}
@end
