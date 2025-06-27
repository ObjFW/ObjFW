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

#import "OFData+ASN1DERParsing.h"
#import "OFASN1BitString.h"
#import "OFASN1Enumerated.h"
#import "OFASN1IA5String.h"
#import "OFASN1NumericString.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFASN1OctetString.h"
#import "OFASN1PrintableString.h"
#import "OFASN1Value.h"
#import "OFArray.h"
#import "OFNull.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"

enum {
	tagConstructedMask = 0x20
};

int _OFData_ASN1DERParsing_reference;

static size_t parseObject(OFData *self, id *object, size_t depthLimit);

long long
OFASN1DERIntegerParse(const unsigned char *buffer, size_t length)
{
	unsigned long long value = 0;

	/* TODO: Support for big numbers */
	if (length > sizeof(unsigned long long) &&
	    (length != sizeof(unsigned long long) + 1 || buffer[0] != 0))
		@throw [OFOutOfRangeException exception];

	if (length >= 2 && ((buffer[0] == 0 && !(buffer[1] & 0x80)) ||
	    (buffer[0] == 0xFF && buffer[1] & 0x80)))
		@throw [OFInvalidFormatException exception];

	if (length >= 1 && buffer[0] & 0x80)
		value = ~0ull;

	while (length--)
		value = (value << 8) | *buffer++;

	return value;
}

static OFArray *
parseSequence(OFData *contents, size_t depthLimit)
{
	OFMutableArray *ret = [OFMutableArray array];
	size_t count = contents.count;

	if (depthLimit == 0)
		@throw [OFOutOfRangeException exception];

	while (count > 0) {
		id object;
		size_t objectLength;

		objectLength = parseObject(contents, &object, depthLimit);

		count -= objectLength;
		contents = [contents subdataWithRange:
		    OFMakeRange(objectLength, count)];

		[ret addObject: object];
	}

	[ret makeImmutable];

	return ret;
}

static OFSet *
parseSet(OFData *contents, size_t depthLimit)
{
	OFMutableSet *ret = [OFMutableSet set];
	size_t count = contents.count;
	OFData *previousObjectData = nil;

	if (depthLimit == 0)
		@throw [OFOutOfRangeException exception];

	while (count > 0) {
		id object;
		size_t objectLength;
		OFData *objectData;

		objectLength = parseObject(contents, &object, depthLimit);
		objectData = [contents subdataWithRange:
		    OFMakeRange(0, objectLength)];

		if (previousObjectData != nil &&
		    [objectData compare: previousObjectData] !=
		    OFOrderedDescending)
			@throw [OFInvalidFormatException exception];

		count -= objectLength;
		contents = [contents subdataWithRange:
		    OFMakeRange(objectLength, count)];

		[ret addObject: object];

		previousObjectData = objectData;
	}

	[ret makeImmutable];

	return ret;
}

static size_t
parseObject(OFData *self, id *object, size_t depthLimit)
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
	case OFASN1TagNumberBoolean:;
		unsigned char boolValue;

		if (tag & tagConstructedMask)
			@throw [OFInvalidFormatException exception];

		if (contents.count != 1)
			@throw [OFInvalidFormatException exception];

		boolValue = *(unsigned char *)[contents itemAtIndex: 0];

		if (boolValue != 0 && boolValue != 0xFF)
			@throw [OFInvalidFormatException exception];

		*object = [OFNumber numberWithBool: boolValue];
		return bytesConsumed;
	case OFASN1TagNumberInteger:
		if (tag & tagConstructedMask)
			@throw [OFInvalidFormatException exception];

		*object = [OFNumber numberWithLongLong:
		    OFASN1DERIntegerParse(contents.items, contents.count)];
		return bytesConsumed;
	case OFASN1TagNumberBitString:
		valueClass = [OFASN1BitString class];
		break;
	case OFASN1TagNumberOctetString:
		valueClass = [OFASN1OctetString class];
		break;
	case OFASN1TagNumberNull:
		if (tag & tagConstructedMask)
			@throw [OFInvalidFormatException exception];

		if (contents.count != 0)
			@throw [OFInvalidFormatException exception];

		*object = [OFNull null];
		return bytesConsumed;
	case OFASN1TagNumberObjectIdentifier:
		valueClass = [OFASN1ObjectIdentifier class];
		break;
	case OFASN1TagNumberEnumerated:
		valueClass = [OFASN1Enumerated class];
		break;
	case OFASN1TagNumberUTF8String:
		if (tag & tagConstructedMask)
			@throw [OFInvalidFormatException exception];

		*object = [OFString stringWithUTF8String: contents.items
						  length: contents.count];
		return bytesConsumed;
	case OFASN1TagNumberSequence:
		if (!(tag & tagConstructedMask))
			@throw [OFInvalidFormatException exception];

		*object = parseSequence(contents, depthLimit - 1);
		return bytesConsumed;
	case OFASN1TagNumberSet:
		if (!(tag & tagConstructedMask))
			@throw [OFInvalidFormatException exception];

		*object = parseSet(contents, depthLimit - 1);
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
		valueClass = [OFASN1Value class];
		break;
	}

	*object = objc_autorelease(
	    [[valueClass alloc] initWithTagClass: tag >> 6
				       tagNumber: tag & 0x1F
				     constructed: tag & tagConstructedMask
			      DEREncodedContents: contents]);
	return bytesConsumed;
}

@implementation OFData (ASN1DERParsing)
- (id)objectByParsingASN1DER
{
	return [self objectByParsingASN1DERWithDepthLimit: 32];
}

- (id)objectByParsingASN1DERWithDepthLimit: (size_t)depthLimit
{
	void *pool = objc_autoreleasePoolPush();
	id object;

	if (self.itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	if (parseObject(self, &object, depthLimit) != self.count)
		@throw [OFInvalidFormatException exception];

	objc_retain(object);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(object);
}
@end
