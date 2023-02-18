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

static const float identityValues[16] = {
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1
};

@implementation OFMatrix4x4
+ (OFMatrix4x4 *)identityMatrix
{
	return [[[OFMatrix4x4 alloc]
	    initWithValues: identityValues] autorelease];
}

+ (instancetype)matrixWithValues: (const float [16])values
{
	return [[[self alloc] initWithValues: values] autorelease];
}

- (instancetype)initWithValues: (const float [16])values
{
	self = [super init];

	memcpy(_values, values, 16 * sizeof(float));

	return self;
}

- (float *)values
{
	return _values;
}

- (instancetype)copy
{
	return [[OFMatrix4x4 alloc] initWithValues: _values];
}

- (bool)isEqual: (OFMatrix4x4 *)matrix
{
	if (![matrix isKindOfClass: [OFMatrix4x4 class]])
		return false;

	return (memcmp(_values, matrix->_values, 16 * sizeof(float)) == 0);
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < 16; i++)
		OFHashAddHash(&hash, OFFloatToRawUInt32(_values[i]));

	OFHashFinalize(&hash);

	return hash;
}

- (void)multiplyWithMatrix: (OFMatrix4x4 *)matrix
{
	float r[16], *m = _values, *l = matrix->_values;
	memcpy(r, m, sizeof(r));

	m[ 0] = l[0] * r[ 0] + l[4] * r[ 1] + l[ 8] * r[ 2] + l[12] * r[ 3];
	m[ 1] = l[1] * r[ 0] + l[5] * r[ 1] + l[ 9] * r[ 2] + l[13] * r[ 3];
	m[ 2] = l[2] * r[ 0] + l[6] * r[ 1] + l[10] * r[ 2] + l[14] * r[ 3];
	m[ 3] = l[3] * r[ 0] + l[7] * r[ 1] + l[11] * r[ 2] + l[15] * r[ 3];
	m[ 4] = l[0] * r[ 4] + l[4] * r[ 5] + l[ 8] * r[ 6] + l[12] * r[ 7];
	m[ 5] = l[1] * r[ 4] + l[5] * r[ 5] + l[ 9] * r[ 6] + l[13] * r[ 7];
	m[ 6] = l[2] * r[ 4] + l[6] * r[ 5] + l[10] * r[ 6] + l[14] * r[ 7];
	m[ 7] = l[3] * r[ 4] + l[7] * r[ 5] + l[11] * r[ 6] + l[15] * r[ 7];
	m[ 8] = l[0] * r[ 8] + l[4] * r[ 9] + l[ 8] * r[10] + l[12] * r[11];
	m[ 9] = l[1] * r[ 8] + l[5] * r[ 9] + l[ 9] * r[10] + l[13] * r[11];
	m[10] = l[2] * r[ 8] + l[6] * r[ 9] + l[10] * r[10] + l[14] * r[11];
	m[11] = l[3] * r[ 8] + l[7] * r[ 9] + l[11] * r[10] + l[15] * r[11];
	m[12] = l[0] * r[12] + l[4] * r[13] + l[ 8] * r[14] + l[12] * r[15];
	m[13] = l[1] * r[12] + l[5] * r[13] + l[ 9] * r[14] + l[13] * r[15];
	m[14] = l[2] * r[12] + l[6] * r[13] + l[10] * r[14] + l[14] * r[15];
	m[15] = l[3] * r[12] + l[7] * r[13] + l[11] * r[14] + l[15] * r[15];
}

- (void)translateWithVector: (OFVector3D)vector
{
	OFMatrix4x4 *translation = [[OFMatrix4x4 alloc] initWithValues:
	    (float [16]){
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		vector.x, vector.y, vector.z, 1
	    }];
	[self multiplyWithMatrix: translation];
	[translation release];
}

- (void)scaleWithVector: (OFVector3D)vector
{
	OFMatrix4x4 *scale = [[OFMatrix4x4 alloc] initWithValues:
	    (float [16]){
		vector.x, 0, 0, 0,
		0, vector.y, 0, 0,
		0, 0, vector.z, 0,
		0, 0, 0, 1
	    }];
	[self multiplyWithMatrix: scale];
	[scale release];
}

- (OFVector4D)transformedVector: (OFVector4D)vec
{
	float *m = _values;

	return OFMakeVector4D(
	    m[0] * vec.x + m[4] * vec.y + m[ 8] * vec.z + m[12] * vec.w,
	    m[1] * vec.x + m[5] * vec.y + m[ 9] * vec.z + m[13] * vec.w,
	    m[2] * vec.x + m[6] * vec.y + m[10] * vec.z + m[14] * vec.w,
	    m[3] * vec.x + m[7] * vec.y + m[11] * vec.z + m[15] * vec.w);
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
	    _values[0], _values[4], _values[8], _values[12],
	    _values[1], _values[5], _values[9], _values[13],
	    _values[2], _values[6], _values[10], _values[14],
	    _values[3], _values[7], _values[11], _values[15]];
}
@end
