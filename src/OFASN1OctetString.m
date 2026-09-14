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
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1OctetString
@synthesize octets = _octets;

+ (instancetype)octetStringWithOctets: (OFData *)octets
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithOctets: octets]);
}

+ (instancetype)octetStringWithOctets: (OFData *)octets
			     tagClass: (OFASN1TagClass)tagClass
			    tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithOctets: octets
		  tagClass: tagClass
		 tagNumber: tagNumber]);
}

- (instancetype)initWithOctets: (OFData *)octets
{
	return [self initWithOctets: octets
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberOctetString];
}

- (instancetype)initWithOctets: (OFData *)octets
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (octets.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		_octets = [octets copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	@try {
		if (constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithOctets: DEREncodedContents
			   tagClass: tagClass
			  tagNumber: tagNumber];
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_octets);

	[super dealloc];
}

- (OFData *)DERRepresentation
{
	size_t octetsCount = _octets.count;
	if (SIZE_MAX - octetsCount < 2)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data = [OFMutableData dataWithCapacity: octetsCount + 2];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, false, tag)];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(octetsCount, length)];

	[data addItems: _octets.items count: octetsCount];

	[data makeImmutable];

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<OFASN1OctetString: %@>", _octets];
}
@end
