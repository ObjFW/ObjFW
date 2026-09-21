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

#import "OFASN1ObjectIdentifier.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1ObjectIdentifier
+ (instancetype)objectIdentifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	return objc_autoreleaseReturnValue([[self alloc] initWithArcs: arcs]);
}

+ (instancetype)objectIdentifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
				tagClass: (OFASN1TagClass)tagClass
			       tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithArcs: arcs
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	return [self initWithArcs: arcs
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberObjectIdentifier];
}

static void
addBase128ValueToData(OFMutableData *data, unsigned long long value)
{
	if (value <= 0x7F) {
		unsigned char byte = value & 0x7F;
		[data addItem: &byte];
		return;
	}

	size_t startPos = data.count;

	while (value > 0) {
		unsigned char byte = (value & 0x7F) | 0x80;
		value >>= 7;
		[data addItem: &byte];
	}

	size_t count = data.count - startPos;
	unsigned char *items = (unsigned char *)data.mutableItems + startPos;
	for (size_t i = 0, j = count - 1; i < count / 2; i++, j--) {
		items[i] ^= items[j];
		items[j] ^= items[i];
		items[i] ^= items[j];
	}

	items[count - 1] &= 0x7F;
}

- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFMutableData *rawValue;
	@try {
		size_t count = arcs.count;
		if (count < 2)
			@throw [OFInvalidFormatException exception];

		unsigned long long value;
		unsigned long long arc2 =
		    [[arcs objectAtIndex: 1] unsignedLongLongValue];
		switch ([[arcs objectAtIndex: 0]
		    unsignedLongLongValue]) {
		case 0:
			if (arc2 > 39)
				@throw [OFInvalidArgumentException exception];

			value = 0;
			break;
		case 1:
			if (arc2 > 39)
				@throw [OFInvalidArgumentException exception];

			value = 40;
			break;
		case 2:
			value = 80;
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		rawValue = [OFMutableData data];

		if (ULLONG_MAX - value < arc2)
			@throw [OFOutOfRangeException exception];

		addBase128ValueToData(rawValue, value + arc2);
		for (size_t i = 2; i < count; i++)
			addBase128ValueToData(rawValue,
			    [[arcs objectAtIndex: i] unsignedLongLongValue]);

		[rawValue makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithRawValue: rawValue
			     tagClass: tagClass
			    tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithRawValue: rawValue
			      tagClass: tagClass
			     tagNumber: tagNumber];

	@try {
		const unsigned char *items = rawValue.items;
		size_t count = rawValue.count;

		if (count == 0)
			@throw [OFInvalidArgumentException exception];

		bool first = true;
		for (size_t i = 0; i < count; i++) {
			if (first && items[i] == 0x80)
				@throw [OFInvalidFormatException exception];

			first = !(items[i] & 0x80);
		}

		if (items[count - 1] & 0x80)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	OFMutableArray OF_GENERIC(OFNumber *) *arcs =
	    [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	const unsigned char *items = _rawValue.items;
	size_t count = _rawValue.count;

	unsigned long long value = 0;
	uint_fast8_t bits = 0;
	for (size_t i = 0; i < count; i++) {
		if ((ULLONG_MAX >> 7) < value || UINT_FAST8_MAX - bits < 7)
			@throw [OFOutOfRangeException exception];

		value = (value << 7) | (items[i] & 0x7F);
		bits += 7;

		if (items[i] & 0x80)
			continue;

		if (arcs.count == 0) {
			if (value < 40)
				[arcs addObject: [OFNumber numberWithInt: 0]];
			else if (value < 80) {
				[arcs addObject: [OFNumber numberWithInt: 1]];
				value -= 40;
			} else {
				[arcs addObject: [OFNumber numberWithInt: 2]];
				value -= 80;
			}
		}

		[arcs addObject: [OFNumber numberWithUnsignedLongLong: value]];

		value = 0;
		bits = 0;
	}

	[arcs makeImmutable];

	objc_autoreleasePoolPop(pool);

	return arcs;
}

- (OFString *)description
{
	OFString *identifier = [self.arcs componentsJoinedByString: @"."];

	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]: %@>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), identifier];
}
@end
