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
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"

@implementation OFASN1NumericString
@synthesize numericStringValue = _numericStringValue;

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

		for (size_t i = 0; i < length; i++)
			if (!OFASCIIIsDigit(cString[i]) && cString[i] != ' ')
				@throw [OFInvalidEncodingException exception];

		_numericStringValue = [string copy];

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
	OFString *numericString;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberNumericString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		numericString = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OFStringEncodingASCII
			       length: DEREncodedContents.count];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithString: numericString];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_numericStringValue);

	[super dealloc];
}

- (OFString *)stringValue
{
	return self.numericStringValue;
}

- (bool)isEqual: (id)object
{
	OFASN1NumericString *numericString;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1NumericString class]])
		return false;

	numericString = object;

	if (![numericString->_numericStringValue isEqual: _numericStringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _numericStringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1NumericString: %@>",
					   _numericStringValue];
}
@end
