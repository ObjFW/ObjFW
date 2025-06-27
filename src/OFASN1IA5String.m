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

#import "OFASN1IA5String.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1IA5String
@synthesize IA5StringValue = _IA5StringValue;

+ (instancetype)stringWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		_IA5StringValue = [string copy];
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
	OFString *IA5String;

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberIA5String || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		IA5String = [OFString
		    stringWithCString: DEREncodedContents.items
			     encoding: OFStringEncodingASCII
			       length: DEREncodedContents.count];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithString: IA5String];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_IA5StringValue);

	[super dealloc];
}

- (OFString *)stringValue
{
	return self.IA5StringValue;
}

- (bool)isEqual: (id)object
{
	OFASN1IA5String *IA5String;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1IA5String class]])
		return false;

	IA5String = object;

	if (![IA5String->_IA5StringValue isEqual: _IA5StringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _IA5StringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1IA5String: %@>",
					   _IA5StringValue];
}
@end
