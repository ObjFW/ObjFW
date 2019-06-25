/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFASN1Boolean.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Boolean
@synthesize booleanValue = _booleanValue;

+ (instancetype)booleanWithBooleanValue: (bool)booleanValue
{
	return [[[self alloc] initWithBooleanValue: booleanValue] autorelease];
}

- (instancetype)initWithBooleanValue: (bool)booleanValue
{
	self = [super init];

	_booleanValue = booleanValue;

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	unsigned char value;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_BOOLEAN || constructed)
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

	return [self initWithBooleanValue: !!value];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFData *)ASN1DERRepresentation
{
	char buffer[] = {
		OF_ASN1_TAG_NUMBER_BOOLEAN,
		1,
		(_booleanValue ? 0xFF : 0x00)
	};

	return [OFData dataWithItems: buffer
			       count: sizeof(buffer)];
}

- (bool)isEqual: (id)object
{
	OFASN1Boolean *boolean;

	if (![object isKindOfClass: [OFASN1Boolean class]])
		return false;

	boolean = object;

	if (boolean->_booleanValue != _booleanValue)
		return false;

	return true;
}

- (uint32_t)hash
{
	return (uint32_t)_booleanValue;
}

- (OFString *)description
{
	return (_booleanValue
	    ? @"<OFASN1Boolean: true>"
	    : @"<OFASN1Boolean: false>");
}
@end
