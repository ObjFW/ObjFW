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
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFOnce.h"

static const float identityValues[4][4] = {
	{ 1, 0, 0, 0 },
	{ 0, 1, 0, 0 },
	{ 0, 0, 1, 0 },
	{ 0, 0, 0, 1 }
};

@implementation OFMatrix4x4
#if (defined(OF_AMD64) || defined(OF_X86)) && defined(HAVE_INTEL_SYNTAX)
static void
multiplyWithMatrix_3DNow(OFMatrix4x4 *self, SEL _cmd, OFMatrix4x4 *matrix)
{
	float result[4][4] = {{ 0 }};

	for (uint_fast8_t i = 0; i < 4; i++) {
		for (uint_fast8_t j = 0; j < 4; j++) {
			__asm__ (
			    "movd	mm0, [%2]\n\t"
			    "punpckldq	mm0, [%2 + 16]\n\t"
			    "pfmul	mm0, [%1]\n\t"
			    "movd	mm1, [%2 + 32]\n\t"
			    "punpckldq	mm1, [%2 + 48]\n\t"
			    "pfmul	mm1, [%1 + 8]\n\t"
			    "pfadd	mm0, mm1\n\t"
			    "movq	mm1, mm0\n\t"
			    "psrlq	mm1, 32\n\t"
			    "pfadd	mm0, mm1\n\t"
			    "movd	%0, mm0"
			    :: "m"(result[i][j]), "r"(&matrix->_values[i][0]),
			       "r"(&self->_values[0][j])
			    : "mm0", "mm1", "memory"
			);
		}
	}

	__asm__ ("femms");

	memcpy(self->_values, result, sizeof(result));
}

static OFVector4D
transformedVector_3DNow(OFMatrix4x4 *self, SEL _cmd, OFVector4D vector)
{
	OFVector4D result;

	__asm__ (
	    "movq	mm0, [%2]\n\t"
	    "movq	mm1, [%2 + 8]\n"
	    "\n\t"
	    "movq	mm2, mm0\n\t"
	    "movq	mm3, mm1\n\t"
	    "pfmul	mm2, [%1]\n\t"
	    "pfmul	mm3, [%1 + 8]\n\t"
	    "pfadd	mm2, mm3\n\t"
	    "movq	mm3, mm2\n\t"
	    "psrlq	mm3, 32\n\t"
	    "pfadd	mm2, mm3\n"
	    "\n\t"
	    "movq	mm3, mm0\n\t"
	    "movq	mm4, mm1\n\t"
	    "pfmul	mm3, [%1 + 16]\n\t"
	    "pfmul	mm4, [%1 + 24]\n\t"
	    "pfadd	mm3, mm4\n\t"
	    "movq	mm4, mm3\n\t"
	    "psrlq	mm4, 32\n\t"
	    "pfadd	mm3, mm4\n"
	    "\n\t"
	    "punpckldq	mm2, mm3\n\t"
	    "movq	[%0], mm2\n"
	    "\n\t"
	    "movq	mm2, mm0\n\t"
	    "movq	mm3, mm1\n\t"
	    "pfmul	mm2, [%1 + 32]\n\t"
	    "pfmul	mm3, [%1 + 40]\n\t"
	    "pfadd	mm2, mm3\n\t"
	    "movq	mm3, mm2\n\t"
	    "psrlq	mm3, 32\n\t"
	    "pfadd	mm2, mm3\n"
	    "\n\t"
	    "pfmul	mm0, [%1 + 48]\n\t"
	    "pfmul	mm1, [%1 + 56]\n\t"
	    "pfadd	mm0, mm1\n\t"
	    "movq	mm1, mm0\n\t"
	    "psrlq	mm1, 32\n\t"
	    "pfadd	mm0, mm1\n"
	    "\n\t"
	    "punpckldq	mm2, mm0\n\t"
	    "movq	[%0 + 8], mm2\n"
	    "\n\t"
	    "femms"
	    :: "r"(&result), "r"(&self->_values), "r"(&vector)
	    : "mm0", "mm1", "mm2", "mm3", "mm4", "memory"
	);

	return result;
}

+ (void)initialize
{
	if (self != [OFMatrix4x4 class])
		return;

	if ([OFSystemInfo supports3DNow]) {
		SEL selector;
		const char *typeEncoding;

		selector = @selector(multiplyWithMatrix:);
		typeEncoding = method_getTypeEncoding(
		    class_getInstanceMethod(self, selector));
		class_replaceMethod(self, selector,
		    (IMP)multiplyWithMatrix_3DNow, typeEncoding);

		selector = @selector(transformedVector:);
		typeEncoding = method_getTypeEncoding(
		    class_getInstanceMethod(self, selector));
		class_replaceMethod(self, selector,
		    (IMP)transformedVector_3DNow, typeEncoding);
	}
}
#endif

+ (OFMatrix4x4 *)identityMatrix
{
	return [[[OFMatrix4x4 alloc]
	    initWithValues: identityValues] autorelease];
}

+ (instancetype)matrixWithValues: (const float [4][4])values
{
	return [[[self alloc] initWithValues: values] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
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
	float result[4][4] = {{ 0 }};

	for (uint_fast8_t i = 0; i < 4; i++)
		for (uint_fast8_t j = 0; j < 4; j++)
			for (uint_fast8_t k = 0; k < 4; k++)
				result[i][j] +=
				    matrix->_values[i][k] * _values[k][j];

	memcpy(_values, result, sizeof(result));
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
