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
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Value
@synthesize tagClass = _tagClass, tagNumber = _tagNumber;
@synthesize constructed = _constructed;
@synthesize DEREncodedContents = _DEREncodedContents;

+ (instancetype)valueWithTagClass: (OFASN1TagClass)tagClass
			tagNumber: (OFASN1TagNumber)tagNumber
		      constructed: (bool)constructed
	       DEREncodedContents: (OFData *)DEREncodedContents
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithTagClass: tagClass
				 tagNumber: tagNumber
			       constructed: constructed
			DEREncodedContents: DEREncodedContents]);
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
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

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_DEREncodedContents);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1Value *value;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	value = object;

	if (value->_tagClass != _tagClass)
		return false;
	if (value->_tagNumber != _tagNumber)
		return false;
	if (value->_constructed != _constructed)
		return false;
	if (![value->_DEREncodedContents isEqual: _DEREncodedContents])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddByte(&hash, _tagClass & 0xFF);
	OFHashAddByte(&hash, _tagNumber & 0xFF);
	OFHashAddByte(&hash, _constructed);
	OFHashAddHash(&hash, _DEREncodedContents.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1Value:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tConstructed = %u\n"
	    @"\tDER-encoded contents = %@\n"
	    @">",
	    _tagClass, _tagNumber, _constructed,
	    _DEREncodedContents.description];
}
@end
