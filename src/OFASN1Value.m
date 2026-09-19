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

#import "OFASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

OFString *
OFASN1TagClassDescription(OFASN1TagClass tagClass)
{
	switch (tagClass) {
	case OFASN1TagClassUniversal:
		return @"Universal";
	case OFASN1TagClassApplication:
		return @"Application";
	case OFASN1TagClassContextSpecific:
		return @"Context specific";
	case OFASN1TagClassPrivate:
		return @"Private";
	}

	return [OFString stringWithFormat: @"%d", tagClass];
}

OFString *
OFASN1TagNumberDescription(OFASN1TagClass tagClass, OFASN1TagNumber tagNumber)
{
	if (tagClass == OFASN1TagClassUniversal) {
		switch (tagNumber) {
		case OFASN1TagNumberBoolean:
			return @"Boolean";
		case OFASN1TagNumberInteger:
			return @"Integer";
		case OFASN1TagNumberBitString:
			return @"Bit string";
		case OFASN1TagNumberOctetString:
			return @"Octet string";
		case OFASN1TagNumberNull:
			return @"Null";
		case OFASN1TagNumberObjectIdentifier:
			return @"Object Identifier";
		case OFASN1TagNumberEnumerated:
			return @"Enumerated";
		case OFASN1TagNumberUTF8String:
			return @"UTF-8 string";
		case OFASN1TagNumberSequence:
			return @"Sequence";
		case OFASN1TagNumberSet:
			return @"Set";
		case OFASN1TagNumberNumericString:
			return @"NumericString";
		case OFASN1TagNumberPrintableString:
			return @"PrintableString";
		case OFASN1TagNumberIA5String:
			return @"IA5String";
		case OFASN1TagNumberUniversalString:
			return @"UniversalString";
		case OFASN1TagNumberBMPString:
			return @"BMPString";
		}
	}

	return [OFString stringWithFormat: @"%d", tagClass];
}

size_t
_OFDEREncodeTag(OFASN1TagClass tagClass, OFASN1TagNumber tagNumber,
    bool constructed, unsigned char buffer[6])
{
	buffer[0] = tagClass << 6;

	if (constructed)
		buffer[0] |= 0x20;

	if (tagNumber < 0x1F) {
		buffer[0] |= tagNumber;
		return 1;
	} else
		buffer[0] |= 0x1F;

	if (tagNumber <= 0x7F) {
		buffer[1] = tagNumber;
		return 2;
	} else if (tagNumber <= 0x3FFF) {
		buffer[1] = (tagNumber >> 7) | 0x80;
		buffer[2] = tagNumber & 0x7F;
		return 3;
	} else if (tagNumber <= 0x1FFFFF) {
		buffer[1] = (tagNumber >> 14) | 0x80;
		buffer[2] = (tagNumber >> 7) | 0x80;
		buffer[3] = tagNumber & 0x7F;
		return 4;
	} else if (tagNumber <= 0xFFFFFFF) {
		buffer[1] = (tagNumber >> 21) | 0x80;
		buffer[2] = (tagNumber >> 14) | 0x80;
		buffer[3] = (tagNumber >> 7) | 0x80;
		buffer[4] = tagNumber & 0x7F;
		return 5;
	} else if (tagNumber <= 0x7FFFFFFF) {
		buffer[1] = (tagNumber >> 28) | 0x80;
		buffer[2] = (tagNumber >> 21) | 0x80;
		buffer[3] = (tagNumber >> 14) | 0x80;
		buffer[4] = (tagNumber >> 7) | 0x80;
		buffer[5] = tagNumber & 0x7F;
		return 6;
	} else
		@throw [OFOutOfRangeException exception];
}

size_t
_OFDEREncodeLength(size_t length, unsigned char buffer[9])
{
	if (length <= 127) {
		buffer[0] = length;
		return 1;
	} else if (length <= 255u) {
		buffer[0] = 0x81;
		buffer[1] = length;
		return 2;
	} else if (length <= 65535u) {
		buffer[0] = 0x82;
		buffer[1] = length >> 8;
		buffer[2] = length;
		return 3;
	} else if (length <= 16777215u) {
		buffer[0] = 0x83;
		buffer[1] = length >> 16;
		buffer[2] = length >> 8;
		buffer[3] = length;
		return 4;
	} else if (length <= 4294967295u) {
		buffer[0] = 0x84;
		buffer[1] = length >> 24;
		buffer[2] = length >> 16;
		buffer[3] = length >> 8;
		buffer[4] = length;
		return 5;
#if SIZE_MAX >= UINT64_MAX
	} else if (length <= 1099511627775u) {
		buffer[0] = 0x85;
		buffer[1] = length >> 32;
		buffer[2] = length >> 24;
		buffer[3] = length >> 16;
		buffer[4] = length >> 8;
		buffer[5] = length;
		return 6;
	} else if (length <= 281474976710655u) {
		buffer[0] = 0x86;
		buffer[1] = length >> 40;
		buffer[2] = length >> 32;
		buffer[3] = length >> 24;
		buffer[4] = length >> 16;
		buffer[5] = length >> 8;
		buffer[6] = length;
		return 7;
	} else if (length <= 72057594037927935u) {
		buffer[0] = 0x87;
		buffer[1] = length >> 48;
		buffer[2] = length >> 40;
		buffer[3] = length >> 32;
		buffer[4] = length >> 24;
		buffer[5] = length >> 16;
		buffer[6] = length >> 8;
		buffer[7] = length;
		return 8;
	} else if (length <= 18446744073709551615u) {
		buffer[0] = 0x88;
		buffer[1] = length >> 56;
		buffer[2] = length >> 48;
		buffer[3] = length >> 40;
		buffer[4] = length >> 32;
		buffer[5] = length >> 24;
		buffer[6] = length >> 16;
		buffer[7] = length >> 8;
		buffer[8] = length;
		return 9;
#endif
	} else
		@throw [OFOutOfRangeException exception];
}

int64_t
_OFDERDecodeInteger(const unsigned char *buffer, size_t length)
{
	if (length > sizeof(int64_t))
		@throw [OFOutOfRangeException exception];

	uint64_t value = 0;
	if (buffer[0] & 0x80)
		value = ~0ull;

	for (size_t i = 0; i < length; i++)
		value = (value << 8) | *buffer++;

	return value;
}

size_t
_OFDEREncodeInteger(int64_t value, unsigned char buffer[8])
{
	uint64_t unsignedValue = value;

	buffer[0] = (unsignedValue >> 56) & 0x80;

	if (value >= -128 && value <= 127) {
		buffer[0] |= unsignedValue;
		return 1;
	} else if (value >= -32768 && value <= 32767) {
		buffer[0] |= unsignedValue >> 8;
		buffer[1] = unsignedValue;
		return 2;
	} else if (value >= -8388608 && value <= 8388607) {
		buffer[0] |= unsignedValue >> 16;
		buffer[1] = unsignedValue >> 8;
		buffer[2] = unsignedValue;
		return 3;
	} else if (value >= -2147483648 && value <= 2147483647) {
		buffer[0] |= unsignedValue >> 24;
		buffer[1] = unsignedValue >> 16;
		buffer[2] = unsignedValue >> 8;
		buffer[3] = unsignedValue;
		return 4;
	} else if (value >= -549755813888 && value <= 549755813887) {
		buffer[0] |= unsignedValue >> 32;
		buffer[1] = unsignedValue >> 24;
		buffer[2] = unsignedValue >> 16;
		buffer[3] = unsignedValue >> 8;
		buffer[4] = unsignedValue;
		return 5;
	} else if (value >= -140737488355328 && value <= 140737488355327) {
		buffer[0] |= unsignedValue >> 40;
		buffer[1] = unsignedValue >> 32;
		buffer[2] = unsignedValue >> 24;
		buffer[3] = unsignedValue >> 16;
		buffer[4] = unsignedValue >> 8;
		buffer[5] = unsignedValue;
		return 6;
	} else if (value >= -36028797018963968 && value <= 36028797018963967) {
		buffer[0] |= unsignedValue >> 48;
		buffer[1] = unsignedValue >> 40;
		buffer[2] = unsignedValue >> 32;
		buffer[3] = unsignedValue >> 24;
		buffer[4] = unsignedValue >> 16;
		buffer[5] = unsignedValue >> 8;
		buffer[6] = unsignedValue;
		return 7;
	} else {
		buffer[0] = unsignedValue >> 56;
		buffer[1] = unsignedValue >> 48;
		buffer[2] = unsignedValue >> 40;
		buffer[3] = unsignedValue >> 32;
		buffer[4] = unsignedValue >> 24;
		buffer[5] = unsignedValue >> 16;
		buffer[6] = unsignedValue >> 8;
		buffer[7] = unsignedValue;
		return 8;
	}
}

@implementation OFASN1Value
@synthesize tagClass = _tagClass, tagNumber = _tagNumber;
@dynamic DERRepresentation;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	self = [super init];

	_tagClass = tagClass;
	_tagNumber = tagNumber;

	return self;
}

- (bool)isEqual: (id)object
{
	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	void *pool = objc_autoreleasePoolPush();
	bool equal =
	    [self.DERRepresentation isEqual: [object DERRepresentation]];
	objc_autoreleasePoolPop(pool);

	return equal;
}

- (OFComparisonResult)compare: (OFASN1Value *)value
{
	if (![value isKindOfClass: [OFASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	void *pool = objc_autoreleasePoolPush();
	OFComparisonResult result =
	    [self.DERRepresentation compare: value.DERRepresentation];
	objc_autoreleasePoolPop(pool);

	return result;
}

- (unsigned long)hash
{
	void *pool = objc_autoreleasePoolPush();
	unsigned long hash = self.DERRepresentation.hash;
	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %@\n"
	    @"\tTag number = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber)];
}
@end
