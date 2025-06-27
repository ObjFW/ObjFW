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

#include <string.h>

#import "OFConcreteNumber.h"

#import "OFInvalidFormatException.h"

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

@implementation OFConcreteNumber
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
#define CASE(type, method)				\
	if (strcmp(objCType, @encode(type)) == 0) {	\
		type value;				\
		memcpy(&value, bytes, sizeof(type));	\
		return [self method value];		\
	}

	CASE(bool, initWithBool:)
	CASE(signed char, initWithChar:)
	CASE(short, initWithShort:)
	CASE(int, initWithInt:)
	CASE(long, initWithLong:)
	CASE(long long, initWithLongLong:)
	CASE(unsigned char, initWithUnsignedChar:)
	CASE(unsigned short, initWithUnsignedShort:)
	CASE(unsigned int, initWithUnsignedInt:)
	CASE(unsigned long, initWithUnsignedLong:)
	CASE(unsigned long long, initWithUnsignedLongLong:)
	CASE(float, initWithFloat:)
	CASE(double, initWithDouble:)

	objc_release(self);
	@throw [OFInvalidFormatException exception];
}

- (instancetype)initWithBool: (bool)value
{
	self = [super initWithBytes: &value objCType: @encode(bool)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(bool);

	return self;
}

- (instancetype)initWithChar: (signed char)value
{
	self = [super initWithBytes: &value objCType: @encode(signed char)];

	_value.signed_ = value;
	_typeEncoding = *@encode(signed char);

	return self;
}

- (instancetype)initWithShort: (short)value
{
	self = [super initWithBytes: &value objCType: @encode(short)];

	_value.signed_ = value;
	_typeEncoding = *@encode(short);

	return self;
}

- (instancetype)initWithInt: (int)value
{
	self = [super initWithBytes: &value objCType: @encode(int)];

	_value.signed_ = value;
	_typeEncoding = *@encode(int);

	return self;
}

- (instancetype)initWithLong: (long)value
{
	self = [super initWithBytes: &value objCType: @encode(long)];

	_value.signed_ = value;
	_typeEncoding = *@encode(long);

	return self;
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super initWithBytes: &value objCType: @encode(long long)];

	_value.signed_ = value;
	_typeEncoding = *@encode(long long);

	return self;
}

- (instancetype)initWithUnsignedChar: (unsigned char)value
{
	self = [super initWithBytes: &value objCType: @encode(unsigned char)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedShort: (unsigned short)value
{
	self = [super initWithBytes: &value objCType: @encode(unsigned short)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(unsigned short);

	return self;
}

- (instancetype)initWithUnsignedInt: (unsigned int)value
{
	self = [super initWithBytes: &value objCType: @encode(unsigned int)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(unsigned int);

	return self;
}

- (instancetype)initWithUnsignedLong: (unsigned long)value
{
	self = [super initWithBytes: &value objCType: @encode(unsigned long)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(unsigned long);

	return self;
}

- (instancetype)initWithUnsignedLongLong: (unsigned long long)value
{
	self = [super initWithBytes: &value
			   objCType: @encode(unsigned long long)];

	_value.unsigned_ = value;
	_typeEncoding = *@encode(unsigned long long);

	return self;
}

- (instancetype)initWithFloat: (float)value
{
	self = [super initWithBytes: &value objCType: @encode(float)];

	_value.float_ = value;
	_typeEncoding = *@encode(float);

	return self;
}

- (instancetype)initWithDouble: (double)value
{
	self = [super initWithBytes: &value objCType: @encode(double)];

	_value.float_ = value;
	_typeEncoding = *@encode(double);

	return self;
}

- (const char *)objCType
{
	return &_typeEncoding;
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
@end
