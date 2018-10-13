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

#import "OFASN1BitString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1BitString
@synthesize bitStringValue = _bitStringValue;
@synthesize bitStringLength = _bitStringLength;

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
		void *pool = objc_autoreleasePoolPush();
		unsigned char lastByteBits;
		size_t count = [_DEREncodedContents count];

		if (_tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    _tagNumber != OF_ASN1_TAG_NUMBER_BIT_STRING ||
		    _constructed)
			@throw [OFInvalidArgumentException exception];

		if (count == 0)
			@throw [OFInvalidFormatException exception];

		lastByteBits =
		    *(unsigned char *)[_DEREncodedContents itemAtIndex: 0];

		if (count == 1 && lastByteBits != 0)
			@throw [OFInvalidFormatException exception];

		if (SIZE_MAX / 8 < count - 1 ||
		    SIZE_MAX - (count - 1) * 8 < lastByteBits)
			@throw [OFOutOfRangeException exception];

		_bitStringLength = (count - 1) * 8 + lastByteBits;
		_bitStringValue = [[_DEREncodedContents
		    subdataWithRange: of_range(1, count - 1)] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_bitStringValue release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1BitString: %@ (%zu bits)>",
					   _bitStringValue, _bitStringLength];
}
@end
