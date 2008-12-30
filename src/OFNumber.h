/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

enum of_number_type {
	OF_NUMBER_CHAR,
	OF_NUMBER_SHORT,
	OF_NUMBER_INT,
	OF_NUMBER_LONG,
	OF_NUMBER_UCHAR,
	OF_NUMBER_USHORT,
	OF_NUMBER_UINT,
	OF_NUMBER_ULONG,
	OF_NUMBER_INT8,
	OF_NUMBER_INT16,
	OF_NUMBER_INT32,
	OF_NUMBER_INT64,
	OF_NUMBER_UINT8,
	OF_NUMBER_UINT16,
	OF_NUMBER_UINT32,
	OF_NUMBER_UINT64,
	OF_NUMBER_SIZE,
	OF_NUMBER_SSIZE,
	OF_NUMBER_PTRDIFF,
	OF_NUMBER_INTPTR,
	OF_NUMBER_FLOAT,
	OF_NUMBER_DOUBLE,
	OF_NUMBER_LONG_DOUBLE
};

/**
 * The OFNumber class provides a way to store a number in an object and
 * manipulate it.
 */
@interface OFNumber: OFObject
{
	union {
		char	       char_;
		short	       short_;
		int	       int_;
		long	       long_;
		unsigned char  uchar;
		unsigned short ushort;
		unsigned int   uint;
		unsigned long  ulong;
		int8_t	       int8;
		int16_t	       int16;
		int32_t	       int32;
		int64_t	       int64;
		uint8_t	       uint8;
		uint16_t       uint16;
		uint32_t       uint32;
		uint64_t       uint64;
		size_t	       size;
		ssize_t	       ssize;
		ptrdiff_t      ptrdiff;
		intptr_t       intptr;
		float	       float_;
		double	       double_;
		long double    longdouble;
	} value;
	enum of_number_type type;
}

+ newWithChar: (char)char_;
+ newWithShort: (short)short_;
+ newWithInt: (int)int_;
+ newWithLong: (long)long_;
+ newWithUChar: (unsigned char)uchar;
+ newWithUShort: (unsigned short)ushort;
+ newWithUInt: (unsigned int)uint;
+ newWithULong: (unsigned long)ulong;
+ newWithInt8: (int8_t)int8;
+ newWithInt16: (int16_t)int16;
+ newWithInt32: (int32_t)int32;
+ newWithInt64: (int64_t)int64;
+ newWithUInt8: (uint8_t)uint8;
+ newWithUInt16: (uint16_t)uint16;
+ newWithUInt32: (uint32_t)uint32;
+ newWithUInt64: (uint64_t)uint64;
+ newWithSize: (size_t)size;
+ newWithSSize: (ssize_t)ssize;
+ newWithPtrDiff: (ptrdiff_t)ptrdiff;
+ newWithIntPtr: (intptr_t)intptr;
+ newWithFloat: (float)float_;
+ newWithDouble: (double)double_;
+ newWithLongDouble: (long double)longdouble;

- initWithChar: (char)char_;
- initWithShort: (short)short_;
- initWithInt: (int)int_;
- initWithLong: (long)long_;
- initWithUChar: (unsigned char)uchar;
- initWithUShort: (unsigned short)ushort;
- initWithUInt: (unsigned int)uint;
- initWithULong: (unsigned long)ulong;
- initWithInt8: (int8_t)int8;
- initWithInt16: (int16_t)int16;
- initWithInt32: (int32_t)int32;
- initWithInt64: (int64_t)int64;
- initWithUInt8: (uint8_t)uint8;
- initWithUInt16: (uint16_t)uint16;
- initWithUInt32: (uint32_t)uint32;
- initWithUInt64: (uint64_t)uint64;
- initWithSize: (size_t)size;
- initWithSSize: (ssize_t)ssize;
- initWithPtrDiff: (ptrdiff_t)ptrdiff;
- initWithIntPtr: (intptr_t)intptr;
- initWithFloat: (float)float_;
- initWithDouble: (double)double_;
- initWithLongDouble: (long double)longdouble;

- (enum of_number_type)type;

- (char)asChar;
- (short)asShort;
- (int)asInt;
- (long)asLong;
- (unsigned char)asUChar;
- (unsigned short)asUShort;
- (unsigned int)asUInt;
- (unsigned long)asULong;
- (int8_t)asInt8;
- (int16_t)asInt16;
- (int32_t)asInt32;
- (int64_t)asInt64;
- (uint8_t)asUInt8;
- (uint16_t)asUInt16;
- (uint32_t)asUInt32;
- (uint64_t)asUInt64;
- (size_t)asSize;
- (ssize_t)asSSize;
- (ptrdiff_t)asPtrDiff;
- (intptr_t)asIntPtr;
- (float)asFloat;
- (double)asDouble;
- (long double)asLongDouble;
@end
