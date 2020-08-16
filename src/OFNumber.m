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
- (instancetype)initWithBool: (bool)value
{
	if (value) {
		static of_once_t once;
		of_once(&once, initTrueNumber);
		return (id)trueNumber;
	} else {
		static of_once_t once;
		of_once(&once, initFalseNumber);
		return (id)falseNumber;
	}
}

- (instancetype)initWithChar: (signed char)value
{
	if (value >= 0)
		return [self initWithUnsignedChar: value];

	return (id)[[OFNumber of_alloc] initWithChar: value];
}

- (instancetype)initWithShort: (short)value
{
	if (value >= 0)
		return [self initWithUnsignedShort: value];
	if (value >= SCHAR_MIN)
		return [self initWithChar: (signed char)value];

	return (id)[[OFNumber of_alloc] initWithShort: value];
}

- (instancetype)initWithInt: (int)value
{
	if (value >= 0)
		return [self initWithUnsignedInt: value];
	if (value >= SHRT_MIN)
		return [self initWithShort: (short)value];

	return (id)[[OFNumber of_alloc] initWithInt: value];
}

- (instancetype)initWithLong: (long)value
{
	if (value >= 0)
		return [self initWithUnsignedLong: value];
	if (value >= INT_MIN)
		return [self initWithShort: (int)value];

	return (id)[[OFNumber of_alloc] initWithLong: value];
}

- (instancetype)initWithLongLong: (long long)value
{
	if (value >= 0)
		return [self initWithUnsignedLongLong: value];
	if (value >= LONG_MIN)
		return [self initWithLong: (long)value];

	return (id)[[OFNumber of_alloc] initWithLongLong: value];
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	switch (value) {
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

	return (id)[[OFNumber of_alloc] initWithUnsignedChar: value];
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	if (value <= UCHAR_MAX)
		return [self initWithUnsignedChar: (unsigned char)value];

	return (id)[[OFNumber of_alloc] initWithUnsignedShort: value];
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	if (value <= USHRT_MAX)
		return [self initWithUnsignedShort: (unsigned short)value];

	return (id)[[OFNumber of_alloc] initWithUnsignedInt: value];
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	if (value <= UINT_MAX)
		return [self initWithUnsignedInt: (unsigned int)value];

	return (id)[[OFNumber of_alloc] initWithUnsignedLong: value];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	if (value <= ULONG_MAX)
		return [self initWithUnsignedLong: (unsigned long)value];

	return (id)[[OFNumber of_alloc] initWithUnsignedLongLong: value];
}

- (instancetype)initWithInt8: (int8_t)value
{
	if (value >= 0)
		return [self initWithUInt8: value];

	return (id)[[OFNumber of_alloc] initWithInt8: value];
}

- (instancetype)initWithInt16: (int16_t)value
{
	if (value >= 0)
		return [self initWithUInt16: value];
	if (value >= INT8_MIN)
		return [self initWithInt8: (int8_t)value];

	return (id)[[OFNumber of_alloc] initWithInt16: value];
}

- (instancetype)initWithInt32: (int32_t)value
{
	if (value >= 0)
		return [self initWithUInt32: value];
	if (value >= INT16_MIN)
		return [self initWithInt16: (int16_t)value];

	return (id)[[OFNumber of_alloc] initWithInt32: value];
}

- (instancetype)initWithInt64: (int64_t)value
{
	if (value >= 0)
		return [self initWithUInt64: value];
	if (value >= INT32_MIN)
		return [self initWithInt32: (int32_t)value];

	return (id)[[OFNumber of_alloc] initWithInt64: value];
}

- (instancetype)initWithUInt8: (uint8_t)value
{
	return (id)[[OFNumber of_alloc] initWithUInt8: value];
}

- (instancetype)initWithUInt16: (uint16_t)value
{
	if (value <= UINT8_MAX)
		return [self initWithUInt8: (uint8_t)value];

	return (id)[[OFNumber of_alloc] initWithUInt16: value];
}

- (instancetype)initWithUInt32: (uint32_t)value
{
	if (value <= UINT16_MAX)
		return [self initWithUInt16: (uint16_t)value];

	return (id)[[OFNumber of_alloc] initWithUInt32: value];
}

- (instancetype)initWithUInt64: (uint64_t)value
{
	if (value <= UINT32_MAX)
		return [self initWithUInt32: (uint32_t)value];

	return (id)[[OFNumber of_alloc] initWithUInt64: value];
}

- (instancetype)initWithSize: (size_t)value
{
	if (value <= ULONG_MAX)
		return [self initWithUnsignedLong: (unsigned long)value];

	return (id)[[OFNumber of_alloc] initWithSize: value];
}

#ifdef __clang__
/*
 * This warning should probably not exist at all, as it prevents checking
 * whether one type fits into another in a portable way.
 */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wtautological-constant-out-of-range-compare"
#endif

- (instancetype)initWithPtrDiff: (ptrdiff_t)value
{
	if (value >= LLONG_MIN && value <= LLONG_MAX)
		return [self initWithLongLong: (long long)value];

	return (id)[[OFNumber of_alloc] initWithPtrDiff: value];
}

- (instancetype)initWithIntPtr: (intptr_t)value
{
	if (value >= 0)
		return [self initWithUIntPtr: value];
	if (value >= LLONG_MIN)
		return [self initWithLongLong: (long long)value];

	return (id)[[OFNumber of_alloc] initWithIntPtr: value];
}

- (instancetype)initWithUIntPtr: (uintptr_t)value
{
	if (value <= ULLONG_MAX)
		return [self initWithUnsignedLongLong:
		    (unsigned long long)value];

	return (id)[[OFNumber of_alloc] initWithUIntPtr: value];
}

#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithFloat: (float)value
{
	if (value == (unsigned long long)value)
		return [self initWithUnsignedLongLong:
		    (unsigned long long)value];
	if (value == (long long)value)
		return [self initWithLongLong: (long long)value];

	return (id)[[OFNumber of_alloc] initWithFloat: value];
}

- (instancetype)initWithDouble: (double)value
{
	if (value == (unsigned long long)value)
		return [self initWithUnsignedLongLong:
		    (unsigned long long)value];
	if (value == (long long)value)
		return [self initWithLongLong: (long long)value];
	if (value == (float)value)
		return [self initWithFloat: (float)value];

	return (id)[[OFNumber of_alloc] initWithDouble: value];
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

+ (instancetype)numberWithBool: (bool)value
{
	return [[[self alloc] initWithBool: value] autorelease];
}

+ (instancetype)numberWithChar: (signed char)value
{
	return [[[self alloc] initWithChar: value] autorelease];
}

+ (instancetype)numberWithShort: (short)value
{
	return [[[self alloc] initWithShort: value] autorelease];
}

+ (instancetype)numberWithInt: (int)value
{
	return [[[self alloc] initWithInt: value] autorelease];
}

+ (instancetype)numberWithLong: (long)value
{
	return [[[self alloc] initWithLong: value] autorelease];
}

+ (instancetype)numberWithLongLong: (long long)value
{
	return [[[self alloc] initWithLongLong: value] autorelease];
}

+ (instancetype)numberWithUnsignedChar: (unsigned char)value
{
	return [[[self alloc] initWithUnsignedChar: value] autorelease];
}

+ (instancetype)numberWithUnsignedShort: (unsigned short)value
{
	return [[[self alloc] initWithUnsignedShort: value] autorelease];
}

+ (instancetype)numberWithUnsignedInt: (unsigned int)value
{
	return [[[self alloc] initWithUnsignedInt: value] autorelease];
}

+ (instancetype)numberWithUnsignedLong: (unsigned long)value
{
	return [[[self alloc] initWithUnsignedLong: value] autorelease];
}

+ (instancetype)numberWithUnsignedLongLong: (unsigned long long)value
{
	return [[[self alloc] initWithUnsignedLongLong: value] autorelease];
}

+ (instancetype)numberWithInt8: (int8_t)value
{
	return [[[self alloc] initWithInt8: value] autorelease];
}

+ (instancetype)numberWithInt16: (int16_t)value
{
	return [[[self alloc] initWithInt16: value] autorelease];
}

+ (instancetype)numberWithInt32: (int32_t)value
{
	return [[[self alloc] initWithInt32: value] autorelease];
}

+ (instancetype)numberWithInt64: (int64_t)value
{
	return [[[self alloc] initWithInt64: value] autorelease];
}

+ (instancetype)numberWithUInt8: (uint8_t)value
{
	return [[[self alloc] initWithUInt8: value] autorelease];
}

+ (instancetype)numberWithUInt16: (uint16_t)value
{
	return [[[self alloc] initWithUInt16: value] autorelease];
}

+ (instancetype)numberWithUInt32: (uint32_t)value
{
	return [[[self alloc] initWithUInt32: value] autorelease];
}

+ (instancetype)numberWithUInt64: (uint64_t)value
{
	return [[[self alloc] initWithUInt64: value] autorelease];
}

+ (instancetype)numberWithSize: (size_t)value
{
	return [[[self alloc] initWithSize: value] autorelease];
}

+ (instancetype)numberWithPtrDiff: (ptrdiff_t)value
{
	return [[[self alloc] initWithPtrDiff: value] autorelease];
}

+ (instancetype)numberWithIntPtr: (intptr_t)value
{
	return [[[self alloc] initWithIntPtr: value] autorelease];
}

+ (instancetype)numberWithUIntPtr: (uintptr_t)value
{
	return [[[self alloc] initWithUIntPtr: value] autorelease];
}

+ (instancetype)numberWithFloat: (float)value
{
	return [[[self alloc] initWithFloat: value] autorelease];
}

+ (instancetype)numberWithDouble: (double)value
{
	return [[[self alloc] initWithDouble: value] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithBool: (bool)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(bool);

	return self;
}

- (instancetype)initWithChar: (signed char)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(signed char);

	return self;
}

- (instancetype)initWithShort: (short)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(short);

	return self;
}

- (instancetype)initWithInt: (int)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int);

	return self;
}

- (instancetype)initWithLong: (long)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(long);

	return self;
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(long long);

	return self;
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned short);

	return self;
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned int);

	return self;
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(unsigned long long);

	return self;
}

- (instancetype)initWithInt8: (int8_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int8_t);

	return self;
}

- (instancetype)initWithInt16: (int16_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int16_t);

	return self;
}

- (instancetype)initWithInt32: (int32_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int32_t);

	return self;
}

- (instancetype)initWithInt64: (int64_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(int64_t);

	return self;
}

- (instancetype)initWithUInt8: (uint8_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint8_t);

	return self;
}

- (instancetype)initWithUInt16: (uint16_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint16_t);

	return self;
}

- (instancetype)initWithUInt32: (uint32_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint32_t);

	return self;
}

- (instancetype)initWithUInt64: (uint64_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uint64_t);

	return self;
}

- (instancetype)initWithSize: (size_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(size_t);

	return self;
}

- (instancetype)initWithPtrDiff: (ptrdiff_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(ptrdiff_t);

	return self;
}

- (instancetype)initWithIntPtr: (intptr_t)value
{
	self = [super init];

	_value.signed_ = value;
	_type = OF_NUMBER_TYPE_SIGNED;
	_typeEncoding = @encode(intptr_t);

	return self;
}

- (instancetype)initWithUIntPtr: (uintptr_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_type = OF_NUMBER_TYPE_UNSIGNED;
	_typeEncoding = @encode(uintptr_t);

	return self;
}

- (instancetype)initWithFloat: (float)value
{
	self = [super init];

	_value.float_ = value;
	_type = OF_NUMBER_TYPE_FLOAT;
	_typeEncoding = @encode(float);

	return self;
}

- (instancetype)initWithDouble: (double)value
{
	self = [super init];

	_value.float_ = value;
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
		} else if ([typeString isEqual: @"float"]) {
			unsigned long long value =
			    [element unsignedLongLongValueWithBase: 16];

			if (value > UINT64_MAX)
				@throw [OFOutOfRangeException exception];

			self = [self initWithDouble: OF_BSWAP_DOUBLE_IF_LE(
			    OF_INT_TO_DOUBLE_RAW(OF_BSWAP64_IF_LE(value)))];
		} else if ([typeString isEqual: @"signed"])
			self = [self initWithLongLong: element.longLongValue];
		else if ([typeString isEqual: @"unsigned"])
			self = [self initWithUnsignedLongLong:
			    element.unsignedLongLongValue];
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
		return (number.longLongValue == self.longLongValue);

	return (number.unsignedLongLongValue == self.unsignedLongLongValue);
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
		long long int1 = self.longLongValue;
		long long int2 = number.longLongValue;

		if (int1 > int2)
			return OF_ORDERED_DESCENDING;
		if (int1 < int2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else {
		unsigned long long uint1 = self.unsignedLongLongValue;
		unsigned long long uint2 = number.unsignedLongLongValue;

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
		long long value = self.longLongValue * -1;

		while (value != 0) {
			OF_HASH_ADD(hash, value & 0xFF);
			value >>= 8;
		}

		OF_HASH_ADD(hash, 1);
	} else if (type == OF_NUMBER_TYPE_UNSIGNED) {
		unsigned long long value = self.unsignedLongLongValue;

		while (value != 0) {
			OF_HASH_ADD(hash, value & 0xFF);
			value >>= 8;
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
		return [OFString stringWithFormat: @"%lld", _value.signed_];
	if (_type == OF_NUMBER_TYPE_UNSIGNED)
		return [OFString stringWithFormat: @"%llu", _value.unsigned_];

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
		long long value = self.longLongValue;

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
		unsigned long long value = self.unsignedLongLongValue;

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
