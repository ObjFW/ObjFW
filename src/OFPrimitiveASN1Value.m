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

#import "OFPrimitiveASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"

@implementation OFPrimitiveASN1Value
@synthesize rawValue = _rawValue;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (rawValue.itemSize != 1)
			@throw [OFInvalidFormatException exception];

		_rawValue = [rawValue copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_rawValue);

	[super dealloc];
}

- (OFData *)DERRepresentation
{
	size_t count = _rawValue.count;

	OFMutableData *data = [OFMutableData dataWithCapacity: count + 2];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, false, tag)];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(count, length)];
	[data addItems: _rawValue.items count: count];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %@\n"
	    @"\tTag number = %@\n"
	    @"\tRaw value = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _rawValue];
}

- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class
{
	if (![class isSubclassOfClass: [OFASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	@try {
		return objc_autoreleaseReturnValue(
		    [[class alloc] initWithRawValue: _rawValue
					   tagClass: _tagClass
					  tagNumber: _tagNumber]);
	} @catch (OFNotImplementedException *e) {
		@throw [OFInvalidArgumentException exception];
	}
}
@end
