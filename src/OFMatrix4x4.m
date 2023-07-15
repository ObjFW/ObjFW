/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFMatrix4x4.h"
#import "OFOnce.h"
#import "OFString.h"

static const float identityValues[4][4] = {
	{ 1, 0, 0, 0 },
	{ 0, 1, 0, 0 },
	{ 0, 0, 1, 0 },
	{ 0, 0, 0, 1 }
};

@implementation OFMatrix4x4
+ (OFMatrix4x4 *)identityMatrix
{
	return [[[OFMatrix4x4 alloc]
	    initWithValues: identityValues] autorelease];
}

+ (instancetype)matrixWithValues: (const float [4][4])values
{
	return [[[self alloc] initWithValues: values] autorelease];
}

- (instancetype)initWithValues: (const float [4][4])values
{
	self = [super init];

	memcpy(_values, values, sizeof(_values));

	return self;
}

- (float (*)[4])values
{
	return _values;
}

- (instancetype)copy
{
	return [[OFMatrix4x4 alloc]
	    initWithValues: (const float (*)[4])_values];
}

- (bool)isEqual: (OFMatrix4x4 *)matrix
{
	if (![matrix isKindOfClass: [OFMatrix4x4 class]])
		return false;

	return (memcmp(_values, matrix->_values, sizeof(_values)) == 0);
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (uint_fast8_t i = 0; i < 4; i++)
		for (uint_fast8_t j = 0; j < 4; j++)
			OFHashAddHash(&hash, OFFloatToRawUInt32(_values[i][j]));

	OFHashFinalize(&hash);

	return hash;
}

- (void)multiplyWithMatrix: (OFMatrix4x4 *)matrix
{
	float right[4][4];
	memcpy(right, _values, sizeof(right));

#define left matrix->_values
	_values[0][0] = left[0][0] * right[0][0] + left[0][1] * right[1][0] +
	    left[0][2] * right[2][0] + left[0][3] * right[3][0];
	_values[0][1] = left[0][0] * right[0][1] + left[0][1] * right[1][1] +
	    left[0][2] * right[2][1] + left[0][3] * right[3][1];
	_values[0][2] = left[0][0] * right[0][2] + left[0][1] * right[1][2] +
	    left[0][2] * right[2][2] + left[0][3] * right[3][2];
	_values[0][3] = left[0][0] * right[0][3] + left[0][1] * right[1][3] +
	    left[0][2] * right[2][3] + left[0][3] * right[3][3];

	_values[1][0] = left[1][0] * right[0][0] + left[1][1] * right[1][0] +
	    left[1][2] * right[2][0] + left[1][3] * right[3][0];
	_values[1][1] = left[1][0] * right[0][1] + left[1][1] * right[1][1] +
	    left[1][2] * right[2][1] + left[1][3] * right[3][1];
	_values[1][2] = left[1][0] * right[0][2] + left[1][1] * right[1][2] +
	    left[1][2] * right[2][2] + left[1][3] * right[3][2];
	_values[1][3] = left[1][0] * right[0][3] + left[1][1] * right[1][3] +
	    left[1][2] * right[2][3] + left[1][3] * right[3][3];

	_values[2][0] = left[2][0] * right[0][0] + left[2][1] * right[1][0] +
	    left[2][2] * right[2][0] + left[2][3] * right[3][0];
	_values[2][1] = left[2][0] * right[0][1] + left[2][1] * right[1][1] +
	    left[2][2] * right[2][1] + left[2][3] * right[3][1];
	_values[2][2] = left[2][0] * right[0][2] + left[2][1] * right[1][2] +
	    left[2][2] * right[2][2] + left[2][3] * right[3][2];
	_values[2][3] = left[2][0] * right[0][3] + left[2][1] * right[1][3] +
	    left[2][2] * right[2][3] + left[2][3] * right[3][3];

	_values[3][0] = left[3][0] * right[0][0] + left[3][1] * right[1][0] +
	    left[3][2] * right[2][0] + left[3][3] * right[3][0];
	_values[3][1] = left[3][0] * right[0][1] + left[3][1] * right[1][1] +
	    left[3][2] * right[2][1] + left[3][3] * right[3][1];
	_values[3][2] = left[3][0] * right[0][2] + left[3][1] * right[1][2] +
	    left[3][2] * right[2][2] + left[3][3] * right[3][2];
	_values[3][3] = left[3][0] * right[0][3] + left[3][1] * right[1][3] +
	    left[3][2] * right[2][3] + left[3][3] * right[3][3];
#undef left
}

- (void)translateWithVector: (OFVector3D)vector
{
	OFMatrix4x4 *translation = [[OFMatrix4x4 alloc] initWithValues:
	    (const float [4][4]){
		{ 1, 0, 0, vector.x },
		{ 0, 1, 0, vector.y },
		{ 0, 0, 1, vector.z },
		{ 0, 0, 0, 1 }
	    }];
	[self multiplyWithMatrix: translation];
	[translation release];
}

- (void)scaleWithVector: (OFVector3D)vector
{
	OFMatrix4x4 *scale = [[OFMatrix4x4 alloc] initWithValues:
	    (const float [4][4]){
		{ vector.x, 0, 0, 0 },
		{ 0, vector.y, 0, 0 },
		{ 0, 0, vector.z, 0 },
		{ 0, 0, 0, 1 }
	    }];
	[self multiplyWithMatrix: scale];
	[scale release];
}

- (OFVector4D)transformedVector: (OFVector4D)vector
{
	return OFMakeVector4D(
	    _values[0][0] * vector.x + _values[0][1] * vector.y +
	    _values[0][2] * vector.z + _values[0][3] * vector.w,
	    _values[1][0] * vector.x + _values[1][1] * vector.y +
	    _values[1][2] * vector.z + _values[1][3] * vector.w,
	    _values[2][0] * vector.x + _values[2][1] * vector.y +
	    _values[2][2] * vector.z + _values[2][3] * vector.w,
	    _values[3][0] * vector.x + _values[3][1] * vector.y +
	    _values[3][2] * vector.z + _values[3][3] * vector.w);
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFMatrix4x4: {\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"\t%g %g %g %g\n"
	    @"}>",
	    _values[0][0], _values[0][1], _values[0][2], _values[0][3],
	    _values[1][0], _values[1][1], _values[1][2], _values[1][3],
	    _values[2][0], _values[2][1], _values[2][2], _values[2][3],
	    _values[3][0], _values[3][1], _values[3][2], _values[3][3]];
}
@end
