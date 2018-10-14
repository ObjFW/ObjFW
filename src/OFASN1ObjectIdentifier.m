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

#import "OFASN1ObjectIdentifier.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1ObjectIdentifier
@synthesize subidentifiers = _subidentifiers;

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
		const unsigned char *items = [_DEREncodedContents items];
		size_t count = [_DEREncodedContents count];
		OFMutableArray *subidentifiers = [OFMutableArray array];
		uintmax_t value = 0;
		uint_fast8_t bits = 0;

		if (_tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    _tagNumber != OF_ASN1_TAG_NUMBER_OBJECT_IDENTIFIER ||
		    _constructed)
			@throw [OFInvalidArgumentException exception];

		if (count == 0)
			@throw [OFInvalidFormatException exception];

		for (size_t i = 0; i < count; i++) {
			if (bits == 0 && items[i] == 0x80)
				@throw [OFInvalidFormatException exception];

			value = (value << 7) | (items[i] & 0x7F);
			bits += 7;

			if (bits > sizeof(uintmax_t) * 8)
				@throw [OFOutOfRangeException exception];

			if (items[i] & 0x80)
				continue;

			if ([subidentifiers count] == 0) {
				if (value < 40)
					[subidentifiers addObject:
					    [OFNumber numberWithUIntMax: 0]];
				else if (value < 80) {
					[subidentifiers addObject:
					    [OFNumber numberWithUIntMax: 1]];
					value -= 40;
				} else {
					[subidentifiers addObject:
					    [OFNumber numberWithUIntMax: 2]];
					value -= 80;
				}
			}

			[subidentifiers addObject:
			    [OFNumber numberWithUIntMax: value]];

			value = 0;
			bits = 0;
		}

		if (items[count - 1] & 0x80)
			@throw [OFInvalidFormatException exception];

		[subidentifiers makeImmutable];
		_subidentifiers = [subidentifiers copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_subidentifiers release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1ObjectIdentifier: %@>",
	    [_subidentifiers componentsJoinedByString: @"."]];
}
@end
