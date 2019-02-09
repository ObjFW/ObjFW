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

+ (instancetype)objectIdentifierWithSubidentifiers:
    (OFArray OF_GENERIC(OFNumber *) *)subidentifiers
{
	return [[[self alloc]
	    initWithSubidentifiers: subidentifiers] autorelease];
}

- (instancetype)initWithSubidentifiers:
    (OFArray OF_GENERIC(OFNumber *) *)subidentifiers
{
	self = [super init];

	@try {
		if ([subidentifiers count] < 1)
			@throw [OFInvalidFormatException exception];

		switch ([[subidentifiers objectAtIndex: 0] intMaxValue]) {
		case 0:
		case 1:
		case 2:
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		_subidentifiers = [subidentifiers copy];
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
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFNumber *) *subidentifiers;

	@try {
		const unsigned char *items = [DEREncodedContents items];
		size_t count = [DEREncodedContents count];
		uintmax_t value = 0;
		uint_fast8_t bits = 0;

		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_OBJECT_IDENTIFIER ||
		    constructed)
			@throw [OFInvalidArgumentException exception];

		if ([DEREncodedContents itemSize] != 1 || count == 0)
			@throw [OFInvalidArgumentException exception];

		subidentifiers = [OFMutableArray array];

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
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithSubidentifiers: subidentifiers];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_subidentifiers release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1ObjectIdentifier *objectIdentifier;

	if (![object isKindOfClass: [OFASN1ObjectIdentifier class]])
		return false;

	objectIdentifier = object;

	if (![objectIdentifier->_subidentifiers isEqual: _subidentifiers])
		return false;

	return true;
}

- (uint32_t)hash
{
	return [_subidentifiers hash];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1ObjectIdentifier: %@>",
	    [_subidentifiers componentsJoinedByString: @"."]];
}
@end
