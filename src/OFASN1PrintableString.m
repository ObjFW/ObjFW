/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

+ (instancetype)stringWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const char *cString = string.UTF8String;
		size_t length = string.UTF8StringLength;

		for (size_t i = 0; i < length; i++) {
			if (OFASCIIIsAlnum(cString[i]))
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

		_printableStringValue = [string copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFString *printableString;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberPrintableString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		printableString = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OFStringEncodingASCII
			       length: DEREncodedContents.count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithString: printableString];

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

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1PrintableString class]])
		return false;

	printableString = object;

	if (![printableString->_printableStringValue isEqual:
	    _printableStringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _printableStringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1PrintableString: %@>",
					   _printableStringValue];
}
@end
