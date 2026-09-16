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

#import "OFASN1Sequence.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1Sequence
@synthesize components = _components;

+ (instancetype)sequenceWithComponents:
    (OFArray OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)components
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithComponents: components]);
}

+ (instancetype)sequenceWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					    OFASN1Value *)) *)components
			      tagClass: (OFASN1TagClass)tagClass
			     tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithComponents: components
		      tagClass: tagClass
		     tagNumber: tagNumber]);
}

- (instancetype)initWithComponents:
    (OFArray OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)components
{
	return [self initWithComponents: components
			       tagClass: OFASN1TagClassUniversal
			      tagNumber: OFASN1TagNumberSequence];
}

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		_components = [components copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_components);

	[super dealloc];
}

- (OFString *)description
{
	OFString *components = [_components.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\t%@\n"
	    @">",
	    self.class, components];
}
@end
