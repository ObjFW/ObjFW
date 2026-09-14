/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
#import "OFCountedSet.h"
#import "OFUnparsedASN1Value.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

enum {
	tagConstructedMask = 0x20
};

int _OFData_DERParsing_reference;

static size_t parseValue(OFData *self, OF_KINDOF(OFASN1Value *) *value,
    size_t depthLimit);

static OFASN1Sequence *
parseSequence(OFData *contents, size_t depthLimit)
{
	OFMutableArray *components = [OFMutableArray array];
	size_t count = contents.count;

	if (depthLimit == 0)
		@throw [OFOutOfRangeException exception];

	while (count > 0) {
		OF_KINDOF(OFASN1Value *) value;
		size_t valueLength;

		valueLength = parseValue(contents, &value, depthLimit);

		count -= valueLength;
		contents = [contents subdataWithRange:
		    OFMakeRange(valueLength, count)];

		[components addObject: value];
	}

	[components makeImmutable];

	return [OFASN1Sequence sequenceWithComponents: components];
}

static OFASN1Set *
parseSet(OFData *contents, size_t depthLimit)
{
	OFCountedSet *components = [OFCountedSet set];
	size_t count = contents.count;
	OFData *previousValueData = nil;

	if (depthLimit == 0)
		@throw [OFOutOfRangeException exception];

	while (count > 0) {
		OF_KINDOF(OFASN1Value *) value;
		size_t valueLength;
		OFData *valueData;

		valueLength = parseValue(contents, &value, depthLimit);
		valueData = [contents subdataWithRange:
		    OFMakeRange(0, valueLength)];

		if (previousValueData != nil &&
		    [valueData compare: previousValueData] ==
		    OFOrderedAscending)
			@throw [OFInvalidFormatException exception];

		count -= valueLength;
		contents = [contents subdataWithRange:
		    OFMakeRange(valueLength, count)];

		[components addObject: value];

		previousValueData = valueData;
	}

	[components makeImmutable];

	return [OFASN1Set setWithComponents: components];
}

static size_t
parseValue(OFData *self, OF_KINDOF(OFASN1Value *) *value, size_t depthLimit)
{
	const unsigned char *items = self.items;
	size_t count = self.count;
	unsigned char tag;
	size_t contentsLength, bytesConsumed = 0;
	Class valueClass;
	OFData *contents;

	if (count < 2)
		@throw [OFTruncatedDataException exception];

	tag = *items++;
	contentsLength = *items++;
	bytesConsumed += 2;

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

		/* TODO: Check that the shortest encoding is used */

		contentsLength = 0;

		for (uint_fast8_t i = 0; i < lengthLength; i++)
			contentsLength = (contentsLength << 8) | *items++;

		bytesConsumed += lengthLength;

		if (contentsLength <= 127)
			@throw [OFInvalidFormatException exception];
	}

	if (count - bytesConsumed < contentsLength)
		@throw [OFTruncatedDataException exception];

	contents = [self subdataWithRange:
	    OFMakeRange(bytesConsumed, contentsLength)];
	bytesConsumed += contentsLength;

	switch (tag & ~tagConstructedMask) {
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
		if (!(tag & tagConstructedMask))
			@throw [OFInvalidFormatException exception];

		*value = parseSequence(contents, depthLimit - 1);
		return bytesConsumed;
	case OFASN1TagNumberSet:
		if (!(tag & tagConstructedMask))
			@throw [OFInvalidFormatException exception];

		*value = parseSet(contents, depthLimit - 1);
		return bytesConsumed;
	case OFASN1TagNumberNumericString:
		valueClass = [OFASN1NumericString class];
		break;
	case OFASN1TagNumberPrintableString:
		valueClass = [OFASN1PrintableString class];
		break;
	case OFASN1TagNumberIA5String:
		valueClass = [OFASN1IA5String class];
		break;
	default:
		valueClass = [OFUnparsedASN1Value class];
		break;
	}

	@try {
		*value = objc_autorelease([[valueClass alloc]
		    of_initWithTagClass: tag >> 6
			      tagNumber: tag & 0x1F
			    constructed: tag & tagConstructedMask
		     DEREncodedContents: contents]);
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
