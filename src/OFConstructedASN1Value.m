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

#import "OFConstructedASN1Value.h"
#import "OFASN1Set.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFCountedSet.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFNotImplementedException.h"

@implementation OFConstructedASN1Value
@synthesize components = _components;

+ (instancetype)valueWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					 OFASN1Value *)) *)components
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithComponents: components
		      tagClass: tagClass
		     tagNumber: tagNumber]);
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

- (OFData *)DERRepresentation
{
	void *pool = objc_autoreleasePoolPush();

	OFMutableArray *componentRepresentations =
	    [OFMutableArray arrayWithCapacity: _components.count];
	size_t totalLength = 0;
	for (OF_KINDOF(OFASN1Value *) component in _components) {
		OFData *componentRepresentation = [component DERRepresentation];
		[componentRepresentations addObject: componentRepresentation];

		size_t componentLength = componentRepresentation.count;
		if (SIZE_MAX - totalLength < componentLength)
			@throw [OFOutOfRangeException exception];

		totalLength += componentLength;
	}

	if (SIZE_MAX - totalLength < 2)
		@throw [OFOutOfRangeException exception];

	OFMutableData *DERRepresentation =
	    [OFMutableData dataWithCapacity: totalLength + 2];

	unsigned char tag[6];
	[DERRepresentation addItems: tag
			      count: _OFDEREncodeTag(_tagClass, _tagNumber,
					 true, tag)];

	unsigned char length[9];
	[DERRepresentation addItems: length
			      count: _OFDEREncodeLength(totalLength, length)];

	for (OFData *componentRepresentation in componentRepresentations)
		[DERRepresentation addItems: componentRepresentation.items
				      count: componentRepresentation.count];

	[DERRepresentation makeImmutable];

	objc_retain(DERRepresentation);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(DERRepresentation);
}

- (OFString *)description
{
	OFString *components = [_components.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %x\n"
	    @"\tTag number = %x\n"
	    @"\tComponents = %@\n"
	    @">",
	    self.class, _tagClass, _tagNumber, components];
}

- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class
{
	if (![class isSubclassOfClass: [OFASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	if ([class isSubclassOfClass: [OFASN1Set class]]) {
		void *pool = objc_autoreleasePoolPush();

		OFData *previousData = nil;
		for (OFASN1Value *value in _components) {
			OFData *data = value.DERRepresentation;

			if (previousData != nil && [data compare:
			    previousData] == OFOrderedAscending)
				@throw [OFInvalidFormatException exception];

			previousData = data;
		}

		OFCountedSet *componentSet =
		    [OFCountedSet setWithArray: _components];
		OFASN1Set *set = [[OFASN1Set alloc]
		    initWithComponentSet: componentSet
				tagClass: _tagClass
			       tagNumber: _tagNumber];

		objc_autoreleasePoolPop(pool);

		return objc_autoreleaseReturnValue(set);
	}

	@try {
		return objc_autoreleaseReturnValue(
		    [[class alloc] initWithComponents: _components
					     tagClass: _tagClass
					    tagNumber: _tagNumber]);
	} @catch (OFNotImplementedException *e) {
		@throw [OFInvalidArgumentException exception];
	}
}
@end
