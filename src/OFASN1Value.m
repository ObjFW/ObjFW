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

size_t
_OFASN1DEREncodeLength(size_t length, unsigned char buffer[9])
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
	} else
		@throw [OFOutOfRangeException exception];
}

@implementation OFASN1Value
@dynamic tagClass, tagNumber, constructed, DERRepresentation;

- (instancetype)init
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}
	}

	return [super init];
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}
	}

	return [super init];
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
	    @"\tConstructed = %u\n"
	    @">",
	    self.class, self.tagClass, self.tagNumber, self.constructed];
}
@end
