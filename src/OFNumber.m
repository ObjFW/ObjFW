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

@interface OFNumber ()
+ (instancetype)of_alloc;
- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth;
@end

@interface OFNumberPlaceholder: OFNumber
@end

@interface OFNumberSingleton: OFNumber
@end

static struct {
	Class isa;
} placeholder;

static OFNumberSingleton *zeroNumber, *oneNumber, *twoNumber;
static OFNumberSingleton *trueNumber, *falseNumber;

static void
initZeroNumber(void)
{
	zeroNumber = [[OFNumberSingleton alloc] initWithUnsignedChar: 0];
}

static void
initOneNumber(void)
{
	oneNumber = [[OFNumberSingleton alloc] initWithUnsignedChar: 1];
}

static void
initTwoNumber(void)
{
	twoNumber = [[OFNumberSingleton alloc] initWithUnsignedChar: 2];
}

static void
initTrueNumber(void)
{
	trueNumber = [[OFNumberSingleton alloc] initWithBool: true];
}

static void
initFalseNumber(void)
{
	falseNumber = [[OFNumberSingleton alloc] initWithBool: false];
}

@implementation OFNumberPlaceholder
- (instancetype)initWithBool: (bool)bool_
{
	if (bool_) {
		static of_once_t once;
		of_once(&once, initTrueNumber);
		return (id)trueNumber;
	} else {
		static of_once_t once;
		of_once(&once, initFalseNumber);
		return (id)falseNumber;
	}
}

- (instancetype)initWithChar: (signed char)sChar
{
	if (sChar >= 0)
		return [self initWithUnsignedChar: sChar];

	return (id)[[OFNumber of_alloc] initWithChar: sChar];
}

- (instancetype)initWithShort: (short)sShort
{
	if (sShort >= 0)
		return [self initWithUnsignedShort: sShort];
	if (sShort >= SCHAR_MIN)
		return [self initWithChar: (signed char)sShort];

	return (id)[[OFNumber of_alloc] initWithShort: sShort];
}

- (instancetype)initWithInt: (int)sInt
{
	if (sInt >= 0)
		return [self initWithUnsignedInt: sInt];
	if (sInt >= SHRT_MIN)
		return [self initWithShort: (short)sInt];

	return (id)[[OFNumber of_alloc] initWithInt: sInt];
}

- (instancetype)initWithLong: (long)sLong
{
	if (sLong >= 0)
		return [self initWithUnsignedLong: sLong];
	if (sLong >= INT_MIN)
		return [self initWithShort: (int)sLong];

	return (id)[[OFNumber of_alloc] initWithLong: sLong];
}

- (instancetype)initWithLongLong: (long long)sLongLong
{
	if (sLongLong >= 0)
		return [self initWithUnsignedLongLong: sLongLong];
	if (sLongLong >= LONG_MIN)
		return [self initWithLong: (long)sLongLong];

	return (id)[[OFNumber of_alloc] initWithLongLong: sLongLong];
}

- (instancetype)initWithUnsignedChar: (unsigned char)uChar
{
	switch (uChar) {
	case 0: {
		static of_once_t once = OF_ONCE_INIT;
		of_once(&once, initZeroNumber);
		return (id)zeroNumber;
	}
	case 1: {
		static of_once_t once = OF_ONCE_INIT;
		of_once(&once, initOneNumber);
		return (id)oneNumber;
	}
	case 2: {
		static of_once_t once = OF_ONCE_INIT;
		of_once(&once, initTwoNumber);
		return (id)twoNumber;
	}
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedChar: uChar];
}

- (instancetype)initWithUnsignedShort: (unsigned short)uShort
{
	if (uShort <= UCHAR_MAX)
		return [self initWithUnsignedChar: (unsigned char)uShort];

	return (id)[[OFNumber of_alloc] initWithUnsignedShort: uShort];
}

- (instancetype)initWithUnsignedInt: (unsigned int)uInt
{
	if (uInt <= USHRT_MAX)
		return [self initWithUnsignedShort: (unsigned short)uInt];

	return (id)[[OFNumber of_alloc] initWithUnsignedInt: uInt];
}

- (instancetype)initWithUnsignedLong: (unsigned long)uLong
{
	if (uLong <= UINT_MAX)
		return [self initWithUnsignedInt: (unsigned int)uLong];

	return (id)[[OFNumber of_alloc] initWithUnsignedLong: uLong];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)uLongLong
{
	if (uLongLong <= ULONG_MAX)
		return [self initWithUnsignedLong: (unsigned long)uLongLong];

	return (id)[[OFNumber of_alloc] initWithUnsignedLongLong: uLongLong];
}

- (instancetype)initWithInt8: (int8_t)int8
{
	if (int8 >= 0)
		return [self initWithUInt8: int8];

	return (id)[[OFNumber of_alloc] initWithInt8: int8];
}

- (instancetype)initWithInt16: (int16_t)int16
{
	if (int16 >= 0)
		return [self initWithUInt16: int16];
	if (int16 >= INT8_MIN)
		return [self initWithInt8: (int8_t)int16];

	return (id)[[OFNumber of_alloc] initWithInt16: int16];
}

- (instancetype)initWithInt32: (int32_t)int32
{
	if (int32 >= 0)
		return [self initWithUInt32: int32];
	if (int32 >= INT16_MIN)
		return [self initWithInt16: (int16_t)int32];

	return (id)[[OFNumber of_alloc] initWithInt32: int32];
}

- (instancetype)initWithInt64: (int64_t)int64
{
	if (int64 >= 0)
		return [self initWithUInt64: int64];
	if (int64 >= INT32_MIN)
		return [self initWithInt32: (int32_t)int64];

	return (id)[[OFNumber of_alloc] initWithInt64: int64];
}

- (instancetype)initWithUInt8: (uint8_t)uInt8
{
	return (id)[[OFNumber of_alloc] initWithUInt8: uInt8];
}

- (instancetype)initWithUInt16: (uint16_t)uInt16
{
	if (uInt16 <= UINT8_MAX)
		return [self initWithUInt8: (uint8_t)uInt16];

	return (id)[[OFNumber of_alloc] initWithUInt16: uInt16];
}

- (instancetype)initWithUInt32: (uint32_t)uInt32
{
	if (uInt32 <= UINT16_MAX)
		return [self initWithUInt16: (uint16_t)uInt32];

	return (id)[[OFNumber of_alloc] initWithUInt32: uInt32];
}

- (instancetype)initWithUInt64: (uint64_t)uInt64
{
	if (uInt64 <= UINT32_MAX)
		return [self initWithUInt32: (uint32_t)uInt64];

	return (id)[[OFNumber of_alloc] initWithUInt64: uInt64];
}

- (instancetype)initWithSize: (size_t)size
{
	if (size <= ULONG_MAX)
		return [self initWithUnsignedLong: (unsigned long)size];

	return (id)[[OFNumber of_alloc] initWithSize: size];
}

- (instancetype)initWithSSize: (ssize_t)sSize
{
	if (sSize >= 0)
		return [self initWithSize: sSize];
	if (sSize <= LONG_MIN)
		return [self initWithLong: (long)sSize];

	return (id)[[OFNumber of_alloc] initWithSSize: sSize];
}

- (instancetype)initWithIntMax: (intmax_t)intMax
{
	if (intMax >= 0)
		return [self initWithUIntMax: intMax];
	if (intMax <= LLONG_MIN)
		return [self initWithLongLong: (long long)intMax];

	return (id)[[OFNumber of_alloc] initWithIntMax: intMax];
}

- (instancetype)initWithUIntMax: (uintmax_t)uIntMax
{
	if (uIntMax <= ULLONG_MAX)
		return [self initWithUnsignedLongLong:
		    (unsigned long long)uIntMax];

	return (id)[[OFNumber of_alloc] initWithUIntMax: uIntMax];
}

#ifdef __clang__
/*
 * This warning should probably not exist at all, as it prevents checking
 * whether one type fits into another in a portable way.
 */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wtautological-constant-out-of-range-compare"
#endif

- (instancetype)initWithPtrDiff: (ptrdiff_t)ptrDiff
{
	if (ptrDiff >= LLONG_MIN && ptrDiff <= LLONG_MAX)
		return [self initWithLongLong: (long long)ptrDiff];

	return (id)[[OFNumber of_alloc] initWithPtrDiff: ptrDiff];
}

- (instancetype)initWithIntPtr: (intptr_t)intPtr
{
	if (intPtr >= 0)
		return [self initWithUIntPtr: intPtr];
	if (intPtr >= LLONG_MIN)
		return [self initWithLongLong: (long long)intPtr];

	return (id)[[OFNumber of_alloc] initWithIntPtr: intPtr];
}

- (instancetype)initWithUIntPtr: (uintptr_t)uIntPtr
{
	if (uIntPtr <= ULLONG_MAX)
		return [self initWithUnsignedLongLong:
		    (unsigned long long)uIntPtr];

	return (id)[[OFNumber of_alloc] initWithUIntPtr: uIntPtr];
}

#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithFloat: (float)float_
{
	if (float_ == (uintmax_t)float_)
		return [self initWithUIntMax: (uintmax_t)float_];
	if (float_ == (intmax_t)float_)
		return [self initWithIntMax: (intmax_t)float_];

	return (id)[[OFNumber of_alloc] initWithFloat: float_];
}

- (instancetype)initWithDouble: (double)double_
{
	if (double_ == (uintmax_t)double_)
		return [self initWithUIntMax: (uintmax_t)double_];
	if (double_ == (intmax_t)double_)
		return [self initWithIntMax: (intmax_t)double_];
	if (double_ == (float)double_)
		return [self initWithFloat: (float)double_];

	return (id)[[OFNumber of_alloc] initWithDouble: double_];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFNumber of_alloc] initWithSerialization: element];
}
@end

@implementation OFNumberSingleton
- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}
@end

@implementation OFNumber
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

	_value.unsigned_ = bool_;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(bool);

	return self;
}

- (instancetype)initWithChar: (signed char)sChar
{
	self = [super init];

	_value.signed_ = sChar;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(signed char);

	return self;
}

- (instancetype)initWithShort: (short)sShort
{
	self = [super init];

	_value.signed_ = sShort;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(short);

	return self;
}

- (instancetype)initWithInt: (int)sInt
{
	self = [super init];

	_value.signed_ = sInt;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int);

	return self;
}

- (instancetype)initWithLong: (long)sLong
{
	self = [super init];

	_value.signed_ = sLong;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(long);

	return self;
}

- (instancetype)initWithLongLong: (long long)sLongLong
{
	self = [super init];

	_value.signed_ = sLongLong;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(long long);

	return self;
}

- (instancetype)initWithUnsignedChar: (unsigned char)uChar
{
	self = [super init];

	_value.unsigned_ = uChar;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedShort: (unsigned short)uShort
{
	self = [super init];

	_value.unsigned_ = uShort;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned short);

	return self;
}

- (instancetype)initWithUnsignedInt: (unsigned int)uInt
{
	self = [super init];

	_value.unsigned_ = uInt;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned int);

	return self;
}

- (instancetype)initWithUnsignedLong: (unsigned long)uLong
{
	self = [super init];

	_value.unsigned_ = uLong;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)uLongLong
{
	self = [super init];

	_value.unsigned_ = uLongLong;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long long);

	return self;
}

- (instancetype)initWithInt8: (int8_t)int8
{
	self = [super init];

	_value.signed_ = int8;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int8_t);

	return self;
}

- (instancetype)initWithInt16: (int16_t)int16
{
	self = [super init];

	_value.signed_ = int16;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int16_t);

	return self;
}

- (instancetype)initWithInt32: (int32_t)int32
{
	self = [super init];

	_value.signed_ = int32;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int32_t);

	return self;
}

- (instancetype)initWithInt64: (int64_t)int64
{
	self = [super init];

	_value.signed_ = int64;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int64_t);

	return self;
}

- (instancetype)initWithUInt8: (uint8_t)uInt8
{
	self = [super init];

	_value.unsigned_ = uInt8;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint8_t);

	return self;
}

- (instancetype)initWithUInt16: (uint16_t)uInt16
{
	self = [super init];

	_value.unsigned_ = uInt16;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint16_t);

	return self;
}

- (instancetype)initWithUInt32: (uint32_t)uInt32
{
	self = [super init];

	_value.unsigned_ = uInt32;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint32_t);

	return self;
}

- (instancetype)initWithUInt64: (uint64_t)uInt64
{
	self = [super init];

	_value.unsigned_ = uInt64;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint64_t);

	return self;
}

- (instancetype)initWithSize: (size_t)size
{
	self = [super init];

	_value.unsigned_ = size;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(size_t);

	return self;
}

- (instancetype)initWithSSize: (ssize_t)sSize
{
	self = [super init];

	_value.signed_ = sSize;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(ssize_t);

	return self;
}

- (instancetype)initWithIntMax: (intmax_t)intMax
{
	self = [super init];

	_value.signed_ = intMax;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(intmax_t);

	return self;
}

- (instancetype)initWithUIntMax: (uintmax_t)uIntMax
{
	self = [super init];

	_value.unsigned_ = uIntMax;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uintmax_t);

	return self;
}

- (instancetype)initWithPtrDiff: (ptrdiff_t)ptrDiff
{
	self = [super init];

	_value.signed_ = ptrDiff;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(ptrdiff_t);

	return self;
}

- (instancetype)initWithIntPtr: (intptr_t)intPtr
{
	self = [super init];

	_value.signed_ = intPtr;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(intptr_t);

	return self;
}

- (instancetype)initWithUIntPtr: (uintptr_t)uIntPtr
{
	self = [super init];

	_value.unsigned_ = uIntPtr;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uintptr_t);

	return self;
}

- (instancetype)initWithFloat: (float)float_
{
	self = [super init];

	_value.float_ = float_;
	_type = OF_NUMBER_TYPE_FLOAT;
	_typeEncoding = @encode(float);

	return self;
}

- (instancetype)initWithDouble: (double)double_
{
	self = [super init];

	_value.float_ = double_;
	_type = OF_NUMBER_TYPE_FLOAT;
	_typeEncoding = @encode(double);

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

		if ([typeString isEqual: @"bool"]) {
			OFString *stringValue = element.stringValue;
			if ([stringValue isEqual: @"true"])
				self = [self initWithBool: true];
			else if ([stringValue isEqual: @"false"])
				self = [self initWithBool: false];
			else
				@throw [OFInvalidArgumentException exception];
		} else if ([typeString isEqual: @"float"])
			self = [self initWithDouble: OF_BSWAP_DOUBLE_IF_LE(
			    OF_INT_TO_DOUBLE_RAW(OF_BSWAP64_IF_LE(
			    (uint64_t)element.hexadecimalValue)))];
		else if ([typeString isEqual: @"signed"])
			self = [self initWithIntMax: element.doubleValue];
		else if ([typeString isEqual: @"unsigned"])
			/*
			 * FIXME: This will fail if the value is bigger than
			 *	  INTMAX_MAX!
			 */
			self = [self initWithUIntMax: element.decimalValue];
		else
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
	return _typeEncoding;
}

- (void)getValue: (void *)value
	    size: (size_t)size
{
	switch (*_typeEncoding) {
#define CASE(enc, type, field)						\
	case enc: {							\
		type tmp = (type)_value.field;				\
									\
		if (size != sizeof(type))				\
			@throw [OFOutOfRangeException exception];	\
									\
		memcpy(value, &tmp, size);				\
		break;							\
	}
	CASE('B', bool, unsigned_)
	CASE('c', signed char, signed_)
	CASE('s', short, signed_)
	CASE('i', int, signed_)
	CASE('l', long, signed_)
	CASE('q', long long, signed_)
	CASE('C', unsigned char, unsigned_)
	CASE('S', unsigned short, unsigned_)
	CASE('I', unsigned int, unsigned_)
	CASE('L', unsigned long, unsigned_)
	CASE('Q', unsigned long long, unsigned_)
	CASE('f', float, float_)
	CASE('d', double, float_)
#undef CASE
	default:
		@throw [OFInvalidFormatException exception];
	}
}

#define RETURN_AS(t)						\
	switch (_type) {					\
	case OF_NUMBER_TYPE_FLOAT:				\
		return (t)_value.float_;			\
	case OF_NUMBER_TYPE_SIGNED:				\
		return (t)_value.signed_;			\
	case OF_NUMBER_TYPE_UNSIGNED:				\
		return (t)_value.unsigned_;			\
	default:						\
		@throw [OFInvalidFormatException exception];	\
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
#undef RETURN_AS

- (bool)isEqual: (id)object
{
	OFNumber *number;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFNumber class]])
		return false;

	number = object;

	if (_type == OF_NUMBER_TYPE_FLOAT ||
	    number->_type == OF_NUMBER_TYPE_FLOAT) {
		double value1 = number.doubleValue;
		double value2 = self.doubleValue;

		if (isnan(value1) && isnan(value2))
			return true;
		if (isnan(value1) || isnan(value2))
			return false;

		return (value1 == value2);
	}

	if (_type == OF_NUMBER_TYPE_SIGNED ||
	    number->_type == OF_NUMBER_TYPE_SIGNED)
		return (number.intMaxValue == self.intMaxValue);

	return (number.uIntMaxValue == self.uIntMaxValue);
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFNumber *number;

	if (![(id)object isKindOfClass: [OFNumber class]])
		@throw [OFInvalidArgumentException exception];

	number = (OFNumber *)object;

	if (_type == OF_NUMBER_TYPE_FLOAT ||
	    number->_type == OF_NUMBER_TYPE_FLOAT) {
		double double1 = self.doubleValue;
		double double2 = number.doubleValue;

		if (double1 > double2)
			return OF_ORDERED_DESCENDING;
		if (double1 < double2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else if (_type == OF_NUMBER_TYPE_SIGNED ||
	    number->_type == OF_NUMBER_TYPE_SIGNED) {
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
	enum of_number_type type = _type;
	uint32_t hash;

	OF_HASH_INIT(hash);

	if (type == OF_NUMBER_TYPE_FLOAT) {
		double d;

		if (isnan(self.doubleValue))
			return 0;

		d = OF_BSWAP_DOUBLE_IF_BE(self.doubleValue);

		for (uint_fast8_t i = 0; i < sizeof(double); i++)
			OF_HASH_ADD(hash, ((char *)&d)[i]);
	} else if (type == OF_NUMBER_TYPE_SIGNED) {
		intmax_t v = self.intMaxValue * -1;

		while (v != 0) {
			OF_HASH_ADD(hash, v & 0xFF);
			v >>= 8;
		}

		OF_HASH_ADD(hash, 1);
	} else if (type == OF_NUMBER_TYPE_UNSIGNED) {
		uintmax_t v = self.uIntMaxValue;

		while (v != 0) {
			OF_HASH_ADD(hash, v & 0xFF);
			v >>= 8;
		}
	} else
		@throw [OFInvalidFormatException exception];

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
	if (*_typeEncoding == 'B')
		return (_value.unsigned_ ? @"true" : @"false");
	if (_type == OF_NUMBER_TYPE_FLOAT)
		return [OFString stringWithFormat: @"%g", _value.float_];
	if (_type == OF_NUMBER_TYPE_SIGNED)
		return [OFString stringWithFormat: @"%jd", _value.signed_];
	if (_type == OF_NUMBER_TYPE_UNSIGNED)
		return [OFString stringWithFormat: @"%ju", _value.unsigned_];

	@throw [OFInvalidFormatException exception];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: self.className
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self.description];

	if (*_typeEncoding == 'B')
		[element addAttributeWithName: @"type"
				  stringValue: @"bool"];
	else if (_type == OF_NUMBER_TYPE_FLOAT) {
		[element addAttributeWithName: @"type"
				  stringValue: @"float"];
		element.stringValue = [OFString
		    stringWithFormat: @"%016" PRIx64,
		    OF_BSWAP64_IF_LE(OF_DOUBLE_TO_INT_RAW(OF_BSWAP_DOUBLE_IF_LE(
		    _value.float_)))];
	} else if (_type == OF_NUMBER_TYPE_SIGNED)
		[element addAttributeWithName: @"type"
				  stringValue: @"signed"];
	else if (_type == OF_NUMBER_TYPE_UNSIGNED)
		[element addAttributeWithName: @"type"
				  stringValue: @"unsigned"];
	else
		@throw [OFInvalidFormatException exception];

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

	if (*_typeEncoding == 'B')
		return (_value.unsigned_ ? @"true" : @"false");

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

	if (*_typeEncoding == 'B') {
		uint8_t type = (_value.unsigned_ ? 0xC3 : 0xC2);

		data = [OFMutableData dataWithItems: &type
					      count: 1];
	} else if (*_typeEncoding == 'f') {
		uint8_t type = 0xCA;
		float tmp = OF_BSWAP_FLOAT_IF_LE(_value.float_);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: 5];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (*_typeEncoding == 'd') {
		uint8_t type = 0xCB;
		double tmp = OF_BSWAP_DOUBLE_IF_LE(_value.float_);

		data = [OFMutableData dataWithItemSize: 1
					      capacity: 9];

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (_type == OF_NUMBER_TYPE_SIGNED) {
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
	} else if (_type == OF_NUMBER_TYPE_UNSIGNED) {
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
	} else
		@throw [OFInvalidFormatException exception];

	[data makeImmutable];

	return data;
}
@end
