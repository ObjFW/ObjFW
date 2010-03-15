/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFNumber.h"
#import "OFExceptions.h"
#import "macros.h"

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
	case OF_NUMBER_UINTPTR:						\
		return (t)value.uintptr;				\
	case OF_NUMBER_FLOAT:						\
		return (t)value.float_;					\
	case OF_NUMBER_DOUBLE:						\
		return (t)value.double_;				\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}
#define CALCULATE(o, n)							\
	switch (type) { 						\
	case OF_NUMBER_CHAR:						\
		return [OFNumber numberWithChar:			\
		    value.char_ o [n asChar]];				\
	case OF_NUMBER_SHORT:						\
		return [OFNumber numberWithShort:			\
		    value.short_ o [n asShort]];			\
	case OF_NUMBER_INT:						\
		return [OFNumber numberWithInt:				\
		    value.int_ o [n asInt]];				\
	case OF_NUMBER_LONG:						\
		return [OFNumber numberWithLong:			\
		    value.long_ o [n asLong]];				\
	case OF_NUMBER_UCHAR:						\
		return [OFNumber numberWithUChar:			\
		    value.uchar o [n asUChar]];				\
	case OF_NUMBER_USHORT:						\
		return [OFNumber numberWithUShort:			\
		    value.ushort o [n asUShort]];			\
	case OF_NUMBER_UINT:						\
		return [OFNumber numberWithUInt:			\
		    value.uint o [n asUInt]];				\
	case OF_NUMBER_ULONG:						\
		return [OFNumber numberWithULong:			\
		    value.ulong o [n asULong]];				\
	case OF_NUMBER_INT8:						\
		return [OFNumber numberWithInt8:			\
		    value.int8 o [n asInt8]];				\
	case OF_NUMBER_INT16:						\
		return [OFNumber numberWithInt16:			\
		    value.int16 o [n asInt16]];				\
	case OF_NUMBER_INT32:						\
		return [OFNumber numberWithInt32:			\
		    value.int32 o [n asInt32]];				\
	case OF_NUMBER_INT64:						\
		return [OFNumber numberWithInt64:			\
		    value.int64 o [n asInt64]];				\
	case OF_NUMBER_UINT8:						\
		return [OFNumber numberWithUInt8:			\
		    value.uint8 o [n asUInt8]];				\
	case OF_NUMBER_UINT16:						\
		return [OFNumber numberWithUInt16:			\
		    value.uint16 o [n asUInt16]];			\
	case OF_NUMBER_UINT32:						\
		return [OFNumber numberWithUInt32:			\
		    value.uint32 o [n asUInt32]];			\
	case OF_NUMBER_UINT64:						\
		return [OFNumber numberWithUInt64:			\
		    value.uint64 o [n asUInt64]];			\
	case OF_NUMBER_SIZE:						\
		return [OFNumber numberWithSize:			\
		    value.size o [n asSize]];				\
	case OF_NUMBER_SSIZE:						\
		return [OFNumber numberWithSSize:			\
		    value.ssize o [n asSSize]];				\
	case OF_NUMBER_INTMAX:						\
		return [OFNumber numberWithIntMax:			\
		    value.intmax o [n asIntMax]];			\
	case OF_NUMBER_UINTMAX:						\
		return [OFNumber numberWithUIntMax:			\
		    value.uintmax o [n asUIntMax]];			\
	case OF_NUMBER_PTRDIFF:						\
		return [OFNumber numberWithPtrDiff:			\
		    value.ptrdiff o [n asPtrDiff]];			\
	case OF_NUMBER_INTPTR:						\
		return [OFNumber numberWithIntPtr:			\
		    value.intptr o [n asIntPtr]];			\
	case OF_NUMBER_UINTPTR:						\
		return [OFNumber numberWithUIntPtr:			\
		    value.uintptr o [n asUIntPtr]];			\
	case OF_NUMBER_FLOAT:						\
		return [OFNumber numberWithFloat:			\
		    value.float_ o [n asFloat]];			\
	case OF_NUMBER_DOUBLE:						\
		return [OFNumber numberWithDouble:			\
		    value.double_ o [n asDouble]];			\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}
#define CALCULATE2(o, n)						\
	switch (type) { 						\
	case OF_NUMBER_CHAR:						\
		return [OFNumber numberWithChar:			\
		    value.char_ o [n asChar]];				\
	case OF_NUMBER_SHORT:						\
		return [OFNumber numberWithShort:			\
		    value.short_ o [n asShort]];			\
	case OF_NUMBER_INT:						\
		return [OFNumber numberWithInt:				\
		    value.int_ o [n asInt]];				\
	case OF_NUMBER_LONG:						\
		return [OFNumber numberWithLong:			\
		    value.long_ o [n asLong]];				\
	case OF_NUMBER_UCHAR:						\
		return [OFNumber numberWithUChar:			\
		    value.uchar o [n asUChar]];				\
	case OF_NUMBER_USHORT:						\
		return [OFNumber numberWithUShort:			\
		    value.ushort o [n asUShort]];			\
	case OF_NUMBER_UINT:						\
		return [OFNumber numberWithUInt:			\
		    value.uint o [n asUInt]];				\
	case OF_NUMBER_ULONG:						\
		return [OFNumber numberWithULong:			\
		    value.ulong o [n asULong]];				\
	case OF_NUMBER_INT8:						\
		return [OFNumber numberWithInt8:			\
		    value.int8 o [n asInt8]];				\
	case OF_NUMBER_INT16:						\
		return [OFNumber numberWithInt16:			\
		    value.int16 o [n asInt16]];				\
	case OF_NUMBER_INT32:						\
		return [OFNumber numberWithInt32:			\
		    value.int32 o [n asInt32]];				\
	case OF_NUMBER_INT64:						\
		return [OFNumber numberWithInt64:			\
		    value.int64 o [n asInt64]];				\
	case OF_NUMBER_UINT8:						\
		return [OFNumber numberWithUInt8:			\
		    value.uint8 o [n asUInt8]];				\
	case OF_NUMBER_UINT16:						\
		return [OFNumber numberWithUInt16:			\
		    value.uint16 o [n asUInt16]];			\
	case OF_NUMBER_UINT32:						\
		return [OFNumber numberWithUInt32:			\
		    value.uint32 o [n asUInt32]];			\
	case OF_NUMBER_UINT64:						\
		return [OFNumber numberWithUInt64:			\
		    value.uint64 o [n asUInt64]];			\
	case OF_NUMBER_SIZE:						\
		return [OFNumber numberWithSize:			\
		    value.size o [n asSize]];				\
	case OF_NUMBER_SSIZE:						\
		return [OFNumber numberWithSSize:			\
		    value.ssize o [n asSSize]];				\
	case OF_NUMBER_INTMAX:						\
		return [OFNumber numberWithIntMax:			\
		    value.intmax o [n asIntMax]];			\
	case OF_NUMBER_UINTMAX:						\
		return [OFNumber numberWithUIntMax:			\
		    value.uintmax o [n asUIntMax]];			\
	case OF_NUMBER_PTRDIFF:						\
		return [OFNumber numberWithPtrDiff:			\
		    value.ptrdiff o [n asPtrDiff]];			\
	case OF_NUMBER_INTPTR:						\
		return [OFNumber numberWithIntPtr:			\
		    value.intptr o [n asIntPtr]];			\
	case OF_NUMBER_UINTPTR:						\
		return [OFNumber numberWithUIntPtr:			\
		    value.uintptr o [n asUIntPtr]];			\
	case OF_NUMBER_FLOAT:						\
	case OF_NUMBER_DOUBLE:						\
		@throw [OFNotImplementedException newWithClass: isa	\
						      selector: _cmd];	\
	default:							\
		@throw [OFInvalidFormatException newWithClass: isa];	\
	}
#define CALCULATE3(o)							\
	switch (type) {							\
	case OF_NUMBER_CHAR:						\
		return [OFNumber numberWithChar: value.char_ o];	\
	case OF_NUMBER_SHORT:						\
		return [OFNumber numberWithShort: value.short_ o];	\
	case OF_NUMBER_INT:						\
		return [OFNumber numberWithInt: value.int_ o];		\
	case OF_NUMBER_LONG:						\
		return [OFNumber numberWithLong: value.long_ o];	\
	case OF_NUMBER_UCHAR:						\
		return [OFNumber numberWithUChar: value.uchar o];	\
	case OF_NUMBER_USHORT:						\
		return [OFNumber numberWithUShort: value.ushort o];	\
	case OF_NUMBER_UINT:						\
		return [OFNumber numberWithUInt: value.uint o];		\
	case OF_NUMBER_ULONG:						\
		return [OFNumber numberWithULong: value.ulong o];	\
	case OF_NUMBER_INT8:						\
		return [OFNumber numberWithInt8: value.int8 o];		\
	case OF_NUMBER_INT16:						\
		return [OFNumber numberWithInt16: value.int16 o];	\
	case OF_NUMBER_INT32:						\
		return [OFNumber numberWithInt32: value.int32 o];	\
	case OF_NUMBER_INT64:						\
		return [OFNumber numberWithInt64: value.int64 o];	\
	case OF_NUMBER_UINT8:						\
		return [OFNumber numberWithUInt8: value.uint8 o];	\
	case OF_NUMBER_UINT16:						\
		return [OFNumber numberWithUInt16: value.uint16 o];	\
	case OF_NUMBER_UINT32:						\
		return [OFNumber numberWithUInt32: value.uint32 o];	\
	case OF_NUMBER_UINT64:						\
		return [OFNumber numberWithUInt64: value.uint64 o];	\
	case OF_NUMBER_SIZE:						\
		return [OFNumber numberWithSize: value.size o];		\
	case OF_NUMBER_SSIZE:						\
		return [OFNumber numberWithSSize: value.ssize o];	\
	case OF_NUMBER_INTMAX:						\
		return [OFNumber numberWithIntMax: value.intmax o];	\
	case OF_NUMBER_UINTMAX:						\
		return [OFNumber numberWithUIntMax: value.uintmax o];	\
	case OF_NUMBER_PTRDIFF:						\
		return [OFNumber numberWithPtrDiff: value.ptrdiff o];	\
	case OF_NUMBER_INTPTR:						\
		return [OFNumber numberWithIntPtr: value.intptr o];	\
	case OF_NUMBER_UINTPTR:						\
		return [OFNumber numberWithUIntPtr: value.uintptr o];	\
	case OF_NUMBER_FLOAT:						\
		return [OFNumber numberWithFloat: value.float_ o];	\
	case OF_NUMBER_DOUBLE:						\
		return [OFNumber numberWithDouble: value.double_ o];	\
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

+ numberWithUIntPtr: (uintptr_t)uintptr
{
	return [[[self alloc] initWithUIntPtr: uintptr] autorelease];
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

- initWithUIntPtr: (uintptr_t)uintptr
{
	self = [super init];

	value.uintptr = uintptr;
	type = OF_NUMBER_UINTPTR;

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

- (uintptr_t)asUIntPtr
{
	RETURN_AS(uintptr_t)
}

- (float)asFloat
{
	RETURN_AS(float)
}

- (double)asDouble
{
	RETURN_AS(double)
}

- (BOOL)isEqual: (OFObject*)obj
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
		return ([(OFNumber*)obj asIntMax] == [self asIntMax]
		    ? YES : NO);
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
	case OF_NUMBER_UINTPTR:
		return ([(OFNumber*)obj asUIntMax] == [self asUIntMax]
		    ? YES : NO);
	case OF_NUMBER_FLOAT:
	case OF_NUMBER_DOUBLE:
		return ([(OFNumber*)obj asDouble] == [self asDouble]
		    ? YES : NO);
	default:
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	}
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	switch (type) {
	case OF_NUMBER_FLOAT:
		OF_HASH_INIT(hash);
		for (i = 0; i < sizeof(float); i++)
			OF_HASH_ADD(hash, ((char*)&value.float_)[i]);
		OF_HASH_FINALIZE(hash);

		return hash;
	case OF_NUMBER_DOUBLE:
		OF_HASH_INIT(hash);
		for (i = 0; i < sizeof(double); i++)
			OF_HASH_ADD(hash, ((char*)&value.double_)[i]);
		OF_HASH_FINALIZE(hash);

		return hash;
	default:
		return [self asUInt32];
	}
}

- add: (OFNumber*)num
{
	CALCULATE(+, num)
}

- subtract: (OFNumber*)num
{
	CALCULATE(-, num)
}

- multiplyWith: (OFNumber*)num
{
	CALCULATE(*, num)
}

- divideBy: (OFNumber*)num
{
	CALCULATE(/, num)
}

- and: (OFNumber*)num
{
	CALCULATE2(&, num)
}

- or: (OFNumber*)num
{
	CALCULATE2(|, num)
}

- xor: (OFNumber*)num
{
	CALCULATE2(^, num)
}

- shiftLeft: (OFNumber*)num
{
	CALCULATE2(<<, num)
}

- shiftRight: (OFNumber*)num
{
	CALCULATE2(>>, num)
}

- increase
{
	CALCULATE3(+ 1)
}

- decrease
{
	CALCULATE3(- 1)
}
@end
