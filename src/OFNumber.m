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

#include <math.h>

#import "OFNumber.h"
#import "OFConcreteNumber.h"
#import "OFData.h"
#import "OFJSONRepresentationPrivate.h"
#import "OFString.h"
#import "OFTaggedPointerNumber.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@interface OFNumber () <OFJSONRepresentationPrivate>
@end

@interface OFPlaceholderNumber: OFNumber
@end

@interface OFConcreteNumberSingleton: OFConcreteNumber
@end

static struct {
	Class isa;
} placeholder;

#define SINGLETON(var, sel, val)					\
	static OFConcreteNumberSingleton *var;				\
									\
	static void							\
	var##Init(void)							\
	{								\
		var = [[OFConcreteNumberSingleton alloc] sel val];	\
	}
SINGLETON(falseNumber, initWithBool:, false)
SINGLETON(trueNumber, initWithBool:, true)
SINGLETON(charZeroNumber, initWithChar:, 0)
SINGLETON(shortZeroNumber, initWithShort:, 0)
SINGLETON(intZeroNumber, initWithInt:, 0)
SINGLETON(longZeroNumber, initWithLong:, 0)
SINGLETON(longLongZeroNumber, initWithLongLong:, 0)
SINGLETON(unsignedCharZeroNumber, initWithUnsignedChar:, 0)
SINGLETON(unsignedShortZeroNumber, initWithUnsignedShort:, 0)
SINGLETON(unsignedIntZeroNumber, initWithUnsignedInt:, 0)
SINGLETON(unsignedLongZeroNumber, initWithUnsignedLong:, 0)
SINGLETON(unsignedLongLongZeroNumber, initWithUnsignedLongLong:, 0)
SINGLETON(floatZeroNumber, initWithFloat:, 0)
SINGLETON(doubleZeroNumber, initWithDouble:, 0)
#undef SINGLETON

static bool
isUnsigned(OFNumber *number)
{
	switch (*number.objCType) {
	case 'B':
	case 'C':
	case 'S':
	case 'I':
	case 'L':
	case 'Q':
		return true;
	default:
		return false;
	}
}

static bool
isSigned(OFNumber *number)
{
	switch (*number.objCType) {
	case 'c':
	case 's':
	case 'i':
	case 'l':
	case 'q':
		return true;
	default:
		return false;
	}
}

static bool
isFloat(OFNumber *number)
{
	switch (*number.objCType) {
	case 'f':
	case 'd':
		return true;
	default:
		return false;
	}
}

@implementation OFPlaceholderNumber
- (instancetype)initWithBool: (bool)value
{
	if (value) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, trueNumberInit);
		return (id)trueNumber;
	} else {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, falseNumberInit);
		return (id)falseNumber;
	}
}

#ifdef __clang__
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wtautological-constant-out-of-range-compare"
#endif
- (instancetype)initWithChar: (signed char)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, charZeroNumberInit);
		return (id)charZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned char)value <=
	    (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithChar: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithChar: value];
}

- (instancetype)initWithShort: (short)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, shortZeroNumberInit);
		return (id)shortZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned short)value <=
	    (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithShort: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithShort: value];
}

- (instancetype)initWithInt: (int)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, intZeroNumberInit);
		return (id)intZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned int)value <=
	    (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithInt: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithInt: value];
}

- (instancetype)initWithLong: (long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, longZeroNumberInit);
		return (id)longZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned long)value <=
	    (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithLong: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithLong: value];
}

- (instancetype)initWithLongLong: (long long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, longLongZeroNumberInit);
		return (id)longLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned long long)value <=
	    (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithLongLong: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithLongLong: value];
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedCharZeroNumberInit);
		return (id)unsignedCharZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithUnsignedChar: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithUnsignedChar: value];
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedShortZeroNumberInit);
		return (id)unsignedShortZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithUnsignedShort: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithUnsignedShort: value];
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedIntZeroNumberInit);
		return (id)unsignedIntZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithUnsignedInt: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithUnsignedInt: value];
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedLongZeroNumberInit);
		return (id)unsignedLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber numberWithUnsignedLong: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithUnsignedLong: value];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedLongLongZeroNumberInit);
		return (id)unsignedLongLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> OFTaggedPointerNumberTagBits)) {
		id ret = [OFTaggedPointerNumber
		    numberWithUnsignedLongLong: value];

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFConcreteNumber alloc] initWithUnsignedLongLong: value];
}

- (instancetype)initWithFloat: (float)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, floatZeroNumberInit);
		return (id)floatZeroNumber;
	}

	return (id)[[OFConcreteNumber alloc] initWithFloat: value];
}

- (instancetype)initWithDouble: (double)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, doubleZeroNumberInit);
		return (id)doubleZeroNumber;
	}

	return (id)[[OFConcreteNumber alloc] initWithDouble: value];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFConcreteNumberSingleton
OF_SINGLETON_METHODS
@end

@implementation OFNumber
+ (void)initialize
{
	if (self == [OFNumber class])
		object_setClass((id)&placeholder, [OFPlaceholderNumber class]);
}

+ (instancetype)alloc
{
	if (self == [OFNumber class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)valueWithPointer: (const void *)pointer
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)valueWithNonretainedObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)valueWithRange: (OFRange)range
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)valueWithPoint: (OFPoint)point
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)valueWithSize: (OFSize)size
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)valueWithRect: (OFRect)rect
{
	OF_UNRECOGNIZED_SELECTOR
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

+ (instancetype)numberWithFloat: (float)value
{
	return [[[self alloc] initWithFloat: value] autorelease];
}

+ (instancetype)numberWithDouble: (double)value
{
	return [[[self alloc] initWithDouble: value] autorelease];
}

- (instancetype)initWithBool: (bool)value
{
	return [self initWithBytes: &value objCType: @encode(bool)];
}

- (instancetype)initWithChar: (signed char)value
{
	return [self initWithBytes: &value objCType: @encode(signed char)];
}

- (instancetype)initWithShort: (short)value
{
	return [self initWithBytes: &value objCType: @encode(short)];
}

- (instancetype)initWithInt: (int)value
{
	return [self initWithBytes: &value objCType: @encode(int)];
}

- (instancetype)initWithLong: (long)value
{
	return [self initWithBytes: &value objCType: @encode(long)];
}

- (instancetype)initWithLongLong: (long long)value
{
	return [self initWithBytes: &value objCType: @encode(long long)];
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	return [self initWithBytes: &value objCType: @encode(unsigned char)];
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	return [self initWithBytes: &value objCType: @encode(unsigned short)];
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	return [self initWithBytes: &value objCType: @encode(unsigned int)];
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	return [self initWithBytes: &value objCType: @encode(unsigned long)];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	return [self initWithBytes: &value
			  objCType: @encode(unsigned long long)];
}

- (instancetype)initWithFloat: (float)value
{
	return [self initWithBytes: &value objCType: @encode(float)];
}

- (instancetype)initWithDouble: (double)value
{
	return [self initWithBytes: &value objCType: @encode(double)];
}

- (long long)longLongValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (unsigned long long)unsignedLongLongValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (double)doubleValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)boolValue
{
	return (bool)self.unsignedLongLongValue;
}

- (signed char)charValue
{
	return (signed char)self.longLongValue;
}

- (short)shortValue
{
	return (short)self.longLongValue;
}

- (int)intValue
{
	return (int)self.longLongValue;
}

- (long)longValue
{
	return (long)self.longLongValue;
}

- (unsigned char)unsignedCharValue
{
	return (unsigned char)self.unsignedLongLongValue;
}

- (unsigned short)unsignedShortValue
{
	return (unsigned short)self.unsignedLongLongValue;
}

- (unsigned int)unsignedIntValue
{
	return (unsigned int)self.unsignedLongLongValue;
}

- (unsigned long)unsignedLongValue
{
	return (unsigned long)self.unsignedLongLongValue;
}

- (float)floatValue
{
	return (float)self.doubleValue;
}

- (bool)isEqual: (id)object
{
	OFNumber *number;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFNumber class]])
		return false;

	number = object;

	if (isFloat(self) || isFloat(number)) {
		double value1 = number.doubleValue;
		double value2 = self.doubleValue;

		if (isnan(value1) && isnan(value2))
			return true;
		if (isnan(value1) || isnan(value2))
			return false;

		return (value1 == value2);
	}

	if (isSigned(self) || isSigned(number))
		return (number.longLongValue == self.longLongValue);

	return (number.unsignedLongLongValue == self.unsignedLongLongValue);
}

- (OFComparisonResult)compare: (OFNumber *)number
{
	if (![number isKindOfClass: [OFNumber class]])
		@throw [OFInvalidArgumentException exception];

	if (isFloat(self) || isFloat(number)) {
		double double1 = self.doubleValue;
		double double2 = number.doubleValue;

		if (double1 > double2)
			return OFOrderedDescending;
		if (double1 < double2)
			return OFOrderedAscending;

		return OFOrderedSame;
	} else if (isSigned(self) || isSigned(number)) {
		long long int1 = self.longLongValue;
		long long int2 = number.longLongValue;

		if (int1 > int2)
			return OFOrderedDescending;
		if (int1 < int2)
			return OFOrderedAscending;

		return OFOrderedSame;
	} else {
		unsigned long long uint1 = self.unsignedLongLongValue;
		unsigned long long uint2 = number.unsignedLongLongValue;

		if (uint1 > uint2)
			return OFOrderedDescending;
		if (uint1 < uint2)
			return OFOrderedAscending;

		return OFOrderedSame;
	}
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	if (isFloat(self)) {
		double d;

		if (isnan(self.doubleValue))
			return 0;

		d = OFToLittleEndianDouble(self.doubleValue);

		for (uint_fast8_t i = 0; i < sizeof(double); i++)
			OFHashAddByte(&hash, ((char *)&d)[i]);
	} else if (isSigned(self) || isUnsigned(self)) {
		unsigned long long value = self.unsignedLongLongValue;

		while (value != 0) {
			OFHashAddByte(&hash, value & 0xFF);
			value >>= 8;
		}
	} else
		@throw [OFInvalidFormatException exception];

	OFHashFinalize(&hash);

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
	if (self.objCType[0] == 'B' && self.objCType[1] == '\0')
		return (self.boolValue ? @"true" : @"false");
	if (isFloat(self))
		return [OFString stringWithFormat: @"%g", self.doubleValue];
	if (isSigned(self))
		return [OFString stringWithFormat: @"%lld", self.longLongValue];
	if (isUnsigned(self))
		return [OFString stringWithFormat: @"%llu",
						   self.unsignedLongLongValue];

	@throw [OFInvalidFormatException exception];
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0 depth: 0];
}

- (OFString *)JSONRepresentationWithOptions:
    (OFJSONRepresentationOptions)options
{
	return [self of_JSONRepresentationWithOptions: options depth: 0];
}

- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
			       depth: (size_t)depth
{
	double doubleValue;

	if (self.objCType[0] == 'B' && self.objCType[1] == '\0')
		return (self.boolValue ? @"true" : @"false");

	doubleValue = self.doubleValue;
	if (isinf(doubleValue)) {
		if (options & OFJSONRepresentationOptionJSON5) {
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
	const char *typeEncoding = self.objCType;

	if (typeEncoding[0] == '\0' || typeEncoding[1] != '\0')
		@throw [OFInvalidFormatException exception];

	if (*typeEncoding == 'B') {
		uint8_t type = (self.boolValue ? 0xC3 : 0xC2);
		data = [OFMutableData dataWithItems: &type count: 1];
	} else if (*typeEncoding == 'f') {
		uint8_t type = 0xCA;
		float tmp = OFToBigEndianFloat(self.floatValue);

		data = [OFMutableData dataWithCapacity: 5];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (*typeEncoding == 'd') {
		uint8_t type = 0xCB;
		double tmp = OFToBigEndianDouble(self.doubleValue);

		data = [OFMutableData dataWithCapacity: 9];
		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (isSigned(self)) {
		long long value = self.longLongValue;

		if (value >= -32 && value < 0) {
			uint8_t tmp = 0xE0 | ((uint8_t)(value - 32) & 0x1F);

			data = [OFMutableData dataWithItems: &tmp count: 1];
		} else if (value >= INT8_MIN && value <= INT8_MAX) {
			uint8_t type = 0xD0;
			int8_t tmp = (int8_t)value;

			data = [OFMutableData dataWithCapacity: 2];
			[data addItem: &type];
			[data addItem: &tmp];
		} else if (value >= INT16_MIN && value <= INT16_MAX) {
			uint8_t type = 0xD1;
			int16_t tmp = OFToBigEndian16((int16_t)value);

			data = [OFMutableData dataWithCapacity: 3];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else if (value >= INT32_MIN && value <= INT32_MAX) {
			uint8_t type = 0xD2;
			int32_t tmp = OFToBigEndian32((int32_t)value);

			data = [OFMutableData dataWithCapacity: 5];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else if (value >= INT64_MIN && value <= INT64_MAX) {
			uint8_t type = 0xD3;
			int64_t tmp = OFToBigEndian64((int64_t)value);

			data = [OFMutableData dataWithCapacity: 9];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else
			@throw [OFOutOfRangeException exception];
	} else if (isUnsigned(self)) {
		unsigned long long value = self.unsignedLongLongValue;

		if (value <= 127) {
			uint8_t tmp = ((uint8_t)value & 0x7F);
			data = [OFMutableData dataWithItems: &tmp count: 1];
		} else if (value <= UINT8_MAX) {
			uint8_t type = 0xCC;
			uint8_t tmp = (uint8_t)value;

			data = [OFMutableData dataWithCapacity: 2];
			[data addItem: &type];
			[data addItem: &tmp];
		} else if (value <= UINT16_MAX) {
			uint8_t type = 0xCD;
			uint16_t tmp = OFToBigEndian16((uint16_t)value);

			data = [OFMutableData dataWithCapacity: 3];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else if (value <= UINT32_MAX) {
			uint8_t type = 0xCE;
			uint32_t tmp = OFToBigEndian32((uint32_t)value);

			data = [OFMutableData dataWithCapacity: 5];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else if (value <= UINT64_MAX) {
			uint8_t type = 0xCF;
			uint64_t tmp = OFToBigEndian64((uint64_t)value);

			data = [OFMutableData dataWithCapacity: 9];
			[data addItem: &type];
			[data addItems: &tmp count: sizeof(tmp)];
		} else
			@throw [OFOutOfRangeException exception];
	} else
		@throw [OFInvalidFormatException exception];

	[data makeImmutable];

	return data;
}
@end
