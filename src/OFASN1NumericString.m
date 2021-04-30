/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFASN1NumericString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"

@implementation OFASN1NumericString
@synthesize numericStringValue = _numericStringValue;

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

		for (size_t i = 0; i < length; i++)
			if (!OFASCIIIsDigit(cString[i]) && cString[i] != ' ')
				@throw [OFInvalidEncodingException exception];

		_numericStringValue = [string copy];

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
		[self release];
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
	[_numericStringValue release];

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
