/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#import "OFASN1PrintableString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"

@implementation OFASN1PrintableString
@synthesize printableStringValue = _printableStringValue;

+ (instancetype)stringWithStringValue: (OFString *)stringValue
{
	return [[[self alloc] initWithStringValue: stringValue] autorelease];
}

- (instancetype)initWithStringValue: (OFString *)stringValue
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const char *cString = stringValue.UTF8String;
		size_t length = stringValue.UTF8StringLength;

		for (size_t i = 0; i < length; i++) {
			if (of_ascii_isalnum(cString[i]))
				continue;

			switch (cString[i]) {
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
				continue;
			default:
				@throw [OFInvalidEncodingException exception];
			}
		}

		_printableStringValue = [stringValue copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFString *printableStringValue;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_PRINTABLE_STRING ||
		    constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		printableStringValue = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OF_STRING_ENCODING_ASCII
			       length: DEREncodedContents.count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithStringValue: printableStringValue];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_printableStringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return self.printableStringValue;
}

- (bool)isEqual: (id)object
{
	OFASN1PrintableString *printableString;

	if (![object isKindOfClass: [OFASN1PrintableString class]])
		return false;

	printableString = object;

	if (![printableString->_printableStringValue isEqual:
	    _printableStringValue])
		return false;

	return true;
}

- (uint32_t)hash
{
	return _printableStringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1PrintableString: %@>",
					   _printableStringValue];
}
@end
