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

#import "OFASN1OctetString.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1OctetString
@synthesize octetStringValue = _octetStringValue;

+ (instancetype)octetStringWithOctetString: (OFData *)octetString
{
	return [[[self alloc] initWithOctetString: octetString] autorelease];
}

- (instancetype)initWithOctetString: (OFData *)octetString
{
	self = [super init];

	@try {
		_octetStringValue = [octetString copy];
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
	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberOctetString || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
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
	[_octetStringValue release];

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
