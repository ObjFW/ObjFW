/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFMessagePackExtension.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFMessagePackExtension
@synthesize type = _type, data = _data;

+ (instancetype)extensionWithType: (int8_t)type data: (OFData *)data
{
	return objc_autoreleaseReturnValue([[self alloc] initWithType: type
								 data: data]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithType: (int8_t)type data: (OFData *)data
{
	self = [super init];

	@try {
		if (data == nil || data.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		_type = type;
		_data = [data copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_data);

	[super dealloc];
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *ret;
	uint8_t prefix;
	size_t count = _data.count;

	if (count == 1) {
		ret = [OFMutableData dataWithCapacity: 3];

		prefix = 0xD4;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 2) {
		ret = [OFMutableData dataWithCapacity: 4];

		prefix = 0xD5;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 4) {
		ret = [OFMutableData dataWithCapacity: 6];

		prefix = 0xD6;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 8) {
		ret = [OFMutableData dataWithCapacity: 10];

		prefix = 0xD7;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count == 16) {
		ret = [OFMutableData dataWithCapacity: 18];

		prefix = 0xD8;
		[ret addItem: &prefix];

		[ret addItem: &_type];
	} else if (count <= UINT8_MAX) {
		uint8_t length;

		ret = [OFMutableData dataWithCapacity: count + 3];

		prefix = 0xC7;
		[ret addItem: &prefix];

		length = (uint8_t)count;
		[ret addItem: &length];

		[ret addItem: &_type];
	} else if (count <= UINT16_MAX) {
		uint16_t length;

		ret = [OFMutableData dataWithCapacity: count + 4];

		prefix = 0xC8;
		[ret addItem: &prefix];

		length = OFToBigEndian16((uint16_t)count);
		[ret addItems: &length count: 2];

		[ret addItem: &_type];
	} else if (count <= UINT32_MAX) {
		uint32_t length;

		ret = [OFMutableData dataWithCapacity: count + 6];

		prefix = 0xC9;
		[ret addItem: &prefix];

		length = OFToBigEndian32((uint32_t)count);
		[ret addItems: &length count: 4];

		[ret addItem: &_type];
	} else
		@throw [OFOutOfRangeException exception];

	[ret addItems: _data.items count: _data.count];
	[ret makeImmutable];

	return ret;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFMessagePackExtension: %d, %@>",
					   _type, _data];
}

- (bool)isEqual: (id)object
{
	OFMessagePackExtension *extension;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMessagePackExtension class]])
		return false;

	extension = object;

	if (extension->_type != _type || ![extension->_data isEqual: _data])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddByte(&hash, (uint8_t)_type);
	OFHashAddHash(&hash, _data.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}
@end
