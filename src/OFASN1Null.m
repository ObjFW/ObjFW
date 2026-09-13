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

#import "OFASN1Null.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Null
+ (instancetype)null
{
	return objc_autoreleaseReturnValue([[OFASN1Null alloc] init]);
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	self = [super init];

	@try {
		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberNull || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.count != 0)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFASN1TagClass)tagClass
{
	return OFASN1TagClassUniversal;
}

- (OFASN1TagNumber)tagNumber
{
	return OFASN1TagNumberNull;
}

- (bool)isConstructed
{
	return false;
}

- (OFData *)DERRepresentation
{
	const unsigned char bytes[] = { OFASN1TagNumberNull, 0 };
	return [OFData dataWithItems: bytes count: sizeof(bytes)];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@>", self.class];
}
@end
