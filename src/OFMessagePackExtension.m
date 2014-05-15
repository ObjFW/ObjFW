/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFMessagePackExtension.h"
#import "OFDataArray.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

#import "macros.h"

@implementation OFMessagePackExtension
+ (instancetype)extensionWithType: (int8_t)type
			     data: (OFDataArray*)data
{
	return [[[self alloc] initWithType: type
				      data: data] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithType: (int8_t)type
	  data: (OFDataArray*)data
{
	self = [super init];

	@try {
		if (data == nil || [data itemSize] != 1)
			@throw [OFInvalidArgumentException exception];

		_type = type;
		_data = [data retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (int8_t)type
{
	return _type;
}

- (OFDataArray*)data
{
	OF_GETTER(_data, true)
}

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *ret;
	uint8_t prefix;
	size_t count = [_data count];

	if (count == 1) {
		ret = [OFDataArray dataArrayWithCapacity: 3];

		prefix = 0xD4;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 2) {
		ret = [OFDataArray dataArrayWithCapacity: 4];

		prefix = 0xD5;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 4) {
		ret = [OFDataArray dataArrayWithCapacity: 6];

		prefix = 0xD6;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 8) {
		ret = [OFDataArray dataArrayWithCapacity: 10];

		prefix = 0xD7;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 16) {
		ret = [OFDataArray dataArrayWithCapacity: 18];

		prefix = 0xD8;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count < 0x100) {
		uint8_t length;

		ret = [OFDataArray dataArrayWithCapacity: count + 3];

		prefix = 0xC7;
		[ret addItem: &prefix];

		length = (uint8_t)count;
		[ret addItem: &length];

		[ret addItem: &_type];
	} else if (count < 0x10000) {
		uint16_t length;

		ret = [OFDataArray dataArrayWithCapacity: count + 4];

		prefix = 0xC8;
		[ret addItem: &prefix];

		length = OF_BSWAP16((uint16_t)count);
		[ret addItems: &length
			count: 2];

		[ret addItem: &_type];
	} else {
		uint32_t length;

		ret = [OFDataArray dataArrayWithCapacity: count + 6];

		prefix = 0xC9;
		[ret addItem: &prefix];

		length = OF_BSWAP32((uint32_t)count);
		[ret addItems: &length
			count: 4];

		[ret addItem: &_type];
	}

	[ret addItems: [_data items]
		count: [_data count]];

	return ret;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<OFMessagePackExtension: %d, %@>",
					   _type, _data];
}

- (bool)isEqual: (id)object
{
	OFMessagePackExtension *extension;

	if (![object isKindOfClass: [OFMessagePackExtension class]])
		return false;

	extension = object;

	if (extension->_type != _type || ![extension->_data isEqual: _data])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD(hash, (uint8_t)_type);
	OF_HASH_ADD_HASH(hash, [_data hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFMessagePackExtension *ret;
	OFDataArray *data;

	data = [_data copy];
	@try {
		ret = [[OFMessagePackExtension alloc] initWithType: _type
							      data: data];
	} @finally {
		[data release];
	}

	return ret;
}
@end
