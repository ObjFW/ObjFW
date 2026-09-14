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

#import "OFASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

unsigned char _OFDEREncodeTag(OFASN1TagClass tagClass,
    OFASN1TagNumber tagNumber, bool constructed)
{
	unsigned char tag = (tagClass << 6) | tagNumber;

	if (constructed)
		tag |= 0x20;

	return tag;
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
	if (length == 0)
		@throw [OFInvalidFormatException exception];

	if (length > sizeof(int64_t))
		@throw [OFOutOfRangeException exception];

	uint64_t unsignedValue = 0;
	if (buffer[0] & 0x80)
		unsignedValue = ~0ull;

	for (size_t i = 0; i < length; i++)
		unsignedValue = (unsignedValue << 8) | *buffer++;

	int64_t value = unsignedValue;
	size_t expectedLength;
	if (value >= -128 && value <= 127)
		expectedLength = 1;
	else if (value >= -32768 && value <= 32767)
		expectedLength = 2;
	else if (value >= -8388608 && value <= 8388607)
		expectedLength = 3;
	else if (value >= -2147483648 && value <= 2147483647)
		expectedLength = 4;
	else if (value >= -549755813888 && value <= 549755813887)
		expectedLength = 5;
	else if (value >= -140737488355328 && value <= 140737488355327)
		expectedLength = 6;
	else if (value >= -36028797018963968 && value <= 36028797018963967)
		expectedLength = 7;
	else
		expectedLength = 8;

	if (length != expectedLength)
		@throw [OFInvalidFormatException exception];

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
		objc_release(self);
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	self = [super init];

	_tagClass = tagClass;
	_tagNumber = tagNumber;

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		objc_release(self);
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	return [self initWithTagClass: tagClass tagNumber: tagNumber];
}

- (bool)isEqual: (id)object
{
	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	return [[object DERRepresentation] isEqual: self.DERRepresentation];
}

- (unsigned long)hash
{
	return self.DERRepresentation.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @">",
	    self.class, self.tagClass, self.tagNumber];
}
@end
