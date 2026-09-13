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

#import "OFASN1UnparsedValue.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1UnparsedValue
@synthesize tagClass = _tagClass, tagNumber = _tagNumber;
@synthesize constructed = _constructed;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidFormatException exception];

		_tagClass = tagClass;
		_tagNumber = tagNumber;
		_constructed = constructed;
		_DEREncodedContents = [DEREncodedContents copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_DEREncodedContents);

	[super dealloc];
}

- (OFData *)DERRepresentation
{
	size_t count = _DEREncodedContents.count;
	OFMutableData *data = [OFMutableData dataWithCapacity: count + 2];

	unsigned char tag = (_tagClass << 6) | (_tagNumber & 0x1F);
	if (_constructed)
		tag |= 0x20;
	[data addItem: &tag];

	unsigned char length[9];
	[data addItems: length
		 count: _OFASN1DEREncodeLength(count, length)];
	[data addItems: _DEREncodedContents.items count: count];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tConstructed = %u\n"
	    @"\tDER-encoded contents = %@\n"
	    @">",
	    self.class, _tagClass, _tagNumber, _constructed,
	    _DEREncodedContents];
}
@end
