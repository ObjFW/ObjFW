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

#import "OFASN1Set.h"
#import "OFArray.h"
#import "OFCountedSet.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Set
+ (instancetype)valueWithComponentSet:
    (OFCountedSet OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)componentSet
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithComponentSet: componentSet]);
}

+ (instancetype)valueWithComponentSet: (OFCountedSet OF_GENERIC(OF_KINDOF(
					   OFASN1Value *)) *)componentSet
			     tagClass: (OFASN1TagClass)tagClass
			    tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithComponentSet: componentSet
			tagClass: tagClass
		       tagNumber: tagNumber]);
}

- (instancetype)initWithComponentSet:
    (OFCountedSet OF_GENERIC(OF_KINDOF(OFASN1Value *)) *)componentSet
{
	return [self initWithComponentSet: componentSet
				 tagClass: OFASN1TagClassUniversal
				tagNumber: OFASN1TagNumberSet];
}

- (instancetype)initWithComponentSet: (OFCountedSet OF_GENERIC(OF_KINDOF(
					  OFASN1Value *)) *)componentSet
			    tagClass: (OFASN1TagClass)tagClass
			   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFMutableArray *components;
	@try {
		components = [OFMutableArray
		    arrayWithCapacity: componentSet.count];
		for (OF_KINDOF(OFASN1Value *) component in componentSet) {
			size_t count = [componentSet countForObject: component];
			for (size_t i = 0; i < count; i++)
				[components addObject: component];
		}

		[components sort];
		[components makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithComponents: components
			       tagClass: tagClass
			      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithComponents: components
				tagClass: tagClass
			       tagNumber: tagNumber];

	@try {
		OF_KINDOF(OFASN1Value *) previousComponent = nil;
		for (OF_KINDOF(OFASN1Value *) component in _components) {
			if (previousComponent != nil && [previousComponent
			    compare: component] == OFOrderedDescending)
				@throw [OFInvalidFormatException exception];

			previousComponent = component;
		}
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFCountedSet *)componentSet
{
	return [OFCountedSet setWithArray: _components];
}
@end
