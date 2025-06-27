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

#import "OFASN1PrintableString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"

@implementation OFASN1PrintableString
@synthesize printableStringValue = _printableStringValue;

+ (instancetype)stringWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
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
		objc_release(self);
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
		objc_release(self);
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
	objc_release(_printableStringValue);

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
