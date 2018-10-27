/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFASN1IA5String.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1IA5String
@synthesize IA5StringValue = _IA5StringValue;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_IA5_STRING || constructed)
			@throw [OFInvalidArgumentException exception];

		if ([DEREncodedContents itemSize] != 1)
			@throw [OFInvalidArgumentException exception];

		_IA5StringValue = [[OFString alloc]
		    initWithCString: [DEREncodedContents items]
			   encoding: OF_STRING_ENCODING_ASCII
			     length: [DEREncodedContents count]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_IA5StringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return [self IA5StringValue];
}

- (bool)isEqual: (id)object
{
	OFASN1IA5String *IA5String;

	if (![object isKindOfClass: [OFASN1IA5String class]])
		return false;

	IA5String = object;

	if (![IA5String->_IA5StringValue isEqual: _IA5StringValue])
		return false;

	return true;
}

- (uint32_t)hash
{
	return [_IA5StringValue hash];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1IA5String: %@>",
					   _IA5StringValue];
}
@end
