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

#import "OFUUID.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#define bytesSize 16

@implementation OFUUID
+ (instancetype)UUID
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)UUIDWithUUIDBytes: (const unsigned char [16])bytes
{
	return [[[self alloc] initWithUUIDBytes: bytes] autorelease];
}

+ (instancetype)UUIDWithUUIDString: (OFString *)string
{
	return [[[self alloc] initWithUUIDString: string] autorelease];
}

- (instancetype)init
{
	uint64_t r;

	self = [super init];

	r = OFRandom64();
	memcpy(_bytes, &r, 8);
	r = OFRandom64();
	memcpy(_bytes + 8, &r, 8);

	_bytes[6] &= ~((1 << 7) | (1 << 5) | (1 << 4));
	_bytes[6] |= (1 << 6);
	_bytes[8] &= ~(1 << 6);
	_bytes[8] |= (1 << 7);

	return self;
}

- (instancetype)initWithUUIDBytes: (const unsigned char [16])bytes
{
	self = [super init];

	memcpy(_bytes, bytes, sizeof(_bytes));

	return self;
}

static void
decode(OFArray OF_GENERIC(OFString *) *components, size_t componentIndex,
    size_t componentLength, unsigned char *bytes, size_t *i)
{
	void *pool = objc_autoreleasePoolPush();
	OFString *component = [components objectAtIndex: componentIndex];
	const char *cString;

	if (component.UTF8StringLength != componentLength)
		@throw [OFInvalidFormatException exception];

	if (*i + componentLength / 2 > bytesSize)
		@throw [OFOutOfRangeException exception];

	cString = component.UTF8String;

	for (size_t j = 0; j < componentLength; j += 2) {
		uint8_t value;

		if (cString[j] >= '0' && cString[j] <= '9')
			value = cString[j] - '0';
		else if (cString[j] >= 'a' && cString[j] <= 'f')
			value = cString[j] - 'a' + 10;
		else if (cString[j] >= 'A' && cString[j] <= 'F')
			value = cString[j] - 'A' + 10;
		else
			@throw [OFInvalidFormatException exception];

		value <<= 4;

		if (cString[j + 1] >= '0' && cString[j + 1] <= '9')
			value |= cString[j + 1] - '0';
		else if (cString[j + 1] >= 'a' && cString[j + 1] <= 'f')
			value |= cString[j + 1] - 'a' + 10;
		else if (cString[j + 1] >= 'A' && cString[j + 1] <= 'F')
			value |= cString[j + 1] - 'A' + 10;
		else
			@throw [OFInvalidFormatException exception];

		bytes[(*i)++] = value;
	}

	objc_autoreleasePoolPop(pool);
}

- (instancetype)initWithUUIDString: (OFString *)string
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		size_t i = 0;
		OFArray OF_GENERIC(OFString *) *components =
		    [string componentsSeparatedByString: @"-"];

		if (components.count != 5)
			@throw [OFInvalidFormatException exception];

		decode(components, 0, 8, _bytes, &i);
		decode(components, 1, 4, _bytes, &i);
		decode(components, 2, 4, _bytes, &i);
		decode(components, 3, 4, _bytes, &i);
		decode(components, 4, 12, _bytes, &i);

		OFEnsure(i == 16);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)isEqual: (id)object
{
	OFUUID *UUID;

	if (![object isKindOfClass: [OFUUID class]])
		return false;

	UUID = object;

	return (memcmp(_bytes, UUID->_bytes, sizeof(_bytes)) == 0);
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < sizeof(_bytes); i++)
		OFHashAddByte(&hash, _bytes[i]);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (OFComparisonResult)compare: (OFUUID *)UUID
{
	int comparison;

	if (![UUID isKindOfClass: [OFUUID class]])
		@throw [OFInvalidArgumentException exception];

	if ((comparison = memcmp(_bytes, UUID->_bytes, sizeof(_bytes))) == 0)
		return OFOrderedSame;

	if (comparison > 0)
		return OFOrderedDescending;
	else
		return OFOrderedAscending;
}

- (void)getUUIDBytes: (unsigned char [16])bytes
{
	memcpy(bytes, _bytes, sizeof(_bytes));
}

- (OFString *)UUIDString
{
	return [OFString stringWithFormat:
	    @"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-"
	    @"%02x%02x%02x%02x%02x%02x",
	    _bytes[0], _bytes[1], _bytes[2], _bytes[3],
	    _bytes[4], _bytes[5], _bytes[6], _bytes[7],
	    _bytes[8], _bytes[9], _bytes[10], _bytes[11],
	    _bytes[12], _bytes[13], _bytes[14], _bytes[15]];
}

- (OFString *)description
{
	return self.UUIDString;
}
@end
