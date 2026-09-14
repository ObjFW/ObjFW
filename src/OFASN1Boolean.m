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

#import "OFASN1Boolean.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Boolean
@synthesize boolValue = _boolValue;

+ (instancetype)booleanWithBool: (bool)bool_
{
	return objc_autoreleaseReturnValue([[self alloc] initWithBool: bool_]);
}

+ (instancetype)booleanWithBool: (bool)bool_
		       tagClass: (OFASN1TagClass)tagClass
		      tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithBool: bool_
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

- (instancetype)initWithBool: (bool)bool_
{
	return [self initWithBool: bool_
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberBoolean];
}

- (instancetype)initWithBool: (bool)bool_
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	_boolValue = bool_;

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	unsigned char value;

	@try {
		if (constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1 ||
		    DEREncodedContents.count != 1)
			@throw [OFInvalidFormatException exception];

		value = *(unsigned char *)[DEREncodedContents itemAtIndex: 0];

		if (value != 0 && value != 0xFF)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithBool: !!value
			 tagClass: tagClass
			tagNumber: tagNumber];
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (OFData *)DERRepresentation
{
	OFMutableData *data = [OFMutableData dataWithCapacity: 3];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, false, tag)];

	static const unsigned char one = 1;
	[data addItem: &one];

	unsigned char value = (_boolValue ? 0xFF : 0x00);
	[data addItem: &value];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return (_boolValue
	    ? @"<OFASN1Boolean: true>"
	    : @"<OFASN1Boolean: false>");
}
@end
