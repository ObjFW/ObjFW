/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include "config.h"

#include <inttypes.h>
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

@interface OFNumber ()
- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth;
@end

@implementation OFNumber
@synthesize type = _type;

+ (instancetype)numberWithBool: (bool)bool_
{
	return [[[self alloc] initWithBool: bool_] autorelease];
}

+ (instancetype)numberWithChar: (signed char)sChar
{
	return [[[self alloc] initWithChar: sChar] autorelease];
}

+ (instancetype)numberWithShort: (signed short)sShort
{
	return [[[self alloc] initWithShort: sShort] autorelease];
}

+ (instancetype)numberWithInt: (signed int)sInt
{
	return [[[self alloc] initWithInt: sInt] autorelease];
}

+ (instancetype)numberWithLong: (signed long)sLong
{
	return [[[self alloc] initWithLong: sLong] autorelease];
}

+ (instancetype)numberWithLongLong: (signed long long)sLongLong
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

- (instancetype)initWithShort: (signed short)sShort
{
	self = [super init];

	_value.sShort = sShort;
	_type = OF_NUMBER_TYPE_SHORT;

	return self;
}

- (instancetype)initWithInt: (signed int)sInt
{
	self = [super init];

	_value.sInt = sInt;
	_type = OF_NUMBER_TYPE_INT;

	return self;
}

- (instancetype)initWithLong: (signed long)sLong
{
	self = [super init];

	_value.sLong = sLong;
	_type = OF_NUMBER_TYPE_LONG;

	return self;
}

- (instancetype)initWithLongLong: (signed long long)sLongLong
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

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		typeString = [[element attributeForName: @"type"] stringValue];

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
			_value.uIntMax = [element decimalValue];
		} else if ([typeString isEqual: @"signed"]) {
			_type = OF_NUMBER_TYPE_INTMAX;
			_value.intMax = [element decimalValue];
		} else if ([typeString isEqual: @"float"]) {
			union {
				float f;
				uint32_t u;
			} f;

			f.u = OF_BSWAP32_IF_LE(
			    (uint32_t)[element hexadecimalValue]);

			_type = OF_NUMBER_TYPE_FLOAT;
			_value.float_ = OF_BSWAP_FLOAT_IF_LE(f.f);
		} else if ([typeString isEqual: @"double"]) {
			union {
				double d;
				uint64_t u;
			} d;

			d.u = OF_BSWAP64_IF_LE(
			    (uint64_t)[element hexadecimalValue]);

			_type = OF_NUMBER_TYPE_DOUBLE;
			_value.double_ = OF_BSWAP_DOUBLE_IF_LE(d.d);
		} else
			@throw [OFInvalidArgumentException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)boolValue
{
	RETURN_AS(bool)
}

- (signed char)charValue
{
	RETURN_AS(signed char)
}

- (signed short)shortValue
{
	RETURN_AS(signed short)
}

- (signed int)intValue
{
	RETURN_AS(signed int)
}

- (signed long)longValue
{
	RETURN_AS(signed long)
}

- (signed long long)longLongValue
{
	RETURN_AS(signed long long)
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
		double value1 = [number doubleValue];
		double value2 = [self doubleValue];

		if (isnan(value1) && isnan(value2))
			return true;
		if (isnan(value1) || isnan(value2))
			return false;

		return (value1 == value2);
	}

	if (_type & OF_NUMBER_TYPE_SIGNED ||
	    number->_type & OF_NUMBER_TYPE_SIGNED)
		return ([number intMaxValue] == [self intMaxValue]);

	return ([number uIntMaxValue] == [self uIntMaxValue]);
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFNumber *number;

	if (![(id)object isKindOfClass: [OFNumber class]])
		@throw [OFInvalidArgumentException exception];

	number = (OFNumber *)object;

	if (_type & OF_NUMBER_TYPE_FLOAT ||
	    number->_type & OF_NUMBER_TYPE_FLOAT) {
		double double1 = [self doubleValue];
		double double2 = [number doubleValue];

		if (double1 > double2)
			return OF_ORDERED_DESCENDING;
		if (double1 < double2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else if (_type & OF_NUMBER_TYPE_SIGNED ||
	    number->_type & OF_NUMBER_TYPE_SIGNED) {
		intmax_t int1 = [self intMaxValue];
		intmax_t int2 = [number intMaxValue];

		if (int1 > int2)
			return OF_ORDERED_DESCENDING;
		if (int1 < int2)
			return OF_ORDERED_ASCENDING;

		return OF_ORDERED_SAME;
	} else {
		uintmax_t uint1 = [self uIntMaxValue];
		uintmax_t uint2 = [number uIntMaxValue];

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
	if (type & OF_NUMBER_TYPE_SIGNED && [self intMaxValue] >= 0)
		type &= ~OF_NUMBER_TYPE_SIGNED;

	/* Do we really need floating point to represent this number? */
	if (type & OF_NUMBER_TYPE_FLOAT) {
		double v = [self doubleValue];

		if (v < 0) {
			if (v == [self intMaxValue]) {
				type &= ~OF_NUMBER_TYPE_FLOAT;
				type |= OF_NUMBER_TYPE_SIGNED;
			}
		} else {
			if (v == [self uIntMaxValue])
				type &= ~OF_NUMBER_TYPE_FLOAT;
		}
	}

	OF_HASH_INIT(hash);

	if (type & OF_NUMBER_TYPE_FLOAT) {
		union {
			double d;
			uint8_t b[sizeof(double)];
		} d;

		if (isnan([self doubleValue]))
			return 0;

		d.d = OF_BSWAP_DOUBLE_IF_BE([self doubleValue]);

		for (uint8_t i = 0; i < sizeof(double); i++)
			OF_HASH_ADD(hash, d.b[i]);
	} else if (type & OF_NUMBER_TYPE_SIGNED) {
		intmax_t v = [self intMaxValue] * -1;

		while (v != 0) {
			OF_HASH_ADD(hash, v & 0xFF);
			v >>= 8;
		}

		OF_HASH_ADD(hash, 1);
	} else {
		uintmax_t v = [self uIntMaxValue];

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
		return [OFString stringWithFormat: @"%ju", [self uIntMaxValue]];
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
		return [OFString stringWithFormat: @"%jd", [self intMaxValue]];
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

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS
				    stringValue: [self description]];

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
	case OF_NUMBER_TYPE_INTPTR:;
		[element addAttributeWithName: @"type"
				  stringValue: @"signed"];
		break;
	case OF_NUMBER_TYPE_FLOAT:;
		union {
			float f;
			uint32_t u;
		} f;

		f.f = OF_BSWAP_FLOAT_IF_LE(_value.float_);

		[element addAttributeWithName: @"type"
				  stringValue: @"float"];
		[element setStringValue:
		    [OFString stringWithFormat: @"%08" PRIx32,
						OF_BSWAP32_IF_LE(f.u)]];

		break;
	case OF_NUMBER_TYPE_DOUBLE:;
		union {
			double d;
			uint64_t u;
		} d;

		d.d = OF_BSWAP_DOUBLE_IF_LE(_value.double_);

		[element addAttributeWithName: @"type"
				  stringValue: @"double"];
		[element setStringValue:
		    [OFString stringWithFormat: @"%016" PRIx64,
						OF_BSWAP64_IF_LE(d.u)]];

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

	doubleValue = [self doubleValue];
	if (isinf(doubleValue)) {
		if (options & OF_JSON_REPRESENTATION_JSON5) {
			if (doubleValue > 0)
				return @"Infinity";
			else
				return @"-Infinity";
		} else
			@throw [OFInvalidArgumentException exception];
	}

	return [self description];
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
		intmax_t value = [self intMaxValue];

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
		uintmax_t value = [self uIntMaxValue];

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
