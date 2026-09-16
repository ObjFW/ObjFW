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

#import "OFASN1Integer.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1Integer
@synthesize rawValue = _rawValue;

+ (instancetype)integerWithInt64: (int64_t)value
{
	return objc_autoreleaseReturnValue([[self alloc] initWithInt64: value]);
}

+ (instancetype)integerWithInt64: (int64_t)value
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithInt64: value
		 tagClass: tagClass
		tagNumber: tagNumber]);
}

+ (instancetype)integerWithRawValue: (OFData *)rawValue
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithRawValue: rawValue]);
}

+ (instancetype)integerWithRawValue: (OFData *)rawValue
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithRawValue: rawValue
		    tagClass: tagClass
		   tagNumber: tagNumber]);
}

- (instancetype)initWithInt64: (int64_t)value
{
	return [self initWithInt64: value
			  tagClass: OFASN1TagClassUniversal
			 tagNumber: OFASN1TagNumberInteger];
}

- (instancetype)initWithInt64: (int64_t)value
		     tagClass: (OFASN1TagClass)tagClass
		    tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *rawValue;
	@try {
		unsigned char buffer[8];
		size_t length = _OFDEREncodeInteger(value, buffer);
		rawValue = [OFData dataWithItems: buffer count: length];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithRawValue: rawValue
			     tagClass: tagClass
			    tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithRawValue: (OFData *)rawValue
{
	return [self initWithRawValue: rawValue
			     tagClass: OFASN1TagClassUniversal
			    tagNumber: OFASN1TagNumberInteger];
}

- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (rawValue.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		size_t count = rawValue.count;
		if (count == 0)
			@throw [OFInvalidFormatException exception];

		if (count >= 2) {
			const unsigned char *items = rawValue.items;
			if ((items[0] == 0 && !(items[1] & 0x80)) ||
			    (items[0] == 0xFF && (items[1] & 0x80)))
				@throw [OFInvalidFormatException exception];
		}

		_rawValue = [rawValue copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	if (constructed) {
		objc_release(self);
		@throw [OFInvalidArgumentException exception];
	}

	return [self initWithRawValue: DEREncodedContents
			     tagClass: tagClass
			    tagNumber: tagNumber];
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_rawValue);

	[super dealloc];
}

- (int64_t)int64Value
{
	return _OFDERDecodeInteger(_rawValue.items, _rawValue.count);
}

- (OFData *)DERRepresentation
{
	OFMutableData *data = [OFMutableData dataWithCapacity: 10];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, false, tag)];

	size_t count = _rawValue.count;
	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(count, length)];

	[data addItems: _rawValue.items count: count];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1Integer: %@>", _rawValue];
}
@end
