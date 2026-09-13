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

#import "OFASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Value
@dynamic tagClass, tagNumber, constructed, DERRepresentation;

- (instancetype)init
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}
	}

	return [super init];
}

- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
{
	if ([self isMemberOfClass: [OFASN1Value class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}
	}

	return [super init];
}

- (bool)isEqual: (id)object
{
	if (![object isKindOfClass: [OFASN1Value class]])
		return false;

	return [[object DERRepresentation] isEqual: self.DERRepresentation];
}

- (unsigned long)hash
{
	return self.DERRepresentation.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tConstructed = %u\n"
	    @">",
	    self.class, self.tagClass, self.tagNumber, self.constructed];
}
@end
