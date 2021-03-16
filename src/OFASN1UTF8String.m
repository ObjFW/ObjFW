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

#import "OFASN1UTF8String.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFASN1UTF8String
@synthesize UTF8StringValue = _UTF8StringValue;

+ (instancetype)stringWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		_UTF8StringValue = [string copy];
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
	OFString *UTF8String;

	@try {
		if (tagClass != OF_ASN1_TAG_CLASS_UNIVERSAL ||
		    tagNumber != OF_ASN1_TAG_NUMBER_UTF8_STRING || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		UTF8String = [OFString
		    stringWithUTF8String: DEREncodedContents.items
				  length: DEREncodedContents.count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithString: UTF8String];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_UTF8StringValue release];

	[super dealloc];
}

- (OFString *)stringValue
{
	return self.UTF8StringValue;
}

- (bool)isEqual: (id)object
{
	OFASN1UTF8String *UTF8String;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1UTF8String class]])
		return false;

	UTF8String = object;

	if (![UTF8String->_UTF8StringValue isEqual: _UTF8StringValue])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _UTF8StringValue.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1UTF8String: %@>",
					   _UTF8StringValue];
}
@end
