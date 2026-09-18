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

#import "OFASN1PrintableString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFOnce.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfRangeException.h"

OF_DIRECT_MEMBERS
@interface OFASN1PrintableStringCharacterSet: OFCharacterSet
@end

static OFCharacterSet *ASN1PrintableStringCharacterSet;

static void
initASN1PrintableStringCharacterSet(void)
{
	ASN1PrintableStringCharacterSet =
	    [[OFASN1PrintableStringCharacterSet alloc] init];
}

@implementation OFASN1PrintableStringCharacterSet
OF_SINGLETON_METHODS

- (bool)characterIsMember: (OFUnichar)character
{
	if (character >= 0x80)
		return false;

	if (OFASCIIIsAlnum(character))
		return true;

	switch (character) {
	case ' ':
	case '\'':
	case '(':
	case ')':
	case '+':
	case ',':
	case '-':
	case '.':
	case '/':
	case ':':
	case '=':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFCharacterSet (ASN1PrintableStringCharacterSet)
+ (OFCharacterSet *)ASN1PrintableStringCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initASN1PrintableStringCharacterSet);

	return ASN1PrintableStringCharacterSet;
}
@end

@implementation OFASN1PrintableString
- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberPrintableString];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *rawValue;
	@try {
		if ([string rangeOfCharacterFromSet: [OFCharacterSet
		    ASN1PrintableStringCharacterSet].invertedSet].location !=
		    OFNotFound)
			@throw [OFInvalidEncodingException exception];

		const char *cString =
		    [string insecureCStringWithEncoding: OFStringEncodingASCII];
		size_t cStringLength =
		    [string cStringLengthWithEncoding: OFStringEncodingASCII];
		rawValue = [OFData dataWithItems: cString count: cStringLength];
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
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	@try {
		void *pool = objc_autoreleasePoolPush();

		OFString *string = [OFString
		    stringWithCString: rawValue.items
			     encoding: OFStringEncodingASCII
			       length: rawValue.count];
		if ([string rangeOfCharacterFromSet: [OFCharacterSet
		    ASN1PrintableStringCharacterSet].invertedSet].location !=
		    OFNotFound)
			@throw [OFInvalidEncodingException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [super initWithRawValue: rawValue
			      tagClass: tagClass
			     tagNumber: tagNumber];
}

- (OFString *)stringValue
{
	return [OFString stringWithCString: _rawValue.items
				  encoding: OFStringEncodingASCII
				    length: _rawValue.count];
}
@end
