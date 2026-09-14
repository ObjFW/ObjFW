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

#import "OFASN1NumericString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFOnce.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfRangeException.h"

OF_DIRECT_MEMBERS
@interface OFASN1NumericStringCharacterSet: OFCharacterSet
@end

static OFCharacterSet *ASN1NumericStringCharacterSet;

static void
initASN1NumericStringCharacterSet(void)
{
	ASN1NumericStringCharacterSet =
	    [[OFASN1NumericStringCharacterSet alloc] init];
}

@implementation OFASN1NumericStringCharacterSet
OF_SINGLETON_METHODS

- (bool)characterIsMember: (OFUnichar)character
{
	if (character >= 0x80)
		return false;

	return (OFASCIIIsDigit(character) || character == ' ');
}
@end

@implementation OFCharacterSet (ASN1NumericStringCharacterSet)
+ (OFCharacterSet *)ASN1NumericStringCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initASN1NumericStringCharacterSet);

	return ASN1NumericStringCharacterSet;
}
@end

@implementation OFASN1NumericString
@synthesize stringValue = _string;

+ (instancetype)stringWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

+ (instancetype)stringWithString: (OFString *)string
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithString: string
		  tagClass: tagClass
		 tagNumber: tagNumber]);
}

- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberNumericString];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if ([string rangeOfCharacterFromSet: [OFCharacterSet
		    ASN1NumericStringCharacterSet].invertedSet].location !=
		    OFNotFound)
			@throw [OFInvalidEncodingException exception];

		_string = [string copy];

		objc_autoreleasePoolPop(pool);
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
	void *pool = objc_autoreleasePoolPush();

	OFString *string;
	@try {
		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		string = [OFString stringWithCString: DEREncodedContents.items
					    encoding: OFStringEncodingASCII
					      length: DEREncodedContents.count];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithString: string
			   tagClass: tagClass
			  tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_string);

	[super dealloc];
}

- (OFData *)DERRepresentation
{
	size_t cStringLength =
	    [_string cStringLengthWithEncoding: OFStringEncodingASCII];
	if (SIZE_MAX - cStringLength < 2)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data =
	    [OFMutableData dataWithCapacity: cStringLength + 2];
	unsigned char tag = _OFDEREncodeTag(_tagClass, _tagNumber, false);
	[data addItem: &tag];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(cStringLength, length)];
	[data addItems: [_string insecureCStringWithEncoding:
			    OFStringEncodingASCII]
		 count: cStringLength];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1NumericString: %@>",
					   _string];
}
@end
