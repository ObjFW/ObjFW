/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFUUID.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFUUID
+ (instancetype)UUID
{
	return [[[self alloc] init] autorelease];
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
		OFHashAdd(&hash, _bytes[i]);

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

- (OFString *)UUIDString
{
	return [OFString stringWithFormat:
	    @"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-"
	    @"%02X%02X%02X%02X%02X%02X",
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
