/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#define OF_NUMBER_M

#include "config.h"

#include <math.h>

#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFXMLAttribute.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#define RETURN_AS(t)							\
	switch (_type) {						\
	case OF_NUMBER_TYPE_BOOL:					\
		return (t)_value.bool_;					\
	case OF_NUMBER_TYPE_CHAR:					\
		return (t)_value.sChar;					\
	case OF_NUMBER_TYPE_SHORT:					\
		return (t)_value.sShort;				\
	case OF_NUMBER_TYPE_INT:					\
		return (t)_value.sInt;					\
	case OF_NUMBER_TYPE_LONG:					\
		return (t)_value.sLong;					\
	case OF_NUMBER_TYPE_LONGLONG:					\
		return (t)_value.sLongLong;				\
	case OF_NUMBER_TYPE_UCHAR:					\
		return (t)_value.uChar;					\
	case OF_NUMBER_TYPE_USHORT:					\
		return (t)_value.uShort;				\
	case OF_NUMBER_TYPE_UINT:					\
		return (t)_value.uInt;					\
	case OF_NUMBER_TYPE_ULONG:					\
		return (t)_value.uLong;					\
	case OF_NUMBER_TYPE_ULONGLONG:					\
		return (t)_value.uLongLong;				\
	case OF_NUMBER_TYPE_INT8:					\
		return (t)_value.int8;					\
	case OF_NUMBER_TYPE_INT16:					\
		return (t)_value.int16;					\
	case OF_NUMBER_TYPE_INT32:					\
		return (t)_value.int32;					\
	case OF_NUMBER_TYPE_INT64:					\
		return (t)_value.int64;					\
	case OF_NUMBER_TYPE_UINT8:					\
		return (t)_value.uInt8;					\
	case OF_NUMBER_TYPE_UINT16:					\
		return (t)_value.uInt16;				\
	case OF_NUMBER_TYPE_UINT32:					\
		return (t)_value.uInt32;				\
	case OF_NUMBER_TYPE_UINT64:					\
		return (t)_value.uInt64;				\
	case OF_NUMBER_TYPE_SIZE:					\
		return (t)_value.size;					\
	case OF_NUMBER_TYPE_SSIZE:					\
		return (t)_value.sSize;					\
	case OF_NUMBER_TYPE_INTMAX:					\
		return (t)_value.intMax;				\
	case OF_NUMBER_TYPE_UINTMAX:					\
		return (t)_value.uIntMax;				\
	case OF_NUMBER_TYPE_PTRDIFF:					\
		return (t)_value.ptrDiff;				\
	case OF_NUMBER_TYPE_INTPTR:					\
		return (t)_value.intPtr;				\
	case OF_NUMBER_TYPE_UINTPTR:					\
		return (t)_value.uIntPtr;				\
	case OF_NUMBER_TYPE_FLOAT:					\
		return (t)_value.float_;				\
	case OF_NUMBER_TYPE_DOUBLE:					\
		return (t)_value.double_;				\
	default:							\
		@throw [OFInvalidFormatException exception];		\
	}

static struct {
	Class isa;
} placeholder;

@interface OFNumber ()
+ (instancetype)of_alloc;
- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth;
@end

@interface OFNumberPlaceholder: OFNumber
@end

@implementation OFNumberPlaceholder
- (instancetype)initWithBool: (bool)bool_
{
	return (id)[[OFNumber of_alloc] initWithBool: bool_];
}

- (instancetype)initWithChar: (signed char)sChar
{
	if (sChar >= 0)
		return (id)[[OFNumber of_alloc] initWithUnsignedChar: sChar];

	return (id)[[OFNumber of_alloc] initWithChar: sChar];
}

- (instancetype)initWithShort: (short)sShort
{
	if (sShort >= 0)
		return (id)[[OFNumber of_alloc] initWithUnsignedShort: sShort];
	if (sShort >= SCHAR_MIN)
		return (id)[[OFNumber of_alloc]
		    initWithChar: (signed char)sShort];

	return (id)[[OFNumber of_alloc] initWithShort: sShort];
}

- (instancetype)initWithInt: (int)sInt
{
	if (sInt >= 0)
		return (id)[[OFNumber of_alloc] initWithUnsignedInt: sInt];
	if (sInt >= SHRT_MIN)
		return (id)[[OFNumber of_alloc] initWithShort: (short)sInt];

	return (id)[[OFNumber of_alloc] initWithInt: sInt];
}

- (instancetype)initWithLong: (long)sLong
{
	if (sLong >= 0)
		return (id)[[OFNumber of_alloc] initWithUnsignedLong: sLong];
	if (sLong >= INT_MIN)
		return (id)[[OFNumber of_alloc] initWithShort: (int)sLong];

	return (id)[[OFNumber of_alloc] initWithLong: sLong];
}

- (instancetype)initWithLongLong: (long long)sLongLong
{
	if (sLongLong >= 0)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedLongLong: sLongLong];
	if (sLongLong >= LONG_MIN)
		return (id)[[OFNumber of_alloc] initWithLong: (long)sLongLong];

	return (id)[[OFNumber of_alloc] initWithLongLong: sLongLong];
}

- (instancetype)initWithUnsignedChar: (unsigned char)uChar
{
	return (id)[[OFNumber of_alloc] initWithUnsignedChar: uChar];
}

- (instancetype)initWithUnsignedShort: (unsigned short)uShort
{
	if (uShort <= UCHAR_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedChar: (unsigned char)uShort];

	return (id)[[OFNumber of_alloc] initWithUnsignedShort: uShort];
}

- (instancetype)initWithUnsignedInt: (unsigned int)uInt
{
	if (uInt <= USHRT_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedShort: (unsigned short)uInt];

	return (id)[[OFNumber of_alloc] initWithUnsignedInt: uInt];
}

- (instancetype)initWithUnsignedLong: (unsigned long)uLong
{
	if (uLong <= UINT_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedInt: (unsigned int)uLong];

	return (id)[[OFNumber of_alloc] initWithUnsignedLong: uLong];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)uLongLong
{
	if (uLongLong <= ULONG_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedLong: (unsigned long)uLongLong];

	return (id)[[OFNumber of_alloc] initWithUnsignedLongLong: uLongLong];
}

- (instancetype)initWithInt8: (int8_t)int8
{
	if (int8 >= 0)
		return (id)[[OFNumber of_alloc] initWithUInt8: int8];

	return (id)[[OFNumber of_alloc] initWithInt8: int8];
}

- (instancetype)initWithInt16: (int16_t)int16
{
	if (int16 >= 0)
		return (id)[[OFNumber of_alloc] initWithUInt16: int16];
	if (int16 >= INT8_MIN)
		return (id)[[OFNumber of_alloc] initWithInt8: (int8_t)int16];

	return (id)[[OFNumber of_alloc] initWithInt16: int16];
}

- (instancetype)initWithInt32: (int32_t)int32
{
	if (int32 >= 0)
		return (id)[[OFNumber of_alloc] initWithUInt32: int32];
	if (int32 >= INT16_MIN)
		return (id)[[OFNumber of_alloc] initWithInt16: (int16_t)int32];

	return (id)[[OFNumber of_alloc] initWithInt32: int32];
}

- (instancetype)initWithInt64: (int64_t)int64
{
	if (int64 >= 0)
		return (id)[[OFNumber of_alloc] initWithUInt64: int64];
	if (int64 >= INT32_MIN)
		return (id)[[OFNumber of_alloc] initWithInt32: (int32_t)int64];

	return (id)[[OFNumber of_alloc] initWithInt64: int64];
}

- (instancetype)initWithUInt8: (uint8_t)uInt8
{
	return (id)[[OFNumber of_alloc] initWithUInt8: uInt8];
}

- (instancetype)initWithUInt16: (uint16_t)uInt16
{
	if (uInt16 <= UINT8_MAX)
		return (id)[[OFNumber of_alloc] initWithUInt8: (uint8_t)uInt16];

	return (id)[[OFNumber of_alloc] initWithUInt16: uInt16];
}

- (instancetype)initWithUInt32: (uint32_t)uInt32
{
	if (uInt32 <= UINT16_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUInt16: (uint16_t)uInt32];

	return (id)[[OFNumber of_alloc] initWithUInt32: uInt32];
}

- (instancetype)initWithUInt64: (uint64_t)uInt64
{
	if (uInt64 <= UINT32_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUInt32: (uint32_t)uInt64];

	return (id)[[OFNumber of_alloc] initWithUInt64: uInt64];
}

- (instancetype)initWithSize: (size_t)size
{
	if (size <= ULONG_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedLong: (unsigned long)size];

	return (id)[[OFNumber of_alloc] initWithSize: size];
}

- (instancetype)initWithSSize: (ssize_t)sSize
{
	if (sSize >= 0)
		return (id)[[OFNumber of_alloc] initWithSize: sSize];
	if (sSize <= LONG_MIN)
		return (id)[[OFNumber of_alloc] initWithLong: (long)sSize];

	return (id)[[OFNumber of_alloc] initWithSSize: sSize];
}

- (instancetype)initWithIntMax: (intmax_t)intMax
{
	if (intMax >= 0)
		return (id)[[OFNumber of_alloc] initWithUIntMax: intMax];
	if (intMax <= LLONG_MIN)
		return (id)[[OFNumber of_alloc]
		    initWithLongLong: (long long)intMax];

	return (id)[[OFNumber of_alloc] initWithIntMax: intMax];
}

- (instancetype)initWithUIntMax: (uintmax_t)uIntMax
{
	if (uIntMax <= ULLONG_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedLongLong: (unsigned long long)uIntMax];

	return (id)[[OFNumber of_alloc] initWithUIntMax: uIntMax];
}

- (instancetype)initWithPtrDiff: (ptrdiff_t)ptrDiff
{
	if (ptrDiff >= LLONG_MIN && ptrDiff <= LLONG_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithLongLong: (long long)ptrDiff];

	return (id)[[OFNumber of_alloc] initWithPtrDiff: ptrDiff];
}

- (instancetype)initWithIntPtr: (intptr_t)intPtr
{
	if (intPtr >= 0)
		return (id)[[OFNumber of_alloc] initWithUIntPtr: intPtr];
	if (intPtr >= LLONG_MIN)
		return (id)[[OFNumber of_alloc]
		    initWithLongLong: (long long)intPtr];

	return (id)[[OFNumber of_alloc] initWithIntPtr: intPtr];
}

- (instancetype)initWithUIntPtr: (uintptr_t)uIntPtr
{
	if (uIntPtr <= ULLONG_MAX)
		return (id)[[OFNumber of_alloc]
		    initWithUnsignedLongLong: (unsigned long long)uIntPtr];

	return (id)[[OFNumber of_alloc] initWithUIntPtr: uIntPtr];
}

- (instancetype)initWithFloat: (float)float_
{
	if (float_ == (uintmax_t)float_)
		return (id)[[OFNumber of_alloc]
		    initWithUIntMax: (uintmax_t)float_];
	if (float_ == (intmax_t)float_)
		return (id)[[OFNumber of_alloc]
		    initWithIntMax: (intmax_t)float_];

	return (id)[[OFNumber of_alloc] initWithFloat: float_];
}

- (instancetype)initWithDouble: (double)double_
{
	if (double_ == (uintmax_t)double_)
		return (id)[[OFNumber of_alloc]
		    initWithUIntMax: (uintmax_t)double_];
	if (double_ == (intmax_t)double_)
		return (id)[[OFNumber of_alloc]
		    initWithIntMax: (intmax_t)double_];
	if (double_ == (float)double_)
		return (id)[[OFNumber of_alloc] initWithFloat: (float)double_];

	return (id)[[OFNumber of_alloc] initWithDouble: double_];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFNumber of_alloc] initWithSerialization: element];
}
@end

@implementation OFNumber
@synthesize type = _type;

+ (void)initialize
{
	if (self == [OFNumber class])
		placeholder.isa = [OFNumberPlaceholder class];
}

+ (instancetype)of_alloc
{
	return [super alloc];
}

+ (instancetype)alloc
{
	if (self == [OFNumber class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)numberWithBool: (bool)bool_
{
	return [[[self alloc] initWithBool: bool_] autorelease];
}

+ (instancetype)numberWithChar: (signed char)sChar
{
	return [[[self alloc] initWithChar: sChar] autorelease];
}

+ (instancetype)numberWithShort: (short)sShort
{
	return [[[self alloc] initWithShort: sShort] autorelease];
}

+ (instancetype)numberWithInt: (int)sInt
{
	return [[[self alloc] initWithInt: sInt] autorelease];
}

+ (instancetype)numberWithLong: (long)sLong
{
	return [[[self alloc] initWithLong: sLong] autorelease];
}

+ (instancetype)numberWithLongLong: (long long)sLongLong
{
	return [[[self alloc] initWithLongLong: sLongLong] autorelease];
}

+ (instancetype)numberWithUnsignedChar: (unsigned char)uChar
{
	return [[[self alloc] initWithUnsignedChar: uChar] autorelease];
}

+ (instancetype)numberWithUnsignedShort: (unsigned short)uShort
{
	return [[[self alloc] initWithUnsignedShort: uShort] autorelease];
}

+ (instancetype)numberWithUnsignedInt: (unsigned int)uInt
{
	return [[[self alloc] initWithUnsignedInt: uInt] autorelease];
}

+ (instancetype)numberWithUnsignedLong: (unsigned long)uLong
{
	return [[[self alloc] initWithUnsignedLong: uLong] autorelease];
}

+ (instancetype)numberWithUnsignedLongLong: (unsigned long long)uLongLong
{
	return [[[self alloc] initWithUnsignedLongLong: uLongLong] autorelease];
}

+ (instancetype)numberWithInt8: (int8_t)int8
{
	return [[[self alloc] initWithInt8: int8] autorelease];
}

+ (instancetype)numberWithInt16: (int16_t)int16
{
	return [[[self alloc] initWithInt16: int16] autorelease];
}

+ (instancetype)numberWithInt32: (int32_t)int32
{
	return [[[self alloc] initWithInt32: int32] autorelease];
}

+ (instancetype)numberWithInt64: (int64_t)int64
{
	return [[[self alloc] initWithInt64: int64] autorelease];
}

+ (instancetype)numberWithUInt8: (uint8_t)uInt8
{
	return [[[self alloc] initWithUInt8: uInt8] autorelease];
}

+ (instancetype)numberWithUInt16: (uint16_t)uInt16
{
	return [[[self alloc] initWithUInt16: uInt16] autorelease];
}

+ (instancetype)numberWithUInt32: (uint32_t)uInt32
{
	return [[[self alloc] initWithUInt32: uInt32] autorelease];
}

+ (instancetype)numberWithUInt64: (uint64_t)uInt64
{
	return [[[self alloc] initWithUInt64: uInt64] autorelease];
}

+ (instancetype)numberWithSize: (size_t)size
{
	return [[[self alloc] initWithSize: size] autorelease];
}

+ (instancetype)numberWithSSize: (ssize_t)sSize
{
	return [[[self alloc] initWithSSize: sSize] autorelease];
}

+ (instancetype)numberWithIntMax: (intmax_t)intMax
{
	return [[[self alloc] initWithIntMax: intMax] autorelease];
}

+ (instancetype)numberWithUIntMax: (uintmax_t)uIntMax
{
	return [[[self alloc] initWithUIntMax: uIntMax] autorelease];
}

+ (instancetype)numberWithPtrDiff: (ptrdiff_t)ptrDiff
{
	return [[[self alloc] initWithPtrDiff: ptrDiff] autorelease];
}

+ (instancetype)numberWithIntPtr: (intptr_t)intPtr
{
	return [[[self alloc] initWithIntPtr: intPtr] autorelease];
}

+ (instancetype)numberWithUIntPtr: (uintptr_t)uIntPtr
{
	return [[[self alloc] initWithUIntPtr: uIntPtr] autorelease];
}

+ (instancetype)numberWithFloat: (float)float_
{
	return [[[self alloc] initWithFloat: float_] autorelease];
}

+ (instancetype)numberWithDouble: (double)double_
{
	return [[[self alloc] initWithDouble: double_] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithBool: (bool)bool_
{
	self = [super init];

	_value.bool_ = bool_;
	_type = OF_NUMBER_TYPE_BOOL;

	return self;
}

- (instancetype)initWithChar: (signed char)sChar
{
	self = [super init];

	_value.sChar = sChar;
	_type = OF_NUMBER_TYPE_CHAR;

	return self;
}

- (instancetype)initWithShort: (short)sShort
{
	self = [super init];

	_value.sShort = sShort;
	_type = OF_NUMBER_TYPE_SHORT;

	return self;
}

- (instancetype)initWithInt: (int)sInt
{
	self = [super init];

	_value.sInt = sInt;
	_type = OF_NUMBER_TYPE_INT;

	return self;
}

- (instancetype)initWithLong: (long)sLong
{
	self = [super init];

	_value.sLong = sLong;
	_type = OF_NUMBER_TYPE_LONG;

	return self;
}

- (instancetype)initWithLongLong: (long long)sLongLong
{
	self = [super init];

	_value.sLongLong = sLongLong;
	_type = OF_NUMBER_TYPE_LONGLONG;

	return self;
}

- (instancetype)initWithUnsignedChar: (unsigned char)uChar
{
	self = [super init];

	_value.uChar = uChar;
	_type = OF_NUMBER_TYPE_UCHAR;

	return self;
}

- (instancetype)initWithUnsignedShort: (unsigned short)uShort
{
	self = [super init];

	_value.uShort = uShort;
	_type = OF_NUMBER_TYPE_USHORT;

	return self;
}

- (instancetype)initWithUnsignedInt: (unsigned int)uInt
{
	self = [super init];

	_value.uInt = uInt;
	_type = OF_NUMBER_TYPE_UINT;

	return self;
}

- (instancetype)initWithUnsignedLong: (unsigned long)uLong
{
	self = [super init];

	_value.uLong = uLong;
	_type = OF_NUMBER_TYPE_ULONG;

	return self;
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)uLongLong
{
	self = [super init];

	_value.uLongLong = uLongLong;
	_type = OF_NUMBER_TYPE_ULONGLONG;

	return self;
}

- (instancetype)initWithInt8: (int8_t)int8
{
	self = [super init];

	_value.int8 = int8;
	_type = OF_NUMBER_TYPE_INT8;

	return self;
}

- (instancetype)initWithInt16: (int16_t)int16
{
	self = [super init];

	_value.int16 = int16;
	_type = OF_NUMBER_TYPE_INT16;

	return self;
}

- (instancetype)initWithInt32: (int32_t)int32
{
	self = [super init];

	_value.int32 = int32;
	_type = OF_NUMBER_TYPE_INT32;

	return self;
}

- (instancetype)initWithInt64: (int64_t)int64
{
	self = [super init];

	_value.int64 = int64;
	_type = OF_NUMBER_TYPE_INT64;

	return self;
}

- (instancetype)initWithUInt8: (uint8_t)uInt8
{
	self = [super init];

	_value.uInt8 = uInt8;
	_type = OF_NUMBER_TYPE_UINT8;

	return self;
}

- (instancetype)initWithUInt16: (uint16_t)uInt16
{
	self = [super init];

	_value.uInt16 = uInt16;
	_type = OF_NUMBER_TYPE_UINT16;

	return self;
}

- (instancetype)initWithUInt32: (uint32_t)uInt32
{
	self = [super init];

	_value.uInt32 = uInt32;
	_type = OF_NUMBER_TYPE_UINT32;

	return self;
}

- (instancetype)initWithUInt64: (uint64_t)uInt64
{
	self = [super init];

	_value.uInt64 = uInt64;
	_type = OF_NUMBER_TYPE_UINT64;

	return self;
}

- (instancetype)initWithSize: (size_t)size
{
	self = [super init];

	_value.size = size;
	_type = OF_NUMBER_TYPE_SIZE;

	return self;
}

- (instancetype)initWithSSize: (ssize_t)sSize
{
	self = [super init];

	_value.sSize = sSize;
	_type = OF_NUMBER_TYPE_SSIZE;

	return self;
}

- (instancetype)initWithIntMax: (intmax_t)intMax
{
	self = [super init];

	_value.intMax = intMax;
	_type = OF_NUMBER_TYPE_INTMAX;

	return self;
}

- (instancetype)initWithUIntMax: (uintmax_t)uIntMax
{
	self = [super init];

	_value.uIntMax = uIntMax;
	_type = OF_NUMBER_TYPE_UINTMAX;

	return self;
}

- (instancetype)initWithPtrDiff: (ptrdiff_t)ptrDiff
{
	self = [super init];

	_value.ptrDiff = ptrDiff;
	_type = OF_NUMBER_TYPE_PTRDIFF;

	return self;
}

- (instancetype)initWithIntPtr: (intptr_t)intPtr
{
	self = [super init];

	_value.intPtr = intPtr;
	_type = OF_NUMBER_TYPE_INTPTR;

	return self;
}

- (instancetype)initWithUIntPtr: (uintptr_t)uIntPtr
{
	self = [super init];

	_value.uIntPtr = uIntPtr;
	_type = OF_NUMBER_TYPE_UINTPTR;

	return self;
}

- (instancetype)initWithFloat: (float)float_
{
	self = [super init];

	_value.float_ = float_;
	_type = OF_NUMBER_TYPE_FLOAT;

	return self;
}

- (instancetype)initWithDouble: (double)double_
{
	self = [super init];

	_value.double_ = double_;
	_type = OF_NUMBER_TYPE_DOUBLE;

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *typeString;

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		typeString = [element attributeForName: @"type"].stringValue;

		if ([typeString isEqual: @"boolean"]) {
			_type = OF_NUMBER_TYPE_BOOL;

			if ([[element stringValue] isEqual: @"true"])
				_value.bool_ = true;
			else if ([[element stringValue] isEqual: @"false"])
				_value.bool_ = false;
			else
				@throw [OFInvalidArgumentException exception];
		} else if ([typeString isEqual: @"unsigned"]) {
			/*
			 * FIXME: This will fail if the value is bigger than
			 *	  INTMAX_MAX!
			 */
			_type = OF_NUMBER_TYPE_UINTMAX;
			_value.uIntMax = element.decimalValue;
		} else if ([typeString isEqual: @"signed"]) {
			_type = OF_NUMBER_TYPE_INTMAX;
			_value.intMax = element.decimalValue;
		} else if ([typeString isEqual: @"float"]) {
			_type = OF_NUMBER_TYPE_FLOAT;
			_value.float_ = OF_BSWAP_FLOAT_IF_LE(
			    OF_INT_TO_FLOAT_RAW(OF_BSWAP32_IF_LE(
			    (uint32_t)element.hexadecimalValue)));
		} else if ([typeString isEqual: @"double"]) {
			_type = OF_NUMBER_TYPE_DOUBLE;
			_value.double_ = OF_BSWAP_DOUBLE_IF_LE(
			    OF_INT_TO_DOUBLE_RAW(OF_BSWAP64_IF_LE(
			    (uint64_t)element.hexadecimalValue)));
		} else
			@throw [OFInvalidArgumentException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (const char *)objCType
{
	switch (_type) {
	case OF_NUMBER_TYPE_BOOL:
		return @encode(bool);
	case OF_NUMBER_TYPE_CHAR:
		return @encode(signed char);
	case OF_NUMBER_TYPE_SHORT:
		return @encode(short);
	case OF_NUMBER_TYPE_INT:
		return @encode(int);
	case OF_NUMBER_TYPE_LONG:
		return @encode(long);
	case OF_NUMBER_TYPE_LONGLONG:
		return @encode(long long);
	case OF_NUMBER_TYPE_UCHAR:
		return @encode(unsigned char);
	case OF_NUMBER_TYPE_USHORT:
		return @encode(unsigned short);
	case OF_NUMBER_TYPE_UINT:
		return @encode(unsigned int);
	case OF_NUMBER_TYPE_ULONG:
		return @encode(unsigned long);
	case OF_NUMBER_TYPE_ULONGLONG:
		return @encode(unsigned long long);
	case OF_NUMBER_TYPE_INT8:
		return @encode(int8_t);
	case OF_NUMBER_TYPE_INT16:
		return @encode(int16_t);
	case OF_NUMBER_TYPE_INT32:
		return @encode(int32_t);
	case OF_NUMBER_TYPE_INT64:
		return @encode(int64_t);
	case OF_NUMBER_TYPE_UINT8:
		return @encode(uint8_t);
	case OF_NUMBER_TYPE_UINT16:
		return @encode(uint16_t);
	case OF_NUMBER_TYPE_UINT32:
		return @encode(uint32_t);
	case OF_NUMBER_TYPE_UINT64:
		return @encode(uint64_t);
	case OF_NUMBER_TYPE_SIZE:
		return @encode(size_t);
	case OF_NUMBER_TYPE_SSIZE:
		return @encode(ssize_t);
	case OF_NUMBER_TYPE_INTMAX:
		return @encode(intmax_t);
	case OF_NUMBER_TYPE_UINTMAX:
		return @encode(uintmax_t);
	case OF_NUMBER_TYPE_PTRDIFF:
		return @encode(ptrdiff_t);
	case OF_NUMBER_TYPE_INTPTR:
		return @encode(intptr_t);
	case OF_NUMBER_TYPE_UINTPTR:
		return @encode(uintptr_t);
	case OF_NUMBER_TYPE_FLOAT:
		return @encode(float);
	case OF_NUMBER_TYPE_DOUBLE:
		return @encode(double);
	default:
		@throw [OFInvalidFormatException exception];
	}
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	switch (_type) {
	case OF_NUMBER_TYPE_BOOL:
		if (size != sizeof(bool))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.bool_, sizeof(bool));
		break;
	case OF_NUMBER_TYPE_CHAR:
		if (size != sizeof(signed char))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sChar, sizeof(signed char));
		break;
	case OF_NUMBER_TYPE_SHORT:
		if (size != sizeof(short))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sShort, sizeof(short));
		break;
	case OF_NUMBER_TYPE_INT:
		if (size != sizeof(int))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sInt, sizeof(int));
		break;
	case OF_NUMBER_TYPE_LONG:
		if (size != sizeof(long))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sLong, sizeof(long));
		break;
	case OF_NUMBER_TYPE_LONGLONG:
		if (size != sizeof(long long))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sLongLong, sizeof(long long));
		break;
	case OF_NUMBER_TYPE_UCHAR:
		if (size != sizeof(unsigned char))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uChar, sizeof(unsigned char));
		break;
	case OF_NUMBER_TYPE_USHORT:
		if (size != sizeof(unsigned short))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uShort, sizeof(unsigned short));
		break;
	case OF_NUMBER_TYPE_UINT:
		if (size != sizeof(unsigned int))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uInt, sizeof(unsigned int));
		break;
	case OF_NUMBER_TYPE_ULONG:
		if (size != sizeof(unsigned long))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uLong, sizeof(unsigned long));
		break;
	case OF_NUMBER_TYPE_ULONGLONG:
		if (size != sizeof(unsigned long long))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uLongLong, sizeof(unsigned long long));
		break;
	case OF_NUMBER_TYPE_INT8:
		if (size != sizeof(int8_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.int8, sizeof(int8_t));
		break;
	case OF_NUMBER_TYPE_INT16:
		if (size != sizeof(int16_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.int16, sizeof(int16_t));
		break;
	case OF_NUMBER_TYPE_INT32:
		if (size != sizeof(int32_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.int32, sizeof(int32_t));
		break;
	case OF_NUMBER_TYPE_INT64:
		if (size != sizeof(int64_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.int64, sizeof(int64_t));
		break;
	case OF_NUMBER_TYPE_UINT8:
		if (size != sizeof(uint8_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uInt8, sizeof(uint8_t));
		break;
	case OF_NUMBER_TYPE_UINT16:
		if (size != sizeof(uint16_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uInt16, sizeof(uint16_t));
		break;
	case OF_NUMBER_TYPE_UINT32:
		if (size != sizeof(uint32_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uInt32, sizeof(uint32_t));
		break;
	case OF_NUMBER_TYPE_UINT64:
		if (size != sizeof(uint64_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uInt64, sizeof(uint64_t));
		break;
	case OF_NUMBER_TYPE_SIZE:
		if (size != sizeof(size_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.size, sizeof(size_t));
		break;
	case OF_NUMBER_TYPE_SSIZE:
		if (size != sizeof(ssize_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.sSize, sizeof(ssize_t));
		break;
	case OF_NUMBER_TYPE_INTMAX:
		if (size != sizeof(intmax_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.intMax, sizeof(intmax_t));
		break;
	case OF_NUMBER_TYPE_UINTMAX:
		if (size != sizeof(uintmax_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uIntMax, sizeof(uintmax_t));
		break;
	case OF_NUMBER_TYPE_PTRDIFF:
		if (size != sizeof(ptrdiff_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.ptrDiff, sizeof(ptrdiff_t));
		break;
	case OF_NUMBER_TYPE_INTPTR:
		if (size != sizeof(intptr_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.intPtr, sizeof(intptr_t));
		break;
	case OF_NUMBER_TYPE_UINTPTR:
		if (size != sizeof(uintptr_t))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.uIntPtr, sizeof(uintptr_t));
		break;
	case OF_NUMBER_TYPE_FLOAT:
		if (size != sizeof(float))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.float_, sizeof(float));
		break;
	case OF_NUMBER_TYPE_DOUBLE:
		if (size != sizeof(double))
			@throw [OFOutOfRangeException exception];

		memcpy(value, &_value.double_, sizeof(double));
		break;
	default:
		@throw [OFInvalidFormatException exception];
	}
}

- (bool)boolValue
{
	RETURN_AS(bool)
}

- (signed char)charValue
{
	RETURN_AS(signed char)
}

- (short)shortValue
{
	RETURN_AS(short)
}

- (int)intValue
{
	RETURN_AS(int)
}

- (long)longValue
{
	RETURN_AS(long)
}

- (long long)longLongValue
{
	RETURN_AS(long long)
}

- (unsigned char)unsignedCharValue
{
	RETURN_AS(unsigned char)
}

- (unsigned short)unsignedShortValue
{
	RETURN_AS(unsigned short)
}

- (unsigned int)unsignedIntValue
{
	RETURN_AS(unsigned int)
}

- (unsigned long)unsignedLongValue
{
	RETURN_AS(unsigned long)
}

- (unsigned long long)unsignedLongLongValue
{
	RETURN_AS(unsigned long long)
}

- (int8_t)int8Value
{
	RETURN_AS(int8_t)
}

- (int16_t)int16Value
{
	RETURN_AS(int16_t)
}

- (int32_t)int32Value
{
	RETURN_AS(int32_t)
}

- (int64_t)int64Value
{
	RETURN_AS(int64_t)
}

- (uint8_t)uInt8Value
{
	RETURN_AS(uint8_t)
}

- (uint16_t)uInt16Value
{
	RETURN_AS(uint16_t)
}

- (uint32_t)uInt32Value
{
	RETURN_AS(uint32_t)
}

- (uint64_t)uInt64Value
{
	RETURN_AS(uint64_t)
}

- (size_t)sizeValue
{
	RETURN_AS(size_t)
}

- (ssize_t)sSizeValue
{
	RETURN_AS(ssize_t)
}

- (intmax_t)intMaxValue
{
	RETURN_AS(intmax_t)
}

- (uintmax_t)uIntMaxValue
{
	RETURN_AS(uintmax_t)
}

- (ptrdiff_t)ptrDiffValue
{
	RETURN_AS(ptrdiff_t)
}

- (intptr_t)intPtrValue
{
	RETURN_AS(intptr_t)
}

- (uintptr_t)uIntPtrValue
{
	RETURN_AS(uintptr_t)
}

- (float)floatValue
{
	RETURN_AS(float)
}

- (double)doubleValue
{
	RETURN_AS(double)
}

- (bool)isEqual: (id)object
{
	OFNumber *number;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFNumber class]])
		return false;

	number = object;

	if (_type & OF_NUMBER_TYPE_FLOAT ||
	    number->_type & OF_NUMBER_TYPE_FLOAT) {
		double value1 = number.doubleValue;
		double value2 = self.doubleValue;

		if (isnan(value1) && isnan(value2))
			return true;
		if (isnan(value1) || isnan(value2))
			return false;

		return (value1 == value2);
	}

	if (_type & OF_NUMBER_TYPE_SIGNED ||
	    number->_type & OF_NUMBER_TYPE_SIGNED)
		return (number.intMaxValue == self.intMaxValue);

	return (number.uIntMaxValue == self.uIntMaxValue);
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFNumber *number;

	if (![(id)object isKindOfClass: [OFNumber class]])
		@throw [OFInvalidArgumentException exception];

	number = (OFNumber *)object;

	if (_type & OF_NUMBER_TYPE_FLOAT ||
	    number->_type & OF_NUMBER_TYPE_FLOAT) {
		double double1 = self.doubleValue;
		double double2 = number.doubleValue;

		if (double1 > double2)
			return OF_ORDERED_DESCENDING;
		if (double1 < double2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else if (_type & OF_NUMBER_TYPE_SIGNED ||
	    number->_type & OF_NUMBER_TYPE_SIGNED) {
		intmax_t int1 = self.intMaxValue;
		intmax_t int2 = number.intMaxValue;

		if (int1 > int2)
			return OF_ORDERED_DESCENDING;
		if (int1 < int2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else {
		uintmax_t uint1 = self.uIntMaxValue;
		uintmax_t uint2 = number.uIntMaxValue;

		if (uint1 > uint2)
			return OF_ORDERED_DESCENDING;
		if (uint1 < uint2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	}
}

- (uint32_t)hash
{
	of_number_type_t type = _type;
	uint32_t hash;

	/* Do we really need signed to represent this number? */
	if (type & OF_NUMBER_TYPE_SIGNED && self.intMaxValue >= 0)
		type &= ~OF_NUMBER_TYPE_SIGNED;

	/* Do we really need floating point to represent this number? */
	if (type & OF_NUMBER_TYPE_FLOAT) {
		double v = self.doubleValue;

		if (v < 0) {
			if (v == self.intMaxValue) {
				type &= ~OF_NUMBER_TYPE_FLOAT;
				type |= OF_NUMBER_TYPE_SIGNED;
			}
		} else {
			if (v == self.uIntMaxValue)
				type &= ~OF_NUMBER_TYPE_FLOAT;
		}
	}

	OF_HASH_INIT(hash);

	if (type & OF_NUMBER_TYPE_FLOAT) {
		double d;

		if (isnan(self.doubleValue))
			return 0;

		d = OF_BSWAP_DOUBLE_IF_BE(self.doubleValue);

		for (uint_fast8_t i = 0; i < sizeof(double); i++)
			OF_HASH_ADD(hash, ((char *)&d)[i]);
	} else if (type & OF_NUMBER_TYPE_SIGNED) {
		intmax_t v = self.intMaxValue * -1;

		while (v != 0) {
			OF_HASH_ADD(hash, v & 0xFF);
			v >>= 8;
		}

		OF_HASH_ADD(hash, 1);
	} else {
		uintmax_t v = self.uIntMaxValue;

		while (v != 0) {
			OF_HASH_ADD(hash, v & 0xFF);
			v >>= 8;
		}
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (id)copy
{
	return [self retain];
}

- (OFString *)description
{
	return [self stringValue];
}

- (OFString *)stringValue
{
	OFMutableString *ret;

	switch (_type) {
	case OF_NUMBER_TYPE_BOOL:
		return (_value.bool_ ? @"true" : @"false");
	case OF_NUMBER_TYPE_UCHAR:
	case OF_NUMBER_TYPE_USHORT:
	case OF_NUMBER_TYPE_UINT:
	case OF_NUMBER_TYPE_ULONG:
	case OF_NUMBER_TYPE_ULONGLONG:
	case OF_NUMBER_TYPE_UINT8:
	case OF_NUMBER_TYPE_UINT16:
	case OF_NUMBER_TYPE_UINT32:
	case OF_NUMBER_TYPE_UINT64:
	case OF_NUMBER_TYPE_SIZE:
	case OF_NUMBER_TYPE_UINTMAX:
	case OF_NUMBER_TYPE_UINTPTR:
		return [OFString stringWithFormat: @"%ju", self.uIntMaxValue];
	case OF_NUMBER_TYPE_CHAR:
	case OF_NUMBER_TYPE_SHORT:
	case OF_NUMBER_TYPE_INT:
	case OF_NUMBER_TYPE_LONG:
	case OF_NUMBER_TYPE_LONGLONG:
	case OF_NUMBER_TYPE_INT8:
	case OF_NUMBER_TYPE_INT16:
	case OF_NUMBER_TYPE_INT32:
	case OF_NUMBER_TYPE_INT64:
	case OF_NUMBER_TYPE_SSIZE:
	case OF_NUMBER_TYPE_INTMAX:
	case OF_NUMBER_TYPE_PTRDIFF:
	case OF_NUMBER_TYPE_INTPTR:
		return [OFString stringWithFormat: @"%jd", self.intMaxValue];
	case OF_NUMBER_TYPE_FLOAT:
		ret = [OFMutableString stringWithFormat: @"%g", _value.float_];

		if (![ret containsString: @"."])
			[ret appendString: @".0"];

		[ret makeImmutable];

		return ret;
	case OF_NUMBER_TYPE_DOUBLE:
		ret = [OFMutableString stringWithFormat: @"%g", _value.double_];

		if (![ret containsString: @"."])
			[ret appendString: @".0"];

		[ret makeImmutable];

		return ret;
	default:
		@throw [OFInvalidFormatException exception];
	}
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self.description];

	switch (_type) {
	case OF_NUMBER_TYPE_BOOL:
		[element addAttributeWithName: @"type"
				  stringValue: @"boolean"];
		break;
	case OF_NUMBER_TYPE_UCHAR:
	case OF_NUMBER_TYPE_USHORT:
	case OF_NUMBER_TYPE_UINT:
	case OF_NUMBER_TYPE_ULONG:
	case OF_NUMBER_TYPE_ULONGLONG:
	case OF_NUMBER_TYPE_UINT8:
	case OF_NUMBER_TYPE_UINT16:
	case OF_NUMBER_TYPE_UINT32:
	case OF_NUMBER_TYPE_UINT64:
	case OF_NUMBER_TYPE_SIZE:
	case OF_NUMBER_TYPE_UINTMAX:
	case OF_NUMBER_TYPE_UINTPTR:
		[element addAttributeWithName: @"type"
				  stringValue: @"unsigned"];
		break;
	case OF_NUMBER_TYPE_CHAR:
	case OF_NUMBER_TYPE_SHORT:
	case OF_NUMBER_TYPE_INT:
	case OF_NUMBER_TYPE_LONG:
	case OF_NUMBER_TYPE_LONGLONG:
	case OF_NUMBER_TYPE_INT8:
	case OF_NUMBER_TYPE_INT16:
	case OF_NUMBER_TYPE_INT32:
	case OF_NUMBER_TYPE_INT64:
	case OF_NUMBER_TYPE_SSIZE:
	case OF_NUMBER_TYPE_INTMAX:
	case OF_NUMBER_TYPE_PTRDIFF:
	case OF_NUMBER_TYPE_INTPTR:
		[element addAttributeWithName: @"type"
				  stringValue: @"signed"];
		break;
	case OF_NUMBER_TYPE_FLOAT:
		[element addAttributeWithName: @"type"
				  stringValue: @"float"];
		element.stringValue = [OFString stringWithFormat: @"%08" PRIx32,
		    OF_BSWAP32_IF_LE(OF_FLOAT_TO_INT_RAW(OF_BSWAP_FLOAT_IF_LE(
		    _value.float_)))];

		break;
	case OF_NUMBER_TYPE_DOUBLE:
		[element addAttributeWithName: @"type"
				  stringValue: @"double"];
		element.stringValue = [OFString
		    stringWithFormat: @"%016" PRIx64,
		    OF_BSWAP64_IF_LE(OF_DOUBLE_TO_INT_RAW(OF_BSWAP_DOUBLE_IF_LE(
		    _value.double_)))];

		break;
	default:
		@throw [OFInvalidFormatException exception];
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0
						depth: 0];
}

- (OFString *)JSONRepresentationWithOptions: (int)options
{
	return [self of_JSONRepresentationWithOptions: options
						depth: 0];
}

- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth
{
	double doubleValue;

	if (_type == OF_NUMBER_TYPE_BOOL)
		return (_value.bool_ ? @"true" : @"false");

	doubleValue = self.doubleValue;
	if (isinf(doubleValue)) {
		if (options & OF_JSON_REPRESENTATION_JSON5) {
			if (doubleValue > 0)
				return @"Infinity";
			else
				return @"-Infinity";
		} else
			@throw [OFInvalidArgumentException exception];
	}

	return self.description;
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;

	if (_type == OF_NUMBER_TYPE_BOOL) {
		uint8_t type = (_value.bool_ ? 0xC3 : 0xC2);

		data = [OFMutableData dataWithItems: &type
					      count: 1];
	} else if (_type == OF_NUMBER_TYPE_FLOAT) {
		uint8_t type = 0xCA;
		float tmp = OF_BSWAP_FLOAT_IF_LE(_value.float_);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_type == OF_NUMBER_TYPE_DOUBLE) {
		uint8_t type = 0xCB;
		double tmp = OF_BSWAP_DOUBLE_IF_LE(_value.double_);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: 9];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_type & OF_NUMBER_TYPE_SIGNED) {
		intmax_t value = self.intMaxValue;

		if (value >= -32 && value < 0) {
			uint8_t tmp = 0xE0 | ((uint8_t)(value - 32) & 0x1F);

			data = [OFMutableData dataWithItems: &tmp
						      count: 1];
		} else if (value >= INT8_MIN && value <= INT8_MAX) {
			uint8_t type = 0xD0;
			int8_t tmp = (int8_t)value;

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 2];

			[data addItem: &type];
			[data addItem: &tmp];
		} else if (value >= INT16_MIN && value <= INT16_MAX) {
			uint8_t type = 0xD1;
			int16_t tmp = OF_BSWAP16_IF_LE((int16_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 3];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else if (value >= INT32_MIN && value <= INT32_MAX) {
			uint8_t type = 0xD2;
			int32_t tmp = OF_BSWAP32_IF_LE((int32_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 5];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else if (value >= INT64_MIN && value <= INT64_MAX) {
			uint8_t type = 0xD3;
			int64_t tmp = OF_BSWAP64_IF_LE((int64_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 9];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else
			@throw [OFOutOfRangeException exception];
	} else {
		uintmax_t value = self.uIntMaxValue;

		if (value <= 127) {
			uint8_t tmp = ((uint8_t)value & 0x7F);

			data = [OFMutableData dataWithItems: &tmp
						      count: 1];
		} else if (value <= UINT8_MAX) {
			uint8_t type = 0xCC;
			uint8_t tmp = (uint8_t)value;

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 2];

			[data addItem: &type];
			[data addItem: &tmp];
		} else if (value <= UINT16_MAX) {
			uint8_t type = 0xCD;
			uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 3];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else if (value <= UINT32_MAX) {
			uint8_t type = 0xCE;
			uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 5];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else if (value <= UINT64_MAX) {
			uint8_t type = 0xCF;
			uint64_t tmp = OF_BSWAP64_IF_LE((uint64_t)value);

			data = [OFMutableData dataWithItemSize: 1
						      capacity: 9];

			[data addItem: &type];
			[data addItems: &tmp
				 count: sizeof(tmp)];
		} else
			@throw [OFOutOfRangeException exception];
	}

	[data makeImmutable];

	return data;
}
@end
