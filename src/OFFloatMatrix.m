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

#import "OFFloatMatrix.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

@implementation OFFloatMatrix
+ matrixWithRows: (size_t)rows
	 columns: (size_t)columns
{
	return [[[self alloc] initWithRows: rows
				   columns: columns] autorelease];
}

+ matrixWithRows: (size_t)rows
  columnsAndData: (size_t)columns, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, columns);
	ret = [[[self alloc] initWithRows: rows
				  columns: columns
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

- initWithRows: (size_t)rows_
       columns: (size_t)columns_
{
	self = [super init];

	@try {
		rows = rows_;
		columns = columns_;

		if (SIZE_MAX / rows < columns)
			@throw [OFOutOfRangeException
			    newWithClass: isa];

		data = [self allocMemoryForNItems: rows * columns
					 withSize: sizeof(float)];

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
  columnsAndData: (size_t)columns_, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, columns_);
	ret = [self initWithRows: rows_
			 columns: columns_
		       arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithRows: (size_t)rows_
       columns: (size_t)columns_
     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		size_t i;

		rows = rows_;
		columns = columns_;

		if (SIZE_MAX / rows < columns)
			@throw [OFOutOfRangeException
			    newWithClass: isa];

		data = [self allocMemoryForNItems: rows * columns
					 withSize: sizeof(float)];

		for (i = 0; i < rows; i++) {
			size_t j;

			for (j = i; j < rows * columns; j += rows)
				data[j] = (float)va_arg(arguments, double);
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setValue: (float)value
	  forRow: (size_t)row
	  column: (size_t)column
{
	if (row >= rows || column >= columns)
		@throw [OFOutOfRangeException newWithClass: isa];

	data[row * columns + column] = value;
}

- (float)valueForRow: (size_t)row
	      column: (size_t)column
{
	if (row >= rows || column >= columns)
		@throw [OFOutOfRangeException newWithClass: isa];

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

	if (object->isa != isa)
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

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	description->isa = [OFString class];
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
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	for (i = 0; i < rows * columns; i++)
		data[i] += matrix->data[i];
}

- (void)subtractMatrix: (OFFloatMatrix*)matrix
{
	size_t i;

	if (matrix->isa != isa || matrix->rows != rows ||
	    matrix->columns != columns)
		@throw [OFInvalidArgumentException newWithClass: isa
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
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	newData = [self allocMemoryForNItems: matrix->rows * columns
				    withSize: sizeof(float)];

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

	[self freeMemory: data];
	data = newData;

	rows = matrix->rows;
}

- (void)transpose
{
	float *newData = [self allocMemoryForNItems: rows * columns
					   withSize: sizeof(float)];
	size_t i, k;

	rows ^= columns;
	columns ^= rows;
	rows ^= columns;

	for (i = k = 0; i < rows; i++) {
		size_t j;

		for (j = i; j < rows * columns; j += rows)
			newData[j] = data[k++];
	}

	[self freeMemory: data];
	data = newData;
}
@end
