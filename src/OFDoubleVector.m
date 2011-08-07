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

#include <stdlib.h>
#include <string.h>
#include <math.h>

#import "OFDoubleVector.h"
#import "OFDoubleMatrix.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static Class doubleMatrix = Nil;

@implementation OFDoubleVector
+ (void)initialize
{
	if (self == [OFDoubleVector class])
		doubleMatrix = [OFDoubleMatrix class];
}

+ vectorWithDimension: (size_t)dimension
{
	return [[[self alloc] initWithDimension: dimension] autorelease];
}

+ vectorWithDimension: (size_t)dimension
		 data: (double)data, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, data);
	ret = [[[self alloc] initWithDimension: dimension
					  data: data
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

		if (SIZE_MAX / dimension < sizeof(double))
			@throw [OFOutOfRangeException newWithClass: isa];

		if ((data = malloc(dimension * sizeof(double))) == NULL)
			@throw [OFOutOfMemoryException
			     newWithClass: isa
			    requestedSize: dimension * sizeof(double)];

		memset(data, 0, dimension * sizeof(double));
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDimension: (size_t)dimension_
	       data: (double)data_, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, data_);
	ret = [self initWithDimension: dimension_
				 data: data_
			    arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithDimension: (size_t)dimension_
	       data: (double)data_
	  arguments: (va_list)arguments
{
	self = [super init];

	@try {
		size_t i;

		dimension = dimension_;

		if (SIZE_MAX / dimension < sizeof(double))
			@throw [OFOutOfRangeException newWithClass: isa];

		if ((data = malloc(dimension * sizeof(double))) == NULL)
			@throw [OFOutOfMemoryException
			     newWithClass: isa
			    requestedSize: dimension * sizeof(double)];

		data[0] = data_;
		for (i = 1; i < dimension; i++)
			data[i] = va_arg(arguments, double);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	free(data);

	[super dealloc];
}

- (void)setValue: (double)value
	 atIndex: (size_t)index
{
	if (index >= dimension)
		@throw [OFOutOfRangeException newWithClass: isa];

	data[index] = value;
}

- (double)valueAtIndex: (size_t)index
{
	if (index >= dimension)
		@throw [OFOutOfRangeException newWithClass: isa];

	return data[index];
}

- (size_t)dimension
{
	return dimension;
}

- (void)setDimension: (size_t)dimension_
{
	double *newData;
	size_t i;

	if ((newData = realloc(data, dimension_ * sizeof(double))) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
					      requestedSize: dimension_ *
							     sizeof(double)];

	data = newData;

	for (i = dimension; i < dimension_; i++)
		data[i] = 0;

	dimension = dimension_;
}

- (BOOL)isEqual: (id)object
{
	OFDoubleVector *otherVector;

	if (![object isKindOfClass: [OFDoubleVector class]])
		return NO;

	otherVector = object;

	if (otherVector->dimension != dimension)
		return NO;

	if (memcmp(otherVector->data, data, dimension * sizeof(double)))
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
			double f;
			uint64_t i;
		} u;

		u.f = data[i];

		OF_HASH_ADD_INT64(hash, u.i);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFDoubleVector *copy = [[isa alloc] initWithDimension: dimension];

	memcpy(copy->data, data, dimension * sizeof(double));

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

	[description makeImmutable];

	return description;
}

- (double*)cArray
{
	return data;
}

- (double)magnitude
{
	double magnitude;
	size_t i;

	magnitude = 0.0;

	for (i = 0; i < dimension; i++)
		magnitude += data[i] * data[i];

	magnitude = sqrt(magnitude);

	return magnitude;
}

- (void)normalize
{
	double magnitude;
	size_t i;

	magnitude = 0.0;

	for (i = 0; i < dimension; i++)
		magnitude += data[i] * data[i];

	magnitude = sqrt(magnitude);

	for (i = 0; i < dimension; i++)
		data[i] /= magnitude;
}

- (void)addVector: (OFDoubleVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] += vector->data[i];
}

- (void)subtractVector: (OFDoubleVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] -= vector->data[i];
}

- (void)multiplyWithScalar: (double)scalar
{
	size_t i;

	for (i = 0; i < dimension; i++)
		data[i] *= scalar;
}

- (void)divideByScalar: (double)scalar
{
	size_t i;

	for (i = 0; i < dimension; i++)
		data[i] /= scalar;
}

- (void)multiplyWithComponentsOfVector: (OFDoubleVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] *= vector->data[i];
}

- (void)divideByComponentsOfVector: (OFDoubleVector*)vector
{
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < dimension; i++)
		data[i] /= vector->data[i];
}

- (double)dotProductWithVector: (OFDoubleVector*)vector
{
	double dotProduct;
	size_t i;

	if (vector->isa != isa || vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	dotProduct = 0.0;

	for (i = 0; i < dimension; i++)
		dotProduct += data[i] * vector->data[i];

	return dotProduct;
}

- (OFDoubleVector*)crossProductWithVector: (OFDoubleVector*)vector
{
	OFDoubleVector *crossProduct;

	if (dimension != 3)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	if (vector->dimension != dimension)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	crossProduct = [OFDoubleVector vectorWithDimension: 3];

	crossProduct->data[0] =
	    data[1] * vector->data[2] - data[2] * vector->data[1];
	crossProduct->data[1] =
	    data[2] * vector->data[0] - data[0] * vector->data[2];
	crossProduct->data[2] =
	    data[0] * vector->data[1] - data[1] * vector->data[0];

	return crossProduct;
}

- (void)multiplyWithMatrix: (OFDoubleMatrix*)matrix
{
	double *newData;
	size_t i, j, k;

	if (matrix->isa != doubleMatrix || dimension != matrix->columns)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((newData = malloc(matrix->rows * sizeof(double))) == NULL)
		@throw [OFOutOfMemoryException
		     newWithClass: isa
		    requestedSize: matrix->rows * sizeof(double)];

	memset(newData, 0, matrix->rows * sizeof(double));

	for (i = j = k = 0; i < matrix->rows * matrix->columns; i++) {
		newData[j] += matrix->data[i] * data[k];

		if (++j == matrix->rows) {
			k++;
			j = 0;
		}
	}

	free(data);
	data = newData;

	dimension = matrix->rows;
}
@end
