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

#import "OFASN1Enumerated.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

extern long long OFASN1DERIntegerParse(const unsigned char *buffer,
    size_t length);

@implementation OFASN1Enumerated
@synthesize longLongValue = _longLongValue;

+ (instancetype)enumeratedWithLongLong: (long long)value
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithLongLong: value]);
}

- (instancetype)initWithLongLong: (long long)value
{
	self = [super init];

	_longLongValue = value;

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	long long value;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberEnumerated || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		value = OFASN1DERIntegerParse(
		    DEREncodedContents.items, DEREncodedContents.count);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithLongLong: value];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (bool)isEqual: (id)object
{
	OFASN1Enumerated *enumerated;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1Enumerated class]])
		return false;

	enumerated = object;

	if (enumerated->_longLongValue != _longLongValue)
		return false;

	return true;
}

- (unsigned long)hash
{
	return (unsigned long)_longLongValue;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Enumerated: %lld>",
					   _longLongValue];
}
@end
