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

#include "config.h"

#import "OFNumber.h"
#import "OFExceptions.h"

#define RETURN_AS(t)							\
	switch (type) {							\
	case OF_NUMBER_CHAR:						\
		return (t)value.char_;					\
	case OF_NUMBER_SHORT:						\
		return (t)value.short_;					\
	case OF_NUMBER_INT:						\
		return (t)value.int_;					\
	case OF_NUMBER_LONG:						\
		return (t)value.long_;					\
	case OF_NUMBER_UCHAR:						\
		return (t)value.uchar;					\
	case OF_NUMBER_USHORT:						\
		return (t)value.ushort;					\
	case OF_NUMBER_UINT:						\
		return (t)value.uint;					\
	case OF_NUMBER_ULONG:						\
		return (t)value.ulong;					\
	case OF_NUMBER_INT8:						\
		return (t)value.int8;					\
	case OF_NUMBER_INT16:						\
		return (t)value.int16;					\
	case OF_NUMBER_INT32:						\
		return (t)value.int32;					\
	case OF_NUMBER_INT64:						\
		return (t)value.int64;					\
	case OF_NUMBER_UINT8:						\
		return (t)value.uint8;					\
	case OF_NUMBER_UINT16:						\
		return (t)value.uint16;					\
	case OF_NUMBER_UINT32:						\
		return (t)value.uint32;					\
	case OF_NUMBER_UINT64:						\
		return (t)value.uint64;					\
	case OF_NUMBER_SIZE:						\
		return (t)value.size;					\
	case OF_NUMBER_SSIZE:						\
		return (t)value.ssize;					\
	case OF_NUMBER_INTMAX:						\
		return (t)value.intmax;					\
	case OF_NUMBER_UINTMAX:						\
		return (t)value.uintmax;				\
	case OF_NUMBER_PTRDIFF:						\
		return (t)value.ptrdiff;				\
	case OF_NUMBER_INTPTR:						\
		return (t)value.intptr;					\
	case OF_NUMBER_FLOAT:						\
		return (t)value.float_;					\
	case OF_NUMBER_DOUBLE:						\
		return (t)value.double_;				\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}
#define CALCULATE(o)							\
	switch (type) {							\
	case OF_NUMBER_CHAR:						\
		value.char_ o;						\
		break;							\
	case OF_NUMBER_SHORT:						\
		value.short_ o;						\
		break;							\
	case OF_NUMBER_INT:						\
		value.int_ o;						\
		break;							\
	case OF_NUMBER_LONG:						\
		value.long_ o;						\
		break;							\
	case OF_NUMBER_UCHAR:						\
		value.uchar o;						\
		break;							\
	case OF_NUMBER_USHORT:						\
		value.ushort o;						\
		break;							\
	case OF_NUMBER_UINT:						\
		value.uint o;						\
		break;							\
	case OF_NUMBER_ULONG:						\
		value.ulong o;						\
		break;							\
	case OF_NUMBER_INT8:						\
		value.int8 o;						\
		break;							\
	case OF_NUMBER_INT16:						\
		value.int16 o;						\
		break;							\
	case OF_NUMBER_INT32:						\
		value.int32 o;						\
		break;							\
	case OF_NUMBER_INT64:						\
		value.int64 o;						\
		break;							\
	case OF_NUMBER_UINT8:						\
		value.uint8 o;						\
		break;							\
	case OF_NUMBER_UINT16:						\
		value.uint16 o;						\
		break;							\
	case OF_NUMBER_UINT32:						\
		value.uint32 o;						\
		break;							\
	case OF_NUMBER_UINT64:						\
		value.uint64 o;						\
		break;							\
	case OF_NUMBER_SIZE:						\
		value.size o;						\
		break;							\
	case OF_NUMBER_SSIZE:						\
		value.ssize o;						\
		break;							\
	case OF_NUMBER_INTMAX:						\
		value.intmax o;						\
		break;							\
	case OF_NUMBER_UINTMAX:						\
		value.uintmax o;					\
		break;							\
	case OF_NUMBER_PTRDIFF:						\
		value.ptrdiff o;					\
		break;							\
	case OF_NUMBER_INTPTR:						\
		value.intptr o;						\
		break;							\
	case OF_NUMBER_FLOAT:						\
		value.float_ o;						\
		break;							\
	case OF_NUMBER_DOUBLE:						\
		value.double_ o;					\
		break;							\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}
#define CALCULATE2(o, n)						\
	switch ([n type]) { 						\
	case OF_NUMBER_CHAR:						\
		value.char_ o [n asChar];				\
		break;							\
	case OF_NUMBER_SHORT:						\
		value.short_ o [n asShort];				\
		break;							\
	case OF_NUMBER_INT:						\
		value.int_ o [n asInt];					\
		break;							\
	case OF_NUMBER_LONG:						\
		value.long_ o [n asLong];				\
		break;							\
	case OF_NUMBER_UCHAR:						\
		value.uchar o [n asUChar];				\
		break;							\
	case OF_NUMBER_USHORT:						\
		value.ushort o [n asUShort];				\
		break;							\
	case OF_NUMBER_UINT:						\
		value.uint o [n asUInt];				\
		break;							\
	case OF_NUMBER_ULONG:						\
		value.ulong o [n asULong];				\
		break;							\
	case OF_NUMBER_INT8:						\
		value.int8 o [n asInt8];				\
		break;							\
	case OF_NUMBER_INT16:						\
		value.int16 o [n asInt16];				\
		break;							\
	case OF_NUMBER_INT32:						\
		value.int32 o [n asInt32];				\
		break;							\
	case OF_NUMBER_INT64:						\
		value.int64 o [n asInt64];				\
		break;							\
	case OF_NUMBER_UINT8:						\
		value.uint8 o [n asUInt8];				\
		break;							\
	case OF_NUMBER_UINT16:						\
		value.uint16 o [n asUInt16];				\
		break;							\
	case OF_NUMBER_UINT32:						\
		value.uint32 o [n asUInt32];				\
		break;							\
	case OF_NUMBER_UINT64:						\
		value.uint64 o [n asUInt64];				\
		break;							\
	case OF_NUMBER_SIZE:						\
		value.size o [n asSize];				\
		break;							\
	case OF_NUMBER_SSIZE:						\
		value.ssize o [n asSSize];				\
		break;							\
	case OF_NUMBER_INTMAX:						\
		value.intmax o [n asIntMax];				\
		break;							\
	case OF_NUMBER_UINTMAX:						\
		value.uintmax o [n asUIntMax];				\
		break;							\
	case OF_NUMBER_PTRDIFF:						\
		value.ptrdiff o [n asPtrDiff];				\
		break;							\
	case OF_NUMBER_INTPTR:						\
		value.intptr o [n asIntPtr];				\
		break;							\
	case OF_NUMBER_FLOAT:						\
		value.float_ o [n asFloat];				\
		break;							\
	case OF_NUMBER_DOUBLE:						\
		value.double_ o [n asDouble];				\
		break;							\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}

@implementation OFNumber
+ numberWithChar: (char)char_
{
	return [[[self alloc] initWithChar: char_] autorelease];
}

+ numberWithShort: (short)short_
{
	return [[[self alloc] initWithShort: short_] autorelease];
}

+ numberWithInt: (int)int_
{
	return [[[self alloc] initWithInt: int_] autorelease];
}

+ numberWithLong: (long)long_
{
	return [[[self alloc] initWithLong: long_] autorelease];
}

+ numberWithUChar: (unsigned char)uchar
{
	return [[[self alloc] initWithUChar: uchar] autorelease];
}

+ numberWithUShort: (unsigned short)ushort
{
	return [[[self alloc] initWithUShort: ushort] autorelease];
}

+ numberWithUInt: (unsigned int)uint
{
	return [[[self alloc] initWithUInt: uint] autorelease];
}

+ numberWithULong: (unsigned long)ulong
{
	return [[[self alloc] initWithULong: ulong] autorelease];
}

+ numberWithInt8: (int8_t)int8
{
	return [[[self alloc] initWithInt8: int8] autorelease];
}

+ numberWithInt16: (int16_t)int16
{
	return [[[self alloc] initWithInt16: int16] autorelease];
}

+ numberWithInt32: (int32_t)int32
{
	return [[[self alloc] initWithInt32: int32] autorelease];
}

+ numberWithInt64: (int64_t)int64
{
	return [[[self alloc] initWithInt64: int64] autorelease];
}

+ numberWithUInt8: (uint8_t)uint8
{
	return [[[self alloc] initWithUInt8: uint8] autorelease];
}

+ numberWithUInt16: (uint16_t)uint16
{
	return [[[self alloc] initWithUInt16: uint16] autorelease];
}

+ numberWithUInt32: (uint32_t)uint32
{
	return [[[self alloc] initWithUInt32: uint32] autorelease];
}

+ numberWithUInt64: (uint64_t)uint64
{
	return [[[self alloc] initWithUInt64: uint64] autorelease];
}

+ numberWithSize: (size_t)size
{
	return [[[self alloc] initWithSize: size] autorelease];
}

+ numberWithSSize: (ssize_t)ssize
{
	return [[[self alloc] initWithSSize: ssize] autorelease];
}

+ numberWithIntMax: (intmax_t)intmax
{
	return [[[self alloc] initWithIntMax: intmax] autorelease];
}

+ numberWithUIntMax: (uintmax_t)uintmax
{
	return [[[self alloc] initWithIntMax: uintmax] autorelease];
}

+ numberWithPtrDiff: (ptrdiff_t)ptrdiff
{
	return [[[self alloc] initWithPtrDiff: ptrdiff] autorelease];
}

+ numberWithIntPtr: (intptr_t)intptr
{
	return [[[self alloc] initWithIntPtr: intptr] autorelease];
}

+ numberWithFloat: (float)float_
{
	return [[[self alloc] initWithFloat: float_] autorelease];
}

+ numberWithDouble: (double)double_
{
	return [[[self alloc] initWithDouble: double_] autorelease];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithChar: (char)char_
{
	self = [super init];

	value.char_ = char_;
	type = OF_NUMBER_CHAR;

	return self;
}

- initWithShort: (short)short_
{
	self = [super init];

	value.short_ = short_;
	type = OF_NUMBER_SHORT;

	return self;
}

- initWithInt: (int)int_
{
	self = [super init];

	value.int_ = int_;
	type = OF_NUMBER_INT;

	return self;
}

- initWithLong: (long)long_
{
	self = [super init];

	value.long_ = long_;
	type = OF_NUMBER_LONG;

	return self;
}

- initWithUChar: (unsigned char)uchar
{
	self = [super init];

	value.uchar = uchar;
	type = OF_NUMBER_UCHAR;

	return self;
}

- initWithUShort: (unsigned short)ushort
{
	self = [super init];

	value.ushort = ushort;
	type = OF_NUMBER_USHORT;

	return self;
}

- initWithUInt: (unsigned int)uint
{
	self = [super init];

	value.uint = uint;
	type = OF_NUMBER_UINT;

	return self;
}

- initWithULong: (unsigned long)ulong
{
	self = [super init];

	value.ulong = ulong;
	type = OF_NUMBER_ULONG;

	return self;
}

- initWithInt8: (int8_t)int8
{
	self = [super init];

	value.int8 = int8;
	type = OF_NUMBER_INT8;

	return self;
}

- initWithInt16: (int16_t)int16
{
	self = [super init];

	value.int16 = int16;
	type = OF_NUMBER_INT16;

	return self;
}

- initWithInt32: (int32_t)int32
{
	self = [super init];

	value.int32 = int32;
	type = OF_NUMBER_INT32;

	return self;
}

- initWithInt64: (int64_t)int64
{
	self = [super init];

	value.int64 = int64;
	type = OF_NUMBER_INT64;

	return self;
}

- initWithUInt8: (uint8_t)uint8
{
	self = [super init];

	value.uint8 = uint8;
	type = OF_NUMBER_UINT8;

	return self;
}

- initWithUInt16: (uint16_t)uint16
{
	self = [super init];

	value.uint16 = uint16;
	type = OF_NUMBER_UINT16;

	return self;
}

- initWithUInt32: (uint32_t)uint32
{
	self = [super init];

	value.uint32 = uint32;
	type = OF_NUMBER_UINT32;

	return self;
}

- initWithUInt64: (uint64_t)uint64
{
	self = [super init];

	value.uint64 = uint64;
	type = OF_NUMBER_UINT64;

	return self;
}

- initWithSize: (size_t)size
{
	self = [super init];

	value.size = size;
	type = OF_NUMBER_SIZE;

	return self;
}

- initWithSSize: (ssize_t)ssize
{
	self = [super init];

	value.ssize = ssize;
	type = OF_NUMBER_SSIZE;

	return self;
}

- initWithIntMax: (intmax_t)intmax
{
	self = [super init];

	value.intmax = intmax;
	type = OF_NUMBER_INTMAX;

	return self;
}

- initWithUIntMax: (uintmax_t)uintmax
{
	self = [super init];

	value.uintmax = uintmax;
	type = OF_NUMBER_UINTMAX;

	return self;
}

- initWithPtrDiff: (ptrdiff_t)ptrdiff
{
	self = [super init];

	value.ptrdiff = ptrdiff;
	type = OF_NUMBER_PTRDIFF;

	return self;
}

- initWithIntPtr: (intptr_t)intptr
{
	self = [super init];

	value.intptr = intptr;
	type = OF_NUMBER_INTPTR;

	return self;
}

- initWithFloat: (float)float_
{
	self = [super init];

	value.float_ = float_;
	type = OF_NUMBER_FLOAT;

	return self;
}

- initWithDouble: (double)double_
{
	self = [super init];

	value.double_ = double_;
	type = OF_NUMBER_DOUBLE;

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
	if (![obj isKindOfClass: [OFNumber class]])
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
		return ([obj asDouble] == [self asDouble] ? YES : NO);
	default:
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	}
}

- (uint32_t)hash
{
	return [self asUInt32];
}

- add: (OFNumber*)num
{
	CALCULATE2(+=, num)
	return self;
}

- subtract: (OFNumber*)num
{
	CALCULATE2(-=, num)
	return self;
}

- multiplyWith: (OFNumber*)num
{
	CALCULATE2(*=, num)
	return self;
}

- divideBy: (OFNumber*)num
{
	CALCULATE2(/=, num)
	return self;
}

- increase
{
	CALCULATE(++)
	return self;
}

- decrease
{
	CALCULATE(--)
	return self;
}
@end
