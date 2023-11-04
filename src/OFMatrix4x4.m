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
#if (defined(OF_AMD64) || defined(OF_X86)) && defined(__GNUC__)
# ifndef __clang__
#  pragma GCC push_options
#  pragma GCC target("sse4.1")
# endif
static void
transformVectors_SSE41(OFMatrix4x4 *self, SEL _cmd, OFVector4D *vectors,
    size_t count)
{
	__asm__ __volatile__ (
	    "test	%0, %0\n\t"
	    "jz		0f\n"
	    "\n\t"
	    "movaps	(%2), %%xmm0\n\t"
	    "movaps	16(%2), %%xmm1\n\t"
	    "movaps	32(%2), %%xmm2\n\t"
	    "movaps	48(%2), %%xmm3\n"
	    "\n\t"
	    "0:\n\t"
	    "movaps	(%1), %%xmm4\n\t"
	    "movaps	%%xmm4, %%xmm5\n\t"
	    "dpps	$0xFF, %%xmm0, %%xmm4\n\t"
	    "movaps	%%xmm5, %%xmm6\n\t"
	    "dpps	$0xFF, %%xmm1, %%xmm5\n\t"
	    "movaps	%%xmm6, %%xmm7\n\t"
	    "dpps	$0xFF, %%xmm2, %%xmm6\n\t"
	    "dpps	$0xFF, %%xmm3, %%xmm7\n\t"
	    "insertps	$0x10, %%xmm5, %%xmm4\n\t"
	    "insertps	$0x20, %%xmm6, %%xmm4\n\t"
	    "insertps	$0x30, %%xmm7, %%xmm4\n\t"
	    "movaps	%%xmm4, (%1)\n"
	    "\n\t"
	    "add	$16, %1\n\t"
	    "dec	%0\n\t"
	    "jnz	0b\n"
	    : "+r"(count), "+r"(vectors)
	    : "r"(self->_values)
	    : "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7",
	      "memory"
	);
}
# ifndef __clang__
#  pragma GCC pop_options
# endif

# ifndef __clang__
#  pragma GCC push_options
#  pragma GCC target("3dnow,3dnowa")
# endif
static void
multiplyWithMatrix_enhanced3DNow(OFMatrix4x4 *self, SEL _cmd,
    OFMatrix4x4 *matrix)
{
	float (*left)[4] = matrix->_values, (*right)[4] = self->_values;
	float result[4][4], (*resultPtr)[4] = result;

	__asm__ __volatile__ (
	    "xorw	%%cx, %%cx\n"
	    "\n\t"
	    "0:\n\t"
	    "movd	(%2), %%mm0\n\t"
	    "punpckldq	16(%2), %%mm0\n\t"
	    "pfmul	(%1), %%mm0\n\t"
	    "movd	32(%2), %%mm1\n\t"
	    "punpckldq  48(%2), %%mm1\n\t"
	    "pfmul	8(%1), %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "pswapd	%%mm0, %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "movd	%%mm0, (%0)\n"
	    "\n\t"
	    "add	$4, %0\n\t"
	    "add	$4, %2\n\t"
	    "incb	%%cl\n\t"
	    "cmpb	$4, %%cl\n\t"
	    "jb		0b\n"
	    "\n\t"
	    "add	$16, %1\n\t"
	    "sub	$16, %2\n\t"
	    "xorb	%%cl, %%cl\n\t"
	    "incb	%%ch\n\t"
	    "cmpb	$4, %%ch\n\t"
	    "jb		0b\n"
	    "\n\t"
	    "femms"
	    : "+r"(resultPtr), "+r"(left), "+r"(right)
	    :: "cx", "mm0", "mm1", "memory"
	);

	memcpy(self->_values, result, 16 * sizeof(float));
}

static void
transformVectors_enhanced3DNow(OFMatrix4x4 *self, SEL _cmd, OFVector4D *vectors,
    size_t count)
{
	__asm__ __volatile__ (
	    "test	%0, %0\n\t"
	    "jz		0f\n"
	    "\n\t"
	    "0:\n\t"
	    "movq	(%1), %%mm0\n\t"
	    "movq	8(%1), %%mm1\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	(%2), %%mm2\n\t"
	    "pfmul	8(%2), %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n\t"
	    "pswapd	%%mm2, %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n"
	    "\n\t"
	    "movq	%%mm0, %%mm3\n\t"
	    "movq	%%mm1, %%mm4\n\t"
	    "pfmul	16(%2), %%mm3\n\t"
	    "pfmul	24(%2), %%mm4\n\t"
	    "pfadd	%%mm4, %%mm3\n\t"
	    "pswapd	%%mm3, %%mm4\n\t"
	    "pfadd	%%mm4, %%mm3\n"
	    "\n\t"
	    "punpckldq	%%mm3, %%mm2\n\t"
	    "movq	%%mm2, (%1)\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	32(%2), %%mm2\n\t"
	    "pfmul	40(%2), %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n\t"
	    "pswapd	%%mm2, %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n"
	    "\n\t"
	    "pfmul	48(%2), %%mm0\n\t"
	    "pfmul	56(%2), %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "pswapd	%%mm0, %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n"
	    "\n\t"
	    "punpckldq	%%mm0, %%mm2\n\t"
	    "movq	%%mm2, 8(%1)\n"
	    "\n\t"
	    "add	$16, %1\n\t"
	    "dec	%0\n\t"
	    "jnz	0b\n"
	    "\n\t"
	    "0:\n\t"
	    "femms"
	    : "+r"(count), "+r"(vectors)
	    : "r"(self->_values)
	    : "mm0", "mm1", "mm2", "mm3", "mm4", "memory"
	);
}
# ifndef __clang__
#  pragma GCC pop_options
# endif

# ifndef __clang__
#  pragma GCC push_options
#  pragma GCC target("3dnow")
# endif
static void
multiplyWithMatrix_3DNow(OFMatrix4x4 *self, SEL _cmd, OFMatrix4x4 *matrix)
{
	float (*left)[4] = matrix->_values, (*right)[4] = self->_values;
	float result[4][4], (*resultPtr)[4] = result;

	__asm__ __volatile__ (
	    "xorw	%%cx, %%cx\n"
	    "\n\t"
	    "0:\n\t"
	    "movd	(%2), %%mm0\n\t"
	    "punpckldq	16(%2), %%mm0\n\t"
	    "pfmul	(%1), %%mm0\n\t"
	    "movd	32(%2), %%mm1\n\t"
	    "punpckldq  48(%2), %%mm1\n\t"
	    "pfmul	8(%1), %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "movq	%%mm0, %%mm1\n\t"
	    "psrlq	$32, %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "movd	%%mm0, (%0)\n"
	    "\n\t"
	    "add	$4, %0\n\t"
	    "add	$4, %2\n\t"
	    "incb	%%cl\n\t"
	    "cmpb	$4, %%cl\n\t"
	    "jb		0b\n"
	    "\n\t"
	    "add	$16, %1\n\t"
	    "sub	$16, %2\n\t"
	    "xorb	%%cl, %%cl\n\t"
	    "incb	%%ch\n\t"
	    "cmpb	$4, %%ch\n\t"
	    "jb		0b\n"
	    "\n\t"
	    "femms"
	    : "+r"(resultPtr), "+r"(left), "+r"(right)
	    :: "cx", "mm0", "mm1", "memory"
	);

	memcpy(self->_values, result, 16 * sizeof(float));
}

static void
transformVectors_3DNow(OFMatrix4x4 *self, SEL _cmd, OFVector4D *vectors,
    size_t count)
{
	__asm__ __volatile__ (
	    "test	%0, %0\n\t"
	    "jz		0f\n"
	    "\n\t"
	    "0:\n\t"
	    "movq	(%1), %%mm0\n\t"
	    "movq	8(%1), %%mm1\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	(%2), %%mm2\n\t"
	    "pfmul	8(%2), %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n\t"
	    "movq	%%mm2, %%mm3\n\t"
	    "psrlq	$32, %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n"
	    "\n\t"
	    "movq	%%mm0, %%mm3\n\t"
	    "movq	%%mm1, %%mm4\n\t"
	    "pfmul	16(%2), %%mm3\n\t"
	    "pfmul	24(%2), %%mm4\n\t"
	    "pfadd	%%mm4, %%mm3\n\t"
	    "movq	%%mm3, %%mm4\n\t"
	    "psrlq	$32, %%mm4\n\t"
	    "pfadd	%%mm4, %%mm3\n"
	    "\n\t"
	    "punpckldq	%%mm3, %%mm2\n\t"
	    "movq	%%mm2, (%1)\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	32(%2), %%mm2\n\t"
	    "pfmul	40(%2), %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n\t"
	    "movq	%%mm2, %%mm3\n\t"
	    "psrlq	$32, %%mm3\n\t"
	    "pfadd	%%mm3, %%mm2\n"
	    "\n\t"
	    "pfmul	48(%2), %%mm0\n\t"
	    "pfmul	56(%2), %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n\t"
	    "movq	%%mm0, %%mm1\n\t"
	    "psrlq	$32, %%mm1\n\t"
	    "pfadd	%%mm1, %%mm0\n"
	    "\n\t"
	    "punpckldq	%%mm0, %%mm2\n\t"
	    "movq	%%mm2, 8(%1)\n"
	    "\n\t"
	    "add	$16, %1\n\t"
	    "dec	%0\n\t"
	    "jnz	0b\n"
	    "\n\t"
	    "0:\n\t"
	    "femms"
	    : "+r"(count), "+r"(vectors)
	    : "r"(self->_values)
	    : "mm0", "mm1", "mm2", "mm3", "mm4", "memory"
	);
}
# ifndef __clang__
#  pragma GCC pop_options
# endif

+ (void)initialize
{
	const char *typeEncoding;

	if (self != [OFMatrix4x4 class])
		return;

# define REPLACE(selector, func)					\
	typeEncoding = method_getTypeEncoding(				\
	    class_getInstanceMethod(self, selector));			\
	class_replaceMethod(self, selector, (IMP)func, typeEncoding);

	if ([OFSystemInfo supportsSSE41]) {
		REPLACE(@selector(transformVectors:count:),
		    transformVectors_SSE41)
	} else if ([OFSystemInfo supports3DNow]) {
		if ([OFSystemInfo supportsEnhanced3DNow]) {
			REPLACE(@selector(multiplyWithMatrix:),
			    multiplyWithMatrix_enhanced3DNow)
			REPLACE(@selector(transformVectors:count:),
			    transformVectors_enhanced3DNow)
		} else {
			REPLACE(@selector(multiplyWithMatrix:),
			    multiplyWithMatrix_3DNow)
			REPLACE(@selector(transformVectors:count:),
			    transformVectors_3DNow)
		}
	}

# undef REPLACE
}
#endif

+ (instancetype)alloc
{
	OFMatrix4x4 *instance;
	float (*values)[4];

	instance = OFAllocObject(self, 16 * sizeof(float), 16,
	    (void **)&values);
	instance->_values = values;

	return instance;
}

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

	memcpy(_values, values, 16 * sizeof(float));

	return self;
}

- (float (*)[4])values
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

	for (uint_fast8_t i = 0; i < 4; i++)
		for (uint_fast8_t j = 0; j < 4; j++)
			OFHashAddHash(&hash, OFFloatToRawUInt32(_values[i][j]));

	OFHashFinalize(&hash);

	return hash;
}

- (void)multiplyWithMatrix: (OFMatrix4x4 *)matrix
{
	float result[4][4];

	for (uint_fast8_t i = 0; i < 4; i++)
		for (uint_fast8_t j = 0; j < 4; j++)
			result[i][j] =
			    matrix->_values[i][0] * _values[0][j] +
			    matrix->_values[i][1] * _values[1][j] +
			    matrix->_values[i][2] * _values[2][j] +
			    matrix->_values[i][3] * _values[3][j];

	memcpy(_values, result, 16 * sizeof(float));
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
	OFVector4D copy = vector;

	[self transformVectors: &copy count: 1];

	return copy;
}

- (void)transformVectors: (OFVector4D *)vectors count: (size_t)count
{
	for (size_t i = 0; i < count; i++) {
		OFVector4D vector = vectors[i];

		vectors[i].x = _values[0][0] * vector.x +
		    _values[0][1] * vector.y + _values[0][2] * vector.z +
		    _values[0][3] * vector.w;
		vectors[i].y = _values[1][0] * vector.x +
		    _values[1][1] * vector.y + _values[1][2] * vector.z +
		    _values[1][3] * vector.w;
		vectors[i].z = _values[2][0] * vector.x +
		    _values[2][1] * vector.y + _values[2][2] * vector.z +
		    _values[2][3] * vector.w;
		vectors[i].w = _values[3][0] * vector.x +
		    _values[3][1] * vector.y + _values[3][2] * vector.z +
		    _values[3][3] * vector.w;
	}
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
