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
