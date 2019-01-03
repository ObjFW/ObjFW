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

#import "OFASN1NumericString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"

@implementation OFASN1NumericString
@synthesize numericStringValue = _numericStringValue;

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
		const unsigned char *items = [DEREncodedContents items];
		size_t count = [DEREncodedContents count];

		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_NUMERIC_STRING ||
		    constructed)
			@throw [OFInvalidArgumentException exception];

		if ([DEREncodedContents itemSize] != 1)
			@throw [OFInvalidArgumentException exception];

		for (size_t i = 0; i < count; i++)
			if (!of_ascii_isdigit(items[i]) && items[i] != ' ')
				@throw [OFInvalidEncodingException exception];

		_numericStringValue = [[OFString alloc]
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
	[_numericStringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return [self numericStringValue];
}

- (bool)isEqual: (id)object
{
	OFASN1NumericString *numericString;

	if (![object isKindOfClass: [OFASN1NumericString class]])
		return false;

	numericString = object;

	if (![numericString->_numericStringValue isEqual: _numericStringValue])
		return false;

	return true;
}

- (uint32_t)hash
{
	return [_numericStringValue hash];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1NumericString: %@>",
					   _numericStringValue];
}
@end
