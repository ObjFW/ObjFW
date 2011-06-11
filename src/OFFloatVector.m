/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <string.h>
#include <math.h>

#import "OFFloatVector.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

@implementation OFFloatVector
+ vectorWithDimension: (size_t)dimension
{
	return [[[self alloc] initWithDimension: dimension] autorelease];
}

+ vectorWithDimensionAndData: (size_t)dimension, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, dimension);
	ret = [[[self alloc] initWithDimension: dimension
				     arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithDimension: (size_t)dimension_
{
	self = [super init];

	@try {
		dimension = dimension_;

		data = [self allocMemoryForNItems: dimension
					 withSize: sizeof(float)];

		memset(data, 0, dimension * sizeof(float));
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDimensionAndData: (size_t)dimension_, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, dimension_);
	ret = [self initWithDimension: dimension_
			    arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithDimension: (size_t)dimension_
	  arguments: (va_list)arguments
{
	self = [super init];

	@try {
		size_t i;

		dimension = dimension_;

		data = [self allocMemoryForNItems: dimension
					 withSize: sizeof(float)];

		for (i = 0; i < dimension; i++)
			data[i] = va_arg(arguments, double);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setValue: (float)value
	 atIndex: (size_t)index
{
	if (index >= dimension)
		@throw [OFOutOfRangeException newWithClass: isa];

	data[index] = value;
}

- (float)valueAtIndex: (size_t)index
{
	if (index >= dimension)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data[index];
}

- (size_t)dimension
{
	return dimension;
}

- (BOOL)isEqual: (id)object
{
	OFFloatVector *otherVector;
	size_t i;

	if (object->isa != isa)
		return NO;

	otherVector = object;

	if (otherVector->dimension != dimension)
		return NO;

	for (i = 0; i < dimension; i++)
		if (otherVector->data[i] != data[i])
			return NO;

	return YES;
}

- (uint32_t)hash
{
	size_t i;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < dimension; i++) {
		union {
			float f;
			uint32_t i;
		} u;

		u.f = data[i];

		OF_HASH_ADD_INT32(hash, u.i);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFFloatVector *copy = [[isa alloc] init];

	copy->dimension = dimension;
	copy->data = [copy allocMemoryForNItems: dimension
				       withSize: sizeof(float)];
	memcpy(copy->data, data, dimension * sizeof(float));

	return copy;
}

- (OFString*)description
{
	OFMutableString *description;
	size_t i;

	description = [OFMutableString stringWithFormat: @"<%@: (",
							 [self className]];

	for (i = 0; i < dimension; i++) {
		if (i != dimension - 1)
			[description appendFormat: @"%g, ", data[i]];
		else
			[description appendFormat: @"%g)>", data[i]];
	}

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	description->isa = [OFString class];
	return description;
}

- (float*)floatArray
{
	return data;
}

- (void)addVector: (OFFloatVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] += vector->data[i];
}

- (void)subtractVector: (OFFloatVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] -= vector->data[i];
}

- (void)multiplyWithScalar: (float)scalar
{
	size_t i;

	for (i = 0; i < dimension; i++)
		data[i] *= scalar;
}

- (void)divideByScalar: (float)scalar
{
	size_t i;

	for (i = 0; i < dimension; i++)
		data[i] /= scalar;
}

- (void)multiplyWithComponentsOfVector: (OFFloatVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] *= vector->data[i];
}

- (void)divideByComponentsOfVector: (OFFloatVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] /= vector->data[i];
}

- (float)dotProductWithVector: (OFFloatVector*)vector
{
	float dotProduct;
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	dotProduct = 0.0;

	for (i = 0; i < dimension; i++)
		dotProduct += data[i] * vector->data[i];

	return dotProduct;
}

- (float)magnitude
{
	float magnitude;
	size_t i;

	magnitude = 0.0;

	for (i = 0; i < dimension; i++)
		magnitude += data[i] * data[i];

	magnitude = sqrtf(magnitude);

	return magnitude;
}

- (void)normalize
{
	float magnitude;
	size_t i;

	magnitude = [self magnitude];

	for (i = 0; i < dimension; i++)
		data[i] /= magnitude;
}
@end
