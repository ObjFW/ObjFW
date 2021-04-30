/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
	return [[[self alloc] initWithLongLong: value] autorelease];
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
		[self release];
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
