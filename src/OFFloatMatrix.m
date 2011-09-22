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

#import "OFFloatMatrix.h"
#import "OFFloatVector.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static Class floatVector = Nil;

@implementation OFFloatMatrix
+ (void)initialize
{
	if (self == [OFFloatMatrix class])
		floatVector = [OFFloatVector class];
}

+ matrixWithRows: (size_t)rows
	 columns: (size_t)columns
{
	return [[[self alloc] initWithRows: rows
				   columns: columns] autorelease];
}

+ matrixWithRows: (size_t)rows
	 columns: (size_t)columns
	    data: (float)data, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, data);
	ret = [[[self alloc] initWithRows: rows
				  columns: columns
				     data: data
				arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithRows: (size_t)rows_
       columns: (size_t)columns_
{
	self = [super init];

	@try {
		rows = rows_;
		columns = columns_;

		if (SIZE_MAX / rows < columns ||
		    SIZE_MAX / rows * columns < sizeof(float))
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		if ((data = malloc(rows * columns * sizeof(float))) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithClass: isa
				  requestedSize: rows * columns *
						 sizeof(float)];

		memset(data, 0, rows * columns * sizeof(float));

		if (rows == columns) {
			size_t i;

			for (i = 0; i < rows * columns; i += rows + 1)
				data[i] = 1;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

-   initWithRows: (size_t)rows_
	 columns: (size_t)columns_
	    data: (float)data_, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, data_);
	ret = [self initWithRows: rows_
			 columns: columns_
			    data: data_
		       arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithRows: (size_t)rows_
       columns: (size_t)columns_
	  data: (float)data_
     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		size_t i;

		rows = rows_;
		columns = columns_;

		if (SIZE_MAX / rows < columns ||
		    SIZE_MAX / rows * columns < sizeof(float))
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		if ((data = malloc(rows * columns * sizeof(float))) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithClass: isa
				  requestedSize: rows * columns *
						 sizeof(float)];

		for (i = 0; i < rows; i++) {
			size_t j;

			for (j = i; j < rows * columns; j += rows)
				data[j] = (j == 0
				    ? data_ : (float)va_arg(arguments, double));
		}
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

- (void)setValue: (float)value
	  forRow: (size_t)row
	  column: (size_t)column
{
	if (row >= rows || column >= columns)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	data[row * columns + column] = value;
}

- (float)valueForRow: (size_t)row
	      column: (size_t)column
{
	if (row >= rows || column >= columns)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	return data[row * columns + column];
}

- (size_t)rows
{
	return rows;
}

- (size_t)columns
{
	return columns;
}

- (BOOL)isEqual: (id)object
{
	OFFloatMatrix *otherMatrix;

	if (![object isKindOfClass: [OFFloatMatrix class]])
		return NO;

	otherMatrix = object;

	if (otherMatrix->rows != rows || otherMatrix->columns != columns)
		return NO;

	if (memcmp(otherMatrix->data, data, rows * columns * sizeof(float)))
		return NO;

	return YES;
}

- (uint32_t)hash
{
	size_t i;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < rows * columns; i++) {
		union {
			float f;
			uint8_t b[sizeof(float)];
		} u;
		uint8_t j;

		u.f = of_bswap_float_if_be(data[i]);

		for (j = 0; j < sizeof(float); j++)
			OF_HASH_ADD(hash, u.b[j]);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	OFFloatMatrix *copy = [[isa alloc] initWithRows: rows
						columns: columns];

	memcpy(copy->data, data, rows * columns * sizeof(float));

	return copy;
}

- (OFString*)description
{
	OFMutableString *description;
	size_t i;

	description = [OFMutableString stringWithFormat: @"<%@, (\n",
							 [self className]];

	for (i = 0; i < rows; i++) {
		size_t j;

		[description appendString: @"\t"];

		for (j = 0; j < columns; j++) {

			if (j != columns - 1)
				[description
				    appendFormat: @"%10f ",
						  data[j * rows + i]];
			else
				[description
				    appendFormat: @"%10f\n",
						  data[j * rows + i]];
		}
	}

	[description appendString: @")>"];

	[description makeImmutable];

	return description;
}

- (float*)cArray
{
	return data;
}

- (void)addMatrix: (OFFloatMatrix*)matrix
{
	size_t i;

	if (matrix->isa != isa || matrix->rows != rows ||
	    matrix->columns != columns)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	for (i = 0; i < rows * columns; i++)
		data[i] += matrix->data[i];
}

- (void)subtractMatrix: (OFFloatMatrix*)matrix
{
	size_t i;

	if (matrix->isa != isa || matrix->rows != rows ||
	    matrix->columns != columns)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	for (i = 0; i < rows * columns; i++)
		data[i] -= matrix->data[i];
}


- (void)multiplyWithScalar: (float)scalar
{
	size_t i;

	for (i = 0; i < rows * columns; i++)
		data[i] *= scalar;
}

- (void)divideByScalar: (float)scalar
{
	size_t i;

	for (i = 0; i < rows * columns; i++)
		data[i] /= scalar;
}

- (void)multiplyWithMatrix: (OFFloatMatrix*)matrix
{
	float *newData;
	size_t i, base1, base2;

	if (rows != matrix->columns)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	if ((newData = malloc(matrix->rows * columns * sizeof(float))) == NULL)
		@throw [OFOutOfMemoryException
		     exceptionWithClass: isa
			  requestedSize: matrix->rows * columns *
					 sizeof(float)];

	base1 = 0;
	base2 = 0;

	for (i = 0; i < columns; i++) {
		size_t base3 = base2;
		size_t j;

		for (j = 0; j < matrix->rows; j++) {
			size_t base4 = j;
			size_t base5 = base1;
			float tmp = 0.0f;
			size_t k;

			for (k = 0; k < matrix->columns; k++) {
				tmp += matrix->data[base4] * data[base5];
				base4 += matrix->rows;
				base5++;
			}

			newData[base3] = tmp;
			base3++;
		}

		base1 += rows;
		base2 += matrix->rows;
	}

	free(data);
	data = newData;

	rows = matrix->rows;
}

- (void)transpose
{
	float *newData;
	size_t i, k;

	if ((newData = malloc(rows * columns * sizeof(float))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: isa
			 requestedSize: rows * columns * sizeof(float)];

	rows ^= columns;
	columns ^= rows;
	rows ^= columns;

	for (i = k = 0; i < rows; i++) {
		size_t j;

		for (j = i; j < rows * columns; j += rows)
			newData[j] = data[k++];
	}

	free(data);
	data = newData;
}

- (void)translateWithVector: (OFFloatVector*)vector
{
	OFFloatMatrix *translation;
	float *cArray;

	if (rows != columns || vector->isa != floatVector ||
	    vector->dimension != rows - 1)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	cArray = [vector cArray];
	translation = [[OFFloatMatrix alloc] initWithRows: rows
						  columns: columns];

	memcpy(translation->data + (columns - 1) * rows, cArray,
	    (rows - 1) * sizeof(float));

	@try {
		[self multiplyWithMatrix: translation];
	} @finally {
		[translation release];
	}
}

- (void)rotateWithVector: (OFFloatVector*)vector
		   angle: (float)angle
{
	OFFloatMatrix *rotation;
	float n[3], m, angleCos, angleSin;

	if (rows != 4 || columns != 4 || vector->isa != floatVector ||
	    vector->dimension != 3)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	n[0] = vector->data[0];
	n[1] = vector->data[1];
	n[2] = vector->data[2];

	m = sqrtf(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]);

	if (m != 1.0) {
		n[0] /= m;
		n[1] /= m;
		n[2] /= m;
	}

	angle = (float)(angle * M_PI / 180.0f);
	angleCos = cosf(angle);
	angleSin = sinf(angle);

	rotation = [[OFFloatMatrix alloc] initWithRows: rows
					       columns: columns];

	rotation->data[0] = angleCos + n[0] * n[0] * (1 - angleCos);
	rotation->data[1] = n[1] * n[0] * (1 - angleCos) + n[2] * angleSin;
	rotation->data[2] = n[2] * n[0] * (1 - angleCos) - n[1] * angleSin;

	rotation->data[4] = n[0] * n[1] * (1 - angleCos) - n[2] * angleSin;
	rotation->data[5] = angleCos + n[1] * n[1] * (1 - angleCos);
	rotation->data[6] = n[2] * n[1] * (1 - angleCos) + n[0] * angleSin;

	rotation->data[8] = n[0] * n[2] * (1 - angleCos) + n[1] * angleSin;
	rotation->data[9] = n[1] * n[2] * (1 - angleCos) - n[0] * angleSin;
	rotation->data[10] = angleCos + n[2] * n[2] * (1 - angleCos);

	@try {
		[self multiplyWithMatrix: rotation];
	} @finally {
		[rotation release];
	}
}

- (void)scaleWithVector: (OFFloatVector*)vector
{
	OFFloatMatrix *scale;
	float *cArray;
	size_t i, j;

	if (rows != columns || vector->isa != floatVector ||
	    vector->dimension != rows - 1)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	cArray = [vector cArray];
	scale = [[OFFloatMatrix alloc] initWithRows: rows
					    columns: columns];

	for (i = j = 0; i < ((rows - 1) * columns) - 1; i += rows + 1)
		scale->data[i] = cArray[j++];

	@try {
		[self multiplyWithMatrix: scale];
	} @finally {
		[scale release];
	}
}
@end
