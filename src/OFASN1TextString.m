/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFASN1TextString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

@implementation OFASN1TextString
@dynamic stringValue;

+ (instancetype)stringWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

+ (instancetype)stringWithString: (OFString *)string
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string
				tagClass: tagClass
			       tagNumber: tagNumber]);
}

- (instancetype)initWithString: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	if ([self isMemberOfClass: [OFASN1TextString class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	return [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]: %@>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber),
	    self.stringValue];
}
@end
