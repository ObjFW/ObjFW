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

#import "OFASN1NumericString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFOnce.h"
#import "OFString.h"

#import "OFInvalidEncodingException.h"

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
	void *pool = objc_autoreleasePoolPush();

	OFData *DEREncodedContents;
	@try {
		const char *cString =
		    [string insecureCStringWithEncoding: OFStringEncodingASCII];
		size_t cStringLength =
		    [string cStringLengthWithEncoding: OFStringEncodingASCII];
		DEREncodedContents = [OFData dataWithItems: cString
						     count: cStringLength];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: tagClass
				      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	@try {
		void *pool = objc_autoreleasePoolPush();

		OFString *string = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OFStringEncodingASCII
			       length: DEREncodedContents.count];
		if ([string rangeOfCharacterFromSet: [OFCharacterSet
		    ASN1NumericStringCharacterSet].invertedSet].location !=
		    OFNotFound)
			@throw [OFInvalidEncodingException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];
}

- (OFString *)stringValue
{
	return [OFString stringWithCString: _DEREncodedContents.items
				  encoding: OFStringEncodingASCII
				    length: _DEREncodedContents.count];
}
@end
