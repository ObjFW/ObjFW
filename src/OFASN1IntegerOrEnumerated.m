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

#import "OFASN1IntegerOrEnumerated.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1IntegerOrEnumerated
@synthesize integerValue = _integerValue;

+ (instancetype)alloc
{
	if (self == [OFASN1IntegerOrEnumerated class])
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [super alloc];
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super initWithTagClass: tagClass
			     tagNumber: tagNumber
			   constructed: constructed
		    DEREncodedContents: DEREncodedContents];

	@try {
		const unsigned char *items = [_DEREncodedContents items];
		size_t count = [_DEREncodedContents count];
		uintmax_t value = 0;

		/* TODO: Support for big numbers */
		if (count > sizeof(uintmax_t) &&
		    (count != sizeof(uintmax_t) + 1 || items[0] != 0))
			@throw [OFOutOfRangeException exception];

		if (count >= 2 && ((items[0] == 0 && !(items[1] & 0x80)) ||
			(items[0] == 0xFF && items[1] & 0x80)))
			@throw [OFInvalidFormatException exception];

		if (count >= 1 && items[0] & 0x80)
			value = ~(uintmax_t)0;

		while (count--)
			value = (value << 8) | *items++;

		_integerValue = value;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %jd>",
					   [self class], _integerValue];
}
@end
