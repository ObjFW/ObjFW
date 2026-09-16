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

#import "OFUnparsedASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"

@implementation OFUnparsedASN1Value
@synthesize constructed = _constructed;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidFormatException exception];

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

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, _constructed,
			    tag)];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(count, length)];
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

- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class
{
	if (![class isSubclassOfClass: [OFASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	@try {
		return objc_autoreleaseReturnValue([[class alloc]
		    of_initWithTagClass: _tagClass
			      tagNumber: _tagNumber
			    constructed: _constructed
		     DEREncodedContents: _DEREncodedContents]);
	} @catch (OFNotImplementedException *e) {
		@throw [OFInvalidArgumentException exception];
	}
}
@end
