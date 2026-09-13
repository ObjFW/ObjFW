/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFASN1Boolean.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Boolean
@synthesize boolValue = _boolValue;

+ (instancetype)booleanWithBool: (bool)bool_
{
	return [[[self alloc] initWithBool: bool_] autorelease];
}

- (instancetype)initWithBool: (bool)bool_
{
	self = [super init];

	_boolValue = bool_;

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	unsigned char value;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberBoolean || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1 ||
		    DEREncodedContents.count != 1)
			@throw [OFInvalidFormatException exception];

		value = *(unsigned char *)[DEREncodedContents itemAtIndex: 0];

		if (value != 0 && value != 0xFF)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return [self initWithBool: !!value];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFData *)ASN1DERRepresentation
{
	char buffer[] = {
		OFASN1TagNumberBoolean,
		1,
		(_boolValue ? 0xFF : 0x00)
	};

	return [OFData dataWithItems: buffer count: sizeof(buffer)];
}

- (bool)isEqual: (id)object
{
	OFASN1Boolean *boolean;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1Boolean class]])
		return false;

	boolean = object;

	if (boolean->_boolValue != _boolValue)
		return false;

	return true;
}

- (unsigned long)hash
{
	return _boolValue;
}

- (OFString *)description
{
	return (_boolValue
	    ? @"<OFASN1Boolean: true>"
	    : @"<OFASN1Boolean: false>");
}
@end
