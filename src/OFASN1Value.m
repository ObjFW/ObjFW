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

#import "OFASN1Value.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Value
@synthesize tagClass = _tagClass, tagNumber = _tagNumber;
@synthesize constructed = _constructed;
@synthesize DEREncodedContents = _DEREncodedContents;

+ (instancetype)valueWithTagClass: (of_asn1_tag_class_t)tagClass
			tagNumber: (of_asn1_tag_number_t)tagNumber
		      constructed: (bool)constructed
	       DEREncodedContents: (OFData *)DEREncodedContents
{
	return [[[self alloc]
	      initWithTagClass: tagClass
		     tagNumber: tagNumber
		   constructed: constructed
	    DEREncodedContents: DEREncodedContents] autorelease];
}

- (instancetype)initWithTagClass: (of_asn1_tag_class_t)tagClass
		       tagNumber: (of_asn1_tag_number_t)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if ([DEREncodedContents itemSize] != 1)
			@throw [OFInvalidFormatException exception];

		_tagClass = tagClass;
		_tagNumber = tagNumber;
		_constructed = constructed;
		_DEREncodedContents = [DEREncodedContents copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_DEREncodedContents release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1Value *value;

	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	value = object;

	if (value->_tagClass != _tagClass)
		return false;
	if (value->_tagNumber != _tagNumber)
		return false;
	if (value->_constructed != _constructed)
		return false;
	if (![value->_DEREncodedContents isEqual: _DEREncodedContents])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD(hash, _tagClass & 0xFF);
	OF_HASH_ADD(hash, _tagNumber & 0xFF);
	OF_HASH_ADD(hash, _constructed);
	OF_HASH_ADD_HASH(hash, [_DEREncodedContents hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1Value:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tConstructed = %u\n"
	    @"\tDER-encoded contents = %@\n"
	    @">",
	    _tagClass, _tagNumber, _constructed,
	    [_DEREncodedContents description]];
}
@end
