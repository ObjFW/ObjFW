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

#import "OFTaggedPointerString.h"

#import "OFOutOfRangeException.h"

static int stringTag;

static OF_INLINE size_t
lengthForValue(uintptr_t value)
{
	if (value <= 0x7F)
		return 1;
	if (value <= 0x3FFF)
		return 2;
	if (value <= 0x1FFFFF)
		return 3;
	if (value <= 0xFFFFFFF)
		return 4;
#if UINTPTR_MAX == UINT64_MAX
	if (value <= 0x7FFFFFFFF)
		return 5;
	if (value <= 0x3FFFFFFFFFF)
		return 6;
	if (value <= 0x1FFFFFFFFFFFF)
		return 7;
	if (value <= 0xFFFFFFFFFFFFFF)
		return 8;
#endif

	@throw [OFOutOfRangeException exception];
}

@implementation OFTaggedPointerString
+ (void)initialize
{
	if (self == [OFTaggedPointerString class])
		stringTag = objc_registerTaggedPointerClass(self);
}

+ (OFTaggedPointerString *)stringWithASCIIString: (const char *)ASCIIString
					  length: (size_t)length
{
	uintptr_t value = 0;

	for (size_t i = 0; i < length; i++)
		value |= (uintptr_t)ASCIIString[i] << (i * 7);

	return objc_createTaggedPointer(stringTag, value);
}

- (size_t)length
{
	return lengthForValue(object_getTaggedPointerValue(self));
}

- (OFUnichar)characterAtIndex: (size_t)idx
{
	uintptr_t value = object_getTaggedPointerValue(self);

	if (idx >= lengthForValue(value))
		@throw [OFOutOfRangeException exception];

	return (value >> (idx * 7)) & 0x7F;
}

- (unsigned long)hash
{
	uintptr_t value = object_getTaggedPointerValue(self);
	unsigned long hash;

	OFHashInit(&hash);

	while (value > 0) {
		OFHashAddByte(&hash, 0);
		OFHashAddByte(&hash, 0);
		OFHashAddByte(&hash, value & 0x7F);
		value >>= 7;
	}

	OFHashFinalize(&hash);

	return hash;
}

- (size_t)UTF8StringLength
{
	return self.length;
}

- (size_t)cStringLengthWithEncoding: (OFStringEncoding)encoding
{
	return self.length;
}

- (void)getCharacters: (OFUnichar *)buffer inRange: (OFRange)range
{
	uintptr_t value = object_getTaggedPointerValue(self);

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > lengthForValue(value))
		@throw [OFOutOfRangeException exception];

	for (size_t i = 0; i < range.length; i++)
		buffer[i] = (value >> ((i + range.location) * 7)) & 0x7F;
}

OF_SINGLETON_METHODS
@end
