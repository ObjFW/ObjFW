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

#import "OFASN1OctetString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1OctetString
@synthesize octetStringValue = _octetStringValue;

+ (instancetype)octetStringWithOctetStringValue: (OFData *)octetStringValue
{
	return [[[self alloc]
	    initWithOctetStringValue: octetStringValue] autorelease];
}

- (instancetype)initWithOctetStringValue: (OFData *)octetStringValue
{
	self = [super init];

	@try {
		_octetStringValue = [octetStringValue copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_OCTET_STRING ||
		    constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return [self initWithOctetStringValue: DEREncodedContents];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_octetStringValue release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1OctetString *octetString;

	if (![object isKindOfClass: [OFASN1OctetString class]])
		return false;

	octetString = object;

	if (![octetString->_octetStringValue isEqual: _octetStringValue])
		return false;

	return true;
}

- (uint32_t)hash
{
	return _octetStringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1OctetString: %@>",
					   _octetStringValue];
}
@end
