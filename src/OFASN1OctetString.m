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

#import "OFASN1OctetString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1OctetString
@synthesize octetStringValue = _octetStringValue;

+ (instancetype)octetStringWithOctetString: (OFData *)octetString
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithOctetString: octetString]);
}

- (instancetype)initWithOctetString: (OFData *)octetString
{
	self = [super init];

	@try {
		_octetStringValue = [octetString copy];
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
	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberOctetString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithOctetString: DEREncodedContents];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_octetStringValue);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1OctetString *octetString;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1OctetString class]])
		return false;

	octetString = object;

	if (![octetString->_octetStringValue isEqual: _octetStringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _octetStringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1OctetString: %@>",
					   _octetStringValue];
}
@end
