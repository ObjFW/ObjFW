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

#import "config.h"

#import "OFNumber.h"
#import "OFExceptions.h"

#define RETURN_AS(t)							      \
	switch (type) {							      \
	case OF_NUMBER_CHAR:						      \
		return (t)value.char_;					      \
	case OF_NUMBER_SHORT:						      \
		return (t)value.short_;					      \
	case OF_NUMBER_INT:						      \
		return (t)value.int_;					      \
	case OF_NUMBER_LONG:						      \
		return (t)value.long_;					      \
	case OF_NUMBER_UCHAR:						      \
		return (t)value.uchar;					      \
	case OF_NUMBER_USHORT:						      \
		return (t)value.ushort;					      \
	case OF_NUMBER_UINT:						      \
		return (t)value.uint;					      \
	case OF_NUMBER_ULONG:						      \
		return (t)value.ulong;					      \
	case OF_NUMBER_INT8:						      \
		return (t)value.int8;					      \
	case OF_NUMBER_INT16:						      \
		return (t)value.int16;					      \
	case OF_NUMBER_INT32:						      \
		return (t)value.int32;					      \
	case OF_NUMBER_INT64:						      \
		return (t)value.int64;					      \
	case OF_NUMBER_UINT8:						      \
		return (t)value.uint8;					      \
	case OF_NUMBER_UINT16:						      \
		return (t)value.uint16;					      \
	case OF_NUMBER_UINT32:						      \
		return (t)value.uint32;					      \
	case OF_NUMBER_UINT64:						      \
		return (t)value.uint64;					      \
	case OF_NUMBER_SIZE:						      \
		return (t)value.size;					      \
	case OF_NUMBER_SSIZE:						      \
		return (t)value.ssize;					      \
	case OF_NUMBER_INTMAX:						      \
		return (t)value.intmax;					      \
	case OF_NUMBER_UINTMAX:						      \
		return (t)value.uintmax;				      \
	case OF_NUMBER_PTRDIFF:						      \
		return (t)value.ptrdiff;				      \
	case OF_NUMBER_INTPTR:						      \
		return (t)value.intptr;					      \
	case OF_NUMBER_FLOAT:						      \
		return (t)value.float_;					      \
	case OF_NUMBER_DOUBLE:						      \
		return (t)value.double_;				      \
	case OF_NUMBER_LONG_DOUBLE:					      \
		return (t)value.longdouble;				      \
	default:							      \
		@throw [OFInvalidFormatException newWithClass: [self class]]; \
									      \
		/* Make gcc happy */					      \
		return 0;						      \
	}

@implementation OFNumber
+ numberWithChar: (char)char_
{
	return [[[OFNumber alloc] initWithChar: char_] autorelease];
}

+ numberWithShort: (short)short_
{
	return [[[OFNumber alloc] initWithShort: short_] autorelease];
}

+ numberWithInt: (int)int_
{
	return [[[OFNumber alloc] initWithInt: int_] autorelease];
}

+ numberWithLong: (long)long_
{
	return [[[OFNumber alloc] initWithLong: long_] autorelease];
}

+ numberWithUChar: (unsigned char)uchar
{
	return [[[OFNumber alloc] initWithUChar: uchar] autorelease];
}

+ numberWithUShort: (unsigned short)ushort
{
	return [[[OFNumber alloc] initWithUShort: ushort] autorelease];
}

+ numberWithUInt: (unsigned int)uint
{
	return [[[OFNumber alloc] initWithUInt: uint] autorelease];
}

+ numberWithULong: (unsigned long)ulong
{
	return [[[OFNumber alloc] initWithULong: ulong] autorelease];
}

+ numberWithInt8: (int8_t)int8
{
	return [[[OFNumber alloc] initWithInt8: int8] autorelease];
}

+ numberWithInt16: (int16_t)int16
{
	return [[[OFNumber alloc] initWithInt16: int16] autorelease];
}

+ numberWithInt32: (int32_t)int32
{
	return [[[OFNumber alloc] initWithInt32: int32] autorelease];
}

+ numberWithInt64: (int64_t)int64
{
	return [[[OFNumber alloc] initWithInt64: int64] autorelease];
}

+ numberWithUInt8: (uint8_t)uint8
{
	return [[[OFNumber alloc] initWithUInt8: uint8] autorelease];
}

+ numberWithUInt16: (uint16_t)uint16
{
	return [[[OFNumber alloc] initWithUInt16: uint16] autorelease];
}

+ numberWithUInt32: (uint32_t)uint32
{
	return [[[OFNumber alloc] initWithUInt32: uint32] autorelease];
}

+ numberWithUInt64: (uint64_t)uint64
{
	return [[[OFNumber alloc] initWithUInt64: uint64] autorelease];
}

+ numberWithSize: (size_t)size
{
	return [[[OFNumber alloc] initWithSize: size] autorelease];
}

+ numberWithSSize: (ssize_t)ssize
{
	return [[[OFNumber alloc] initWithSSize: ssize] autorelease];
}

+ numberWithIntMax: (intmax_t)intmax
{
	return [[[OFNumber alloc] initWithIntMax: intmax] autorelease];
}

+ numberWithUIntMax: (uintmax_t)uintmax
{
	return [[[OFNumber alloc] initWithIntMax: uintmax] autorelease];
}

+ numberWithPtrDiff: (ptrdiff_t)ptrdiff
{
	return [[[OFNumber alloc] initWithPtrDiff: ptrdiff] autorelease];
}

+ numberWithIntPtr: (intptr_t)intptr
{
	return [[[OFNumber alloc] initWithIntPtr: intptr] autorelease];
}

+ numberWithFloat: (float)float_
{
	return [[[OFNumber alloc] initWithFloat: float_] autorelease];
}

+ numberWithDouble: (double)double_
{
	return [[[OFNumber alloc] initWithDouble: double_] autorelease];
}

+ numberWithLongDouble: (long double)longdouble
{
	return [[[OFNumber alloc] initWithLongDouble: longdouble] autorelease];
}

- initWithChar: (char)char_
{
	if ((self = [super init])) {
		value.char_ = char_;
		type = OF_NUMBER_CHAR;
	}

	return self;
}

- initWithShort: (short)short_
{
	if ((self = [super init])) {
		value.short_ = short_;
		type = OF_NUMBER_SHORT;
	}

	return self;
}

- initWithInt: (int)int_
{
	if ((self = [super init])) {
		value.int_ = int_;
		type = OF_NUMBER_INT;
	}

	return self;
}

- initWithLong: (long)long_
{
	if ((self = [super init])) {
		value.long_ = long_;
		type = OF_NUMBER_LONG;
	}

	return self;
}

- initWithUChar: (unsigned char)uchar
{
	if ((self = [super init])) {
		value.uchar = uchar;
		type = OF_NUMBER_UCHAR;
	}

	return self;
}

- initWithUShort: (unsigned short)ushort
{
	if ((self = [super init])) {
		value.ushort = ushort;
		type = OF_NUMBER_USHORT;
	}

	return self;
}

- initWithUInt: (unsigned int)uint
{
	if ((self = [super init])) {
		value.uint = uint;
		type = OF_NUMBER_UINT;
	}

	return self;
}

- initWithULong: (unsigned long)ulong
{
	if ((self = [super init])) {
		value.ulong = ulong;
		type = OF_NUMBER_ULONG;
	}

	return self;
}

- initWithInt8: (int8_t)int8
{
	if ((self = [super init])) {
		value.int8 = int8;
		type = OF_NUMBER_INT8;
	}

	return self;
}

- initWithInt16: (int16_t)int16
{
	if ((self = [super init])) {
		value.int16 = int16;
		type = OF_NUMBER_INT16;
	}

	return self;
}

- initWithInt32: (int32_t)int32
{
	if ((self = [super init])) {
		value.int32 = int32;
		type = OF_NUMBER_INT32;
	}

	return self;
}

- initWithInt64: (int64_t)int64
{
	if ((self = [super init])) {
		value.int64 = int64;
		type = OF_NUMBER_INT64;
	}

	return self;
}

- initWithUInt8: (uint8_t)uint8
{
	if ((self = [super init])) {
		value.uint8 = uint8;
		type = OF_NUMBER_UINT8;
	}

	return self;
}

- initWithUInt16: (uint16_t)uint16
{
	if ((self = [super init])) {
		value.uint16 = uint16;
		type = OF_NUMBER_UINT16;
	}

	return self;
}

- initWithUInt32: (uint32_t)uint32
{
	if ((self = [super init])) {
		value.uint32 = uint32;
		type = OF_NUMBER_UINT32;
	}

	return self;
}

- initWithUInt64: (uint64_t)uint64
{
	if ((self = [super init])) {
		value.uint64 = uint64;
		type = OF_NUMBER_UINT64;
	}

	return self;
}

- initWithSize: (size_t)size
{
	if ((self = [super init])) {
		value.size = size;
		type = OF_NUMBER_SIZE;
	}

	return self;
}

- initWithSSize: (ssize_t)ssize
{
	if ((self = [super init])) {
		value.ssize = ssize;
		type = OF_NUMBER_SSIZE;
	}

	return self;
}

- initWithIntMax: (intmax_t)intmax
{
	if ((self = [super init])) {
		value.intmax = intmax;
		type = OF_NUMBER_INTMAX;
	}

	return self;
}

- initWithUIntMax: (uintmax_t)uintmax
{
	if ((self = [super init])) {
		value.uintmax = uintmax;
		type = OF_NUMBER_UINTMAX;
	}

	return self;
}

- initWithPtrDiff: (ptrdiff_t)ptrdiff
{
	if ((self = [super init])) {
		value.ptrdiff = ptrdiff;
		type = OF_NUMBER_PTRDIFF;
	}

	return self;
}

- initWithIntPtr: (intptr_t)intptr
{
	if ((self = [super init])) {
		value.intptr = intptr;
		type = OF_NUMBER_INTPTR;
	}

	return self;
}

- initWithFloat: (float)float_
{
	if ((self = [super init])) {
		value.float_ = float_;
		type = OF_NUMBER_FLOAT;
	}

	return self;
}

- initWithDouble: (double)double_
{
	if ((self = [super init])) {
		value.double_ = double_;
		type = OF_NUMBER_DOUBLE;
	}

	return self;
}

- initWithLongDouble: (long double)longdouble
{
	if ((self = [super init])) {
		value.longdouble = longdouble;
		type = OF_NUMBER_LONG_DOUBLE;
	}

	return self;
}

- (enum of_number_type)type
{
	return type;
}

- (char)asChar
{
	RETURN_AS(char)
}

- (short)asShort
{
	RETURN_AS(short)
}

- (int)asInt
{
	RETURN_AS(int)
}

- (long)asLong
{
	RETURN_AS(long)
}

- (unsigned char)asUChar
{
	RETURN_AS(unsigned char)
}

- (unsigned short)asUShort
{
	RETURN_AS(unsigned short)
}

- (unsigned int)asUInt
{
	RETURN_AS(unsigned int)
}

- (unsigned long)asULong
{
	RETURN_AS(unsigned long)
}

- (int8_t)asInt8
{
	RETURN_AS(int8_t)
}

- (int16_t)asInt16
{
	RETURN_AS(int16_t)
}

- (int32_t)asInt32
{
	RETURN_AS(int32_t)
}

- (int64_t)asInt64
{
	RETURN_AS(int64_t)
}

- (uint8_t)asUInt8
{
	RETURN_AS(uint8_t)
}

- (uint16_t)asUInt16
{
	RETURN_AS(uint16_t)
}

- (uint32_t)asUInt32
{
	RETURN_AS(uint32_t)
}

- (uint64_t)asUInt64
{
	RETURN_AS(uint64_t)
}

- (size_t)asSize
{
	RETURN_AS(size_t)
}

- (ssize_t)asSSize
{
	RETURN_AS(ssize_t)
}

- (intmax_t)asIntMax
{
	RETURN_AS(intmax_t)
}

- (uintmax_t)asUIntMax
{
	RETURN_AS(uintmax_t)
}

- (ptrdiff_t)asPtrDiff
{
	RETURN_AS(ptrdiff_t)
}

- (intptr_t)asIntPtr
{
	RETURN_AS(intptr_t)
}

- (float)asFloat
{
	RETURN_AS(float)
}

- (double)asDouble
{
	RETURN_AS(double)
}

- (long double)asLongDouble
{
	RETURN_AS(long double)
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFNumber class]])
		return NO;

	switch (type) {
	case OF_NUMBER_CHAR:
	case OF_NUMBER_SHORT:
	case OF_NUMBER_INT:
	case OF_NUMBER_LONG:
	case OF_NUMBER_INT8:
	case OF_NUMBER_INT16:
	case OF_NUMBER_INT32:
	case OF_NUMBER_INT64:
	case OF_NUMBER_INTMAX:
	case OF_NUMBER_PTRDIFF:
		return ([obj asIntMax] == [self asIntMax] ? YES : NO);
	case OF_NUMBER_SSIZE:
	case OF_NUMBER_UCHAR:
	case OF_NUMBER_USHORT:
	case OF_NUMBER_UINT:
	case OF_NUMBER_ULONG:
	case OF_NUMBER_UINT8:
	case OF_NUMBER_UINT16:
	case OF_NUMBER_UINT32:
	case OF_NUMBER_UINT64:
	case OF_NUMBER_SIZE:
	case OF_NUMBER_UINTMAX:
	case OF_NUMBER_INTPTR:
		return ([obj asUIntMax] == [self asUIntMax] ? YES : NO);
	case OF_NUMBER_FLOAT:
	case OF_NUMBER_DOUBLE:
	case OF_NUMBER_LONG_DOUBLE:
		return ([obj asLongDouble] == [self asLongDouble] ? YES : NO);
	default:
		@throw [OFInvalidArgumentException newWithClass: [self class]
						    andSelector: _cmd];
	}
}

- (uint32_t)hash
{
	return [self asUInt32];
}
@end
