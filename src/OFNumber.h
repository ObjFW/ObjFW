/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <unistd.h>

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
	OF_NUMBER_INTMAX,
	OF_NUMBER_UINTMAX,
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
		intmax_t       intmax;
		uintmax_t      uintmax;
		ptrdiff_t      ptrdiff;
		intptr_t       intptr;
		float	       float_;
		double	       double_;
		long double    longdouble;
	} value;
	enum of_number_type type;
}

+ numberWithChar: (char)char_;
+ numberWithShort: (short)short_;
+ numberWithInt: (int)int_;
+ numberWithLong: (long)long_;
+ numberWithUChar: (unsigned char)uchar;
+ numberWithUShort: (unsigned short)ushort;
+ numberWithUInt: (unsigned int)uint;
+ numberWithULong: (unsigned long)ulong;
+ numberWithInt8: (int8_t)int8;
+ numberWithInt16: (int16_t)int16;
+ numberWithInt32: (int32_t)int32;
+ numberWithInt64: (int64_t)int64;
+ numberWithUInt8: (uint8_t)uint8;
+ numberWithUInt16: (uint16_t)uint16;
+ numberWithUInt32: (uint32_t)uint32;
+ numberWithUInt64: (uint64_t)uint64;
+ numberWithSize: (size_t)size;
+ numberWithSSize: (ssize_t)ssize;
+ numberWithIntMax: (intmax_t)intmax;
+ numberWithUIntMax: (uintmax_t)uintmax;
+ numberWithPtrDiff: (ptrdiff_t)ptrdiff;
+ numberWithIntPtr: (intptr_t)intptr;
+ numberWithFloat: (float)float_;
+ numberWithDouble: (double)double_;
+ numberWithLongDouble: (long double)longdouble;

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
- initWithIntMax: (intmax_t)intmax;
- initWithUIntMax: (uintmax_t)uintmax;
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
- (intmax_t)asIntMax;
- (uintmax_t)asUIntMax;
- (ptrdiff_t)asPtrDiff;
- (intptr_t)asIntPtr;
- (float)asFloat;
- (double)asDouble;
- (long double)asLongDouble;
@end
