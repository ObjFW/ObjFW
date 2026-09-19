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

#import "OFData+DERParsing.h"
#import "OFASN1BMPString.h"
#import "OFASN1BitString.h"
#import "OFASN1Boolean.h"
#import "OFASN1Enumerated.h"
#import "OFASN1IA5String.h"
#import "OFASN1Integer.h"
#import "OFASN1Null.h"
#import "OFASN1NumericString.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFASN1OctetString.h"
#import "OFASN1PrintableString.h"
#import "OFASN1Sequence.h"
#import "OFASN1Set.h"
#import "OFASN1UTF8String.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFConstructedASN1Value.h"
#import "OFCountedSet.h"
#import "OFPrimitiveASN1Value.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

int _OFData_DERParsing_reference;

static size_t parseValue(OFData *self, OF_KINDOF(OFASN1Value *) *value,
    size_t depthLimit);

static OF_KINDOF(OFASN1Value *)
parseConstructed(OFData *rawValue, Class class, OFASN1TagClass tagClass,
    OFASN1TagNumber tagNumber, size_t depthLimit)
{
	OFMutableArray *components = [OFMutableArray array];
	size_t count = rawValue.count;

	if (depthLimit == 0)
		@throw [OFOutOfRangeException exception];

	while (count > 0) {
		OF_KINDOF(OFASN1Value *) value;
		size_t valueLength;

		valueLength = parseValue(rawValue, &value, depthLimit);

		count -= valueLength;
		rawValue = [rawValue subdataWithRange:
		    OFMakeRange(valueLength, count)];

		[components addObject: value];
	}

	[components makeImmutable];

	return objc_autoreleaseReturnValue(
	    [[class alloc] initWithComponents: components
				     tagClass: tagClass
				    tagNumber: tagNumber]);
}

static size_t
parseValue(OFData *self, OF_KINDOF(OFASN1Value *) *value, size_t depthLimit)
{
	const unsigned char *items = self.items;
	size_t count = self.count;
	unsigned char tag;
	size_t contentsLength, bytesConsumed = 0;

	if (count < 2)
		@throw [OFTruncatedDataException exception];

	tag = *items++;
	bytesConsumed++;
	OFASN1TagClass tagClass = tag >> 6;
	OFASN1TagNumber tagNumber = tag & 0x1F;
	bool constructed = tag & 0x20;

	if (tagNumber == 0x1F) {
		tagNumber = 0;

		if ((*items & 0x7F) == 0)
			@throw [OFInvalidFormatException exception];

		bool last;
		do {
			if (count - bytesConsumed < 2)
				@throw [OFTruncatedDataException exception];

			if (tagNumber > 0xFFFFFF)
				@throw [OFOutOfRangeException exception];

			last = !(*items & 0x80);
			tagNumber <<= 7;
			tagNumber |= *items++ & 0x7F;
			bytesConsumed++;
		} while (!last);

		if (tagNumber < 0x1F)
			@throw [OFInvalidFormatException exception];
	}

	contentsLength = *items++;
	bytesConsumed++;

	if (contentsLength > 127) {
		uint_fast8_t lengthLength = contentsLength & 0x7F;

		if (lengthLength > sizeof(size_t))
			@throw [OFOutOfRangeException exception];

		if (count - bytesConsumed < lengthLength)
			@throw [OFTruncatedDataException exception];

		if (lengthLength == 0 ||
		    (lengthLength == 1 && items[0] < 0x80) ||
		    (lengthLength >= 2 && items[0] == 0))
			@throw [OFInvalidFormatException exception];

		contentsLength = 0;

		for (uint_fast8_t i = 0; i < lengthLength; i++)
			contentsLength = (contentsLength << 8) | *items++;

		bytesConsumed += lengthLength;
	}

	if (count - bytesConsumed < contentsLength)
		@throw [OFTruncatedDataException exception];

	OFData *rawValue = [self subdataWithRange:
	    OFMakeRange(bytesConsumed, contentsLength)];
	bytesConsumed += contentsLength;

	Class valueClass;
	if (tagClass == OFASN1TagClassUniversal) {
		bool expectConstructed = false;

		switch (tagNumber) {
		case OFASN1TagNumberBoolean:
			valueClass = [OFASN1Boolean class];
			break;
		case OFASN1TagNumberInteger:
			valueClass = [OFASN1Integer class];
			break;
		case OFASN1TagNumberBitString:
			valueClass = [OFASN1BitString class];
			break;
		case OFASN1TagNumberOctetString:
			valueClass = [OFASN1OctetString class];
			break;
		case OFASN1TagNumberNull:
			valueClass = [OFASN1Null class];
			break;
		case OFASN1TagNumberObjectIdentifier:
			valueClass = [OFASN1ObjectIdentifier class];
			break;
		case OFASN1TagNumberEnumerated:
			valueClass = [OFASN1Enumerated class];
			break;
		case OFASN1TagNumberUTF8String:
			valueClass = [OFASN1UTF8String class];
			break;
		case OFASN1TagNumberSequence:
			valueClass = [OFASN1Sequence class];
			expectConstructed = true;
			break;
		case OFASN1TagNumberSet:
			valueClass = [OFASN1Set class];
			expectConstructed = true;
			break;
		case OFASN1TagNumberNumericString:
			valueClass = [OFASN1NumericString class];
			break;
		case OFASN1TagNumberPrintableString:
			valueClass = [OFASN1PrintableString class];
			break;
		case OFASN1TagNumberIA5String:
			valueClass = [OFASN1IA5String class];
			break;
		case OFASN1TagNumberBMPString:
			valueClass = [OFASN1BMPString class];
			break;
		default:
			if (constructed)
				valueClass = [OFConstructedASN1Value class];
			else
				valueClass = [OFPrimitiveASN1Value class];

			expectConstructed = constructed;
			break;
		}

		if (expectConstructed != constructed)
			@throw [OFInvalidFormatException exception];
	} else {
		if (constructed)
			valueClass = [OFConstructedASN1Value class];
		else
			valueClass = [OFPrimitiveASN1Value class];
	}

	@try {
		if (constructed)
			*value = parseConstructed(rawValue, valueClass,
			    tagClass, tagNumber, depthLimit - 1);
		else
			*value = objc_autorelease([[valueClass alloc]
			    initWithRawValue: rawValue
				    tagClass: tagClass
				   tagNumber: tagNumber]);
	} @catch (OFInvalidArgumentException *e) {
		@throw [OFInvalidFormatException exception];
	}

	return bytesConsumed;
}

@implementation OFData (DERParsing)
- (OF_KINDOF(OFASN1Value *))valueByParsingDER
{
	return [self valueByParsingDERWithDepthLimit: 32];
}

- (OF_KINDOF(OFASN1Value *))valueByParsingDERWithDepthLimit: (size_t)depthLimit
{
	void *pool = objc_autoreleasePoolPush();
	OF_KINDOF(OFASN1Value *) value;

	if (self.itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	if (parseValue(self, &value, depthLimit) != self.count)
		@throw [OFInvalidFormatException exception];

	objc_retain(value);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(value);
}
@end
