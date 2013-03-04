/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFDataArray+BinaryPackValue.h"
#import "OFNumber.h"
#import "OFNull.h"
#import "OFDataArray.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"

#import "OFInvalidFormatException.h"

#import "autorelease.h"
#import "macros.h"

int _OFDataArray_BinaryPackValue_reference;

static size_t parse_object(const uint8_t*, size_t, id*);

static uint16_t
read_uint16(const uint8_t *buffer)
{
	return ((uint16_t)buffer[0] << 8) | buffer[1];
}

static uint32_t
read_uint32(const uint8_t *buffer)
{
	return ((uint32_t)buffer[0] << 24) | ((uint32_t)buffer[1] << 16) |
	    ((uint32_t)buffer[2] << 8) | buffer[3];
}

static uint64_t
read_uint64(const uint8_t *buffer)
{
	return ((uint64_t)buffer[0] << 56) | ((uint64_t)buffer[1] << 48) |
	    ((uint64_t)buffer[2] << 40) | ((uint64_t)buffer[3] << 32) |
	    ((uint64_t)buffer[4] << 24) | ((uint64_t)buffer[5] << 16) |
	    ((uint64_t)buffer[6] << 8) | buffer[7];
}

static size_t
parse_array(const uint8_t *buffer, size_t length, id *object, size_t count)
{
	void *pool;
	size_t i, pos;

	/*
	 * Don't use capacity! For data and strings, this is safe, as we can
	 * check if we still have enough bytes left. For an array however, we
	 * can't know this, as every child can be more than one byte.
	 */
	*object = [OFMutableArray array];
	pos = 0;

	for (i = 0; i < count; i++) {
		id child;
		size_t childLength;

		pool = objc_autoreleasePoolPush();

		childLength = parse_object(buffer + pos, length - pos, &child);
		if (childLength == 0 || child == nil) {
			objc_autoreleasePoolPop(pool);

			*object = nil;
			return 0;
		}
		pos += childLength;

		[*object addObject: child];

		objc_autoreleasePoolPop(pool);
	}

	return pos;
}

static size_t
parse_table(const uint8_t *buffer, size_t length, id *object, size_t count)
{
	void *pool;
	size_t i, pos;

	/*
	 * Don't use capacity! For data and strings, this is safe, as we can
	 * check if we still have enough bytes left. For a dictionary however,
	 * we can't know this, as every key / value can be more than one byte.
	 */
	*object = [OFMutableDictionary dictionary];
	pos = 0;

	for (i = 0; i < count; i++) {
		id key, value;
		size_t keyLength, valueLength;

		pool = objc_autoreleasePoolPush();

		keyLength = parse_object(buffer + pos, length - pos, &key);
		if (keyLength == 0 || key == nil) {
			objc_autoreleasePoolPop(pool);

			*object = nil;
			return 0;
		}
		pos += keyLength;

		valueLength = parse_object(buffer + pos, length - pos, &value);
		if (valueLength == 0 || value == nil) {
			objc_autoreleasePoolPop(pool);

			*object = nil;
			return 0;
		}
		pos += valueLength;

		[*object setObject: value
			    forKey: key];

		objc_autoreleasePoolPop(pool);
	}

	return pos;
}

static size_t
parse_object(const uint8_t *buffer, size_t length, id *object)
{
	size_t i, count;

	if (length < 1)
		goto error;

	/* Integers */
	if ((buffer[0] & 0x80) == 0) {
		*object = [OFNumber numberWithUInt8: buffer[0] & 0x7F];
		return 1;
	}
	if ((buffer[0] & 0xE0) == 0xE0) {
		*object = [OFNumber numberWithInt8:
		    ((int8_t)(buffer[0] & 0x1F)) - 32];
		return 1;
	}

	/* String */
	if ((buffer[0] & 0xE0) == 0xA0) {
		count = buffer[0] & 0x1F;

		if (length < count + 1)
			goto error;

		*object = [OFString
		    stringWithUTF8String: (const char*)buffer + 1
				  length: count];
		return count + 1;
	}

	/* Array */
	if ((buffer[0] & 0xF0) == 0x90)
		return parse_array(buffer + 1, length - 1, object,
		    buffer[0] & 0xF) + 1;

	/* Table */
	if ((buffer[0] & 0xF0) == 0x80)
		return parse_table(buffer + 1, length - 1, object,
		    buffer[0] & 0xF) + 1;

	/* Prefix byte */
	switch (*buffer) {
	/* Unsigned integers */
	case 0xCC:
		if (length < 2)
			goto error;

		*object = [OFNumber numberWithUInt8: buffer[1]];
		return 2;
	case 0xCD:
		if (length < 3)
			goto error;

		*object = [OFNumber numberWithUInt16: read_uint16(buffer + 1)];
		return 3;
	case 0xCE:
		if (length < 5)
			goto error;

		*object = [OFNumber numberWithUInt32: read_uint32(buffer + 1)];
		return 5;
	case 0xCF:
		if (length < 9)
			goto error;

		*object = [OFNumber numberWithUInt64: read_uint64(buffer + 1)];
		return 9;
	/* Signed integers */
	case 0xD0:
		if (length < 2)
			goto error;

		*object = [OFNumber numberWithInt8: buffer[1]];
		return 2;
	case 0xD1:
		if (length < 3)
			goto error;

		*object = [OFNumber numberWithInt16: read_uint16(buffer + 1)];
		return 3;
	case 0xD2:
		if (length < 5)
			goto error;

		*object = [OFNumber numberWithInt32: read_uint32(buffer + 1)];
		return 5;
	case 0xD3:
		if (length < 9)
			goto error;

		*object = [OFNumber numberWithInt64: read_uint64(buffer + 1)];
		return 9;
	/* Float */
	case 0xCA:;
		union {
			uint8_t u8[4];
			float f;
		} f;

		if (length < 5)
			goto error;

		for (i = 0; i < 4; i++)
			f.u8[i] = buffer[i + 1];

		*object = [OFNumber numberWithFloat: OF_BSWAP_FLOAT_IF_LE(f.f)];
		return 5;
	/* Double */
	case 0xCB:;
		union {
			uint8_t u8[8];
			double d;
		} d;

		if (length < 9)
			goto error;

		for (i = 0; i < 8; i++)
			d.u8[i] = buffer[i + 1];

		*object = [OFNumber numberWithDouble:
		    OF_BSWAP_DOUBLE_IF_LE(d.d)];
		return 9;
	/* nil */
	case 0xC0:
		*object = [OFNull null];
		return 1;
	/* false */
	case 0xC2:
		*object = [OFNumber numberWithBool: false];
		return 1;
	/* true */
	case 0xC3:
		*object = [OFNumber numberWithBool: true];
		return 1;
	/* Data */
	case 0xD5:
		if (length < 2)
			goto error;

		count = buffer[1];

		if (length < count + 2)
			goto error;

		*object = [OFDataArray dataArrayWithItemSize: 1
						    capacity: count];
		[*object addItems: buffer + 2
			    count: count];

		return count + 2;
	case 0xD6:
		if (length < 3)
			goto error;

		count = read_uint16(buffer + 1);

		if (length < count + 3)
			goto error;

		*object = [OFDataArray dataArrayWithItemSize: 1
						    capacity: count];
		[*object addItems: buffer + 3
			    count: count];

		return count + 3;
	case 0xD7:
		if (length < 5)
			goto error;

		count = read_uint32(buffer + 1);

		if (length < count + 5)
			goto error;

		*object = [OFDataArray dataArrayWithItemSize: 1
						    capacity: count];
		[*object addItems: buffer + 5
			    count: count];

		return count + 5;
	/* Strings */
	case 0xD9:
		if (length < 2)
			goto error;

		count = buffer[1];

		if (length < count + 2)
			goto error;

		*object = [OFString
		    stringWithUTF8String: (const char*)buffer + 2
				  length: count];
		return count + 2;
	case 0xDA:
		if (length < 3)
			goto error;

		count = read_uint16(buffer + 1);

		if (length < count + 3)
			goto error;

		*object = [OFString
		    stringWithUTF8String: (const char*)buffer + 3
				  length: count];
		return count + 3;
	case 0xDB:
		if (length < 5)
			goto error;

		count = read_uint32(buffer + 1);

		if (length < count + 5)
			goto error;

		*object = [OFString
		    stringWithUTF8String: (const char*)buffer + 5
				  length: count];
		return count + 5;
	/* Arrays */
	case 0xDC:
		if (length < 3)
			goto error;

		return parse_array(buffer + 3, length - 3, object,
		    read_uint16(buffer + 1)) + 3;
	case 0xDD:
		if (length < 5)
			goto error;

		return parse_array(buffer + 5, length - 5, object,
		    read_uint32(buffer + 1)) + 5;
	/* Tables */
	case 0xDE:
		if (length < 3)
			goto error;

		return parse_table(buffer + 3, length - 3, object,
		    read_uint16(buffer + 1)) + 3;
	case 0xDF:
		if (length < 5)
			goto error;

		return parse_table(buffer + 5, length - 5, object,
		    read_uint32(buffer + 1)) + 5;
	}

error:
	*object = nil;
	return 0;
}

@implementation OFDataArray (BinaryPackValue)
- (id)binaryPackValue
{
	size_t count = [self count];
	id object;

	if (parse_object([self items], count, &object) != count ||
	    object == nil)
		@throw [OFInvalidFormatException
		    exceptionWithClass: [self class]];

	return object;
}
@end
