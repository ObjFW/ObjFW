/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@interface OFNumber ()
+ (instancetype)of_alloc;
- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
			       depth: (size_t)depth;
@end

@interface OFNumberPlaceholder: OFNumber
@end

@interface OFNumberSingleton: OFNumber
@end

#ifdef OF_OBJFW_RUNTIME
enum Tag {
	tagChar,
	tagShort,
	tagInt,
	tagLong,
	tagLongLong,
	tagUnsignedChar,
	tagUnsignedShort,
	tagUnsignedInt,
	tagUnsignedLong,
	tagUnsignedLongLong,
};
static const uint_fast8_t tagBits = 4;
static const uintptr_t tagMask = 0xF;

@interface OFTaggedPointerNumber: OFNumberSingleton
@end
#endif

static struct {
	Class isa;
} placeholder;

#define SINGLETON(var, sel, val)				\
	static OFNumberSingleton *var;				\
								\
	static void						\
	var##Init(void)						\
	{							\
		var = [[OFNumberSingleton alloc] sel val];	\
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

#ifdef OF_OBJFW_RUNTIME
static int numberTag;
#endif

static bool
isUnsigned(OFNumber *number)
{
	switch (*number.objCType) {
	case 'B':
		return true;
	case 'C':
		return true;
	case 'S':
		return true;
	case 'I':
		return true;
	case 'L':
		return true;
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
		return true;
	case 's':
		return true;
	case 'i':
		return true;
	case 'l':
		return true;
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
		return true;
	case 'd':
		return true;
	default:
		return false;
	}
}

@implementation OFNumberPlaceholder
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
	} else if ((unsigned char)value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)(unsigned char)value << tagBits) | tagChar);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithChar: value];
}

- (instancetype)initWithShort: (short)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, shortZeroNumberInit);
		return (id)shortZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned short)value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)(unsigned short)value << tagBits) | tagShort);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithShort: value];
}

- (instancetype)initWithInt: (int)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, intZeroNumberInit);
		return (id)intZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned int)value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)(unsigned int)value << tagBits) | tagInt);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithInt: value];
}

- (instancetype)initWithLong: (long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, longZeroNumberInit);
		return (id)longZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned long)value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)(unsigned long)value << tagBits) | tagLong);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithLong: value];
}

- (instancetype)initWithLongLong: (long long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, longLongZeroNumberInit);
		return (id)longLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if ((unsigned long long)value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)(unsigned long long)value << tagBits) |
		    tagLongLong);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithLongLong: value];
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedCharZeroNumberInit);
		return (id)unsignedCharZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)value << tagBits) | tagUnsignedChar);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedChar: value];
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedShortZeroNumberInit);
		return (id)unsignedShortZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)value << tagBits) | tagUnsignedShort);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedShort: value];
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedIntZeroNumberInit);
		return (id)unsignedIntZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)value << tagBits) | tagUnsignedInt);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedInt: value];
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedLongZeroNumberInit);
		return (id)unsignedLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)value << tagBits) | tagUnsignedLong);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedLong: value];
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, unsignedLongLongZeroNumberInit);
		return (id)unsignedLongLongZeroNumber;
#ifdef OF_OBJFW_RUNTIME
	} else if (value <= (UINTPTR_MAX >> tagBits)) {
		id ret = objc_createTaggedPointer(numberTag,
		    ((uintptr_t)value << tagBits) | tagUnsignedLongLong);

		if (ret != nil)
			return ret;
#endif
	}

	return (id)[[OFNumber of_alloc] initWithUnsignedLongLong: value];
}

- (instancetype)initWithFloat: (float)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, floatZeroNumberInit);
		return (id)floatZeroNumber;
	}

	return (id)[[OFNumber of_alloc] initWithFloat: value];
}

- (instancetype)initWithDouble: (double)value
{
	if (value == 0) {
		static OFOnceControl onceControl = OFOnceControlInitValue;
		OFOnce(&onceControl, doubleZeroNumberInit);
		return (id)doubleZeroNumber;
	}

	return (id)[[OFNumber of_alloc] initWithDouble: value];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif
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
	return OFMaxRetainCount;
}
@end

#ifdef OF_OBJFW_RUNTIME
@implementation OFTaggedPointerNumber
- (const char *)objCType
{
	uintptr_t value = object_getTaggedPointerValue(self);

	switch (value & tagMask) {
	case tagChar:
		return @encode(signed char);
	case tagShort:
		return @encode(short);
	case tagInt:
		return @encode(int);
	case tagLong:
		return @encode(long);
	case tagLongLong:
		return @encode(long long);
	case tagUnsignedChar:
		return @encode(unsigned char);
	case tagUnsignedShort:
		return @encode(unsigned short);
	case tagUnsignedInt:
		return @encode(unsigned int);
	case tagUnsignedLong:
		return @encode(unsigned long);
	case tagUnsignedLongLong:
		return @encode(unsigned long long);
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

# define RETURN_VALUE							  \
	uintptr_t value = object_getTaggedPointerValue(self);		  \
									  \
	switch (value & tagMask) {					  \
	case tagChar:							  \
		return (signed char)(unsigned char)(value >> tagBits);	  \
	case tagShort:							  \
		return (short)(unsigned short)(value >> tagBits);	  \
	case tagInt:							  \
		return (int)(unsigned int)(value >> tagBits);		  \
	case tagLong:							  \
		return (long)(unsigned long)(value >> tagBits);		  \
	case tagLongLong:						  \
		return (long long)(unsigned long long)(value >> tagBits); \
	case tagUnsignedChar:						  \
		return (unsigned char)(value >> tagBits);		  \
	case tagUnsignedShort:						  \
		return (unsigned short)(value >> tagBits);		  \
	case tagUnsignedInt:						  \
		return (unsigned int)(value >> tagBits);		  \
	case tagUnsignedLong:						  \
		return (unsigned long)(value >> tagBits);		  \
	case tagUnsignedLongLong:					  \
		return (unsigned long long)(value >> tagBits);		  \
	default:							  \
		@throw [OFInvalidArgumentException exception];		  \
	}
- (long long)longLongValue
{
	RETURN_VALUE
}

- (unsigned long long)unsignedLongLongValue
{
	RETURN_VALUE
}

- (double)doubleValue
{
	RETURN_VALUE
}
@end
# undef RETURN_VALUE
#endif

@implementation OFNumber
+ (void)initialize
{
	if (self != [OFNumber class])
		return;

	object_setClass((id)&placeholder, [OFNumberPlaceholder class]);

#ifdef OF_OBJFW_RUNTIME
	numberTag =
	    objc_registerTaggedPointerClass([OFTaggedPointerNumber class]);
#endif
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

+ (instancetype)valueWithBytes: (const void *)bytes
		      objCType: (const char *)objCType
{
	OF_UNRECOGNIZED_SELECTOR
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

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithBool: (bool)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(bool);

	return self;
}

- (instancetype)initWithChar: (signed char)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(signed char);

	return self;
}

- (instancetype)initWithShort: (short)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(short);

	return self;
}

- (instancetype)initWithInt: (int)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(int);

	return self;
}

- (instancetype)initWithLong: (long)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(long);

	return self;
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(long long);

	return self;
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(unsigned short);

	return self;
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(unsigned int);

	return self;
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(unsigned long long);

	return self;
}

- (instancetype)initWithPtrDiff: (ptrdiff_t)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(ptrdiff_t);

	return self;
}

- (instancetype)initWithIntPtr: (intptr_t)value
{
	self = [super init];

	_value.signed_ = value;
	_typeEncoding = @encode(intptr_t);

	return self;
}

- (instancetype)initWithUIntPtr: (uintptr_t)value
{
	self = [super init];

	_value.unsigned_ = value;
	_typeEncoding = @encode(uintptr_t);

	return self;
}

- (instancetype)initWithFloat: (float)value
{
	self = [super init];

	_value.float_ = value;
	_typeEncoding = @encode(float);

	return self;
}

- (instancetype)initWithDouble: (double)value
{
	self = [super init];

	_value.float_ = value;
	_typeEncoding = @encode(double);

	return self;
}

- (const char *)objCType
{
	return _typeEncoding;
}

- (void)getValue: (void *)value size: (size_t)size
{
	switch (*self.objCType) {
#define CASE(enc, type, property)					\
	case enc: {							\
		type tmp = (type)self.property;				\
									\
		if (size != sizeof(type))				\
			@throw [OFOutOfRangeException exception];	\
									\
		memcpy(value, &tmp, size);				\
		break;							\
	}
	CASE('B', bool, unsignedLongLongValue)
	CASE('c', signed char, longLongValue)
	CASE('s', short, longLongValue)
	CASE('i', int, longLongValue)
	CASE('l', long, longLongValue)
	CASE('q', long long, longLongValue)
	CASE('C', unsigned char, unsignedLongLongValue)
	CASE('S', unsigned short, unsignedLongLongValue)
	CASE('I', unsigned int, unsignedLongLongValue)
	CASE('L', unsigned long, unsignedLongLongValue)
	CASE('Q', unsigned long long, unsignedLongLongValue)
	CASE('f', float, doubleValue)
	CASE('d', double, doubleValue)
#undef CASE
	default:
		@throw [OFInvalidFormatException exception];
	}
}

- (long long)longLongValue
{
	if (isFloat(self))
		return _value.float_;
	else if (isSigned(self))
		return _value.signed_;
	else if (isUnsigned(self))
		return _value.unsigned_;
	else
		@throw [OFInvalidFormatException exception];
}

- (unsigned long long)unsignedLongLongValue
{
	if (isFloat(self))
		return _value.float_;
	else if (isSigned(self))
		return _value.signed_;
	else if (isUnsigned(self))
		return _value.unsigned_;
	else
		@throw [OFInvalidFormatException exception];
}

- (double)doubleValue
{
	if (isFloat(self))
		return _value.float_;
	else if (isSigned(self))
		return _value.signed_;
	else if (isUnsigned(self))
		return _value.unsigned_;
	else
		@throw [OFInvalidFormatException exception];
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
	if (*self.objCType == 'B')
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

	if (*self.objCType == 'B')
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
