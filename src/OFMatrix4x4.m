/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#  pragma GCC target("sse")
# endif
static void
transformVectors_SSE(OFMatrix4x4 *self, SEL _cmd, OFVector4D *vectors,
    size_t count)
{
	OF_ALIGN(16) float tmp[4];

	__asm__ __volatile__ (
	    "test	%[count], %[count]\n\t"
	    "jz		0f\n"
	    "\n\t"
	    "movaps	(%[matrix]), %%xmm0\n\t"
	    "movaps	16(%[matrix]), %%xmm1\n\t"
	    "movaps	32(%[matrix]), %%xmm2\n\t"
# ifdef OF_AMD64
	    "movaps	48(%[matrix]), %%xmm8\n"
# endif
	    "\n\t"
	    "0:\n\t"
	    "movaps	(%[vectors]), %%xmm3\n"
	    "\n\t"
	    "movaps	%%xmm0, %%xmm4\n\t"
	    "mulps	%%xmm3, %%xmm4\n\t"
	    "movaps	%%xmm4, (%[tmp])\n\t"
	    "addss	4(%[tmp]), %%xmm4\n\t"
	    "addss	8(%[tmp]), %%xmm4\n\t"
	    "addss	12(%[tmp]), %%xmm4\n"
	    "\n\t"
	    "movaps	%%xmm1, %%xmm5\n\t"
	    "mulps	%%xmm3, %%xmm5\n\t"
	    "movaps	%%xmm5, (%[tmp])\n\t"
	    "addss	4(%[tmp]), %%xmm5\n\t"
	    "addss	8(%[tmp]), %%xmm5\n\t"
	    "addss	12(%[tmp]), %%xmm5\n"
	    "\n\t"
	    "movaps	%%xmm2, %%xmm6\n\t"
	    "mulps	%%xmm3, %%xmm6\n\t"
	    "movaps	%%xmm6, (%[tmp])\n\t"
	    "addss	4(%[tmp]), %%xmm6\n\t"
	    "addss	8(%[tmp]), %%xmm6\n\t"
	    "addss	12(%[tmp]), %%xmm6\n"
	    "\n\t"
# ifdef OF_AMD64
	    "movaps	%%xmm8, %%xmm7\n\t"
# else
	    "movaps	48(%[matrix]), %%xmm7\n\t"
# endif
	    "mulps	%%xmm3, %%xmm7\n\t"
	    "movaps	%%xmm7, (%[tmp])\n\t"
	    "addss	4(%[tmp]), %%xmm7\n\t"
	    "addss	8(%[tmp]), %%xmm7\n\t"
	    "addss	12(%[tmp]), %%xmm7\n"
	    "\n\t"
	    "movss	%%xmm4, (%[vectors])\n\t"
	    "movss	%%xmm5, 4(%[vectors])\n\t"
	    "movss	%%xmm6, 8(%[vectors])\n\t"
	    "movss	%%xmm7, 12(%[vectors])\n"
	    "\n\t"
	    "add	$16, %[vectors]\n\t"
	    "dec	%[count]\n\t"
	    "jnz	0b\n"
	    : [count] "+r" (count),
	      [vectors] "+r" (vectors)
	    : [matrix] "r" (self->_values),
	      [tmp] "r" (&tmp)
	    : "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7",
# ifdef OF_AMD64
	      "xmm8",
# endif
	      "memory"
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
	    "movl	$4, %%ecx\n\t"
	    "\n\t"
	    "0:\n\t"
	    "movd	(%[right]), %%mm0\n\t"
	    "punpckldq	16(%[right]), %%mm0\n\t"
	    "pfmul	(%[left]), %%mm0\n\t"
	    "movd	32(%[right]), %%mm1\n\t"
	    "punpckldq  48(%[right]), %%mm1\n\t"
	    "pfmul	8(%[left]), %%mm1\n\t"
	    "pfacc	%%mm1, %%mm0\n\t"
	    "pfacc	%%mm0, %%mm0\n\t"
	    "movd	%%mm0, (%[result])\n\t"
	    "movd	4(%[right]), %%mm0\n\t"
	    "punpckldq	20(%[right]), %%mm0\n\t"
	    "pfmul	(%[left]), %%mm0\n\t"
	    "movd	36(%[right]), %%mm1\n\t"
	    "punpckldq  52(%[right]), %%mm1\n\t"
	    "pfmul	8(%[left]), %%mm1\n\t"
	    "pfacc	%%mm1, %%mm0\n\t"
	    "pfacc	%%mm0, %%mm0\n\t"
	    "movd	%%mm0, 4(%[result])\n\t"
	    "movd	8(%[right]), %%mm0\n\t"
	    "punpckldq	24(%[right]), %%mm0\n\t"
	    "pfmul	(%[left]), %%mm0\n\t"
	    "movd	40(%[right]), %%mm1\n\t"
	    "punpckldq  56(%[right]), %%mm1\n\t"
	    "pfmul	8(%[left]), %%mm1\n\t"
	    "pfacc	%%mm1, %%mm0\n\t"
	    "pfacc	%%mm0, %%mm0\n\t"
	    "movd	%%mm0, 8(%[result])\n\t"
	    "movd	12(%[right]), %%mm0\n\t"
	    "punpckldq	28(%[right]), %%mm0\n\t"
	    "pfmul	(%[left]), %%mm0\n\t"
	    "movd	44(%[right]), %%mm1\n\t"
	    "punpckldq  60(%[right]), %%mm1\n\t"
	    "pfmul	8(%[left]), %%mm1\n\t"
	    "pfacc	%%mm1, %%mm0\n\t"
	    "pfacc	%%mm0, %%mm0\n\t"
	    "movd	%%mm0, 12(%[result])\n"
	    "\n\t"
	    "add	$16, %[result]\n\t"
	    "add	$16, %[left]\n\t"
	    "decl	%%ecx\n\t"
	    "jnz	0b\n"
	    "\n\t"
	    "femms"
	    : [result] "+r" (resultPtr),
	      [left] "+r" (left),
	      [right] "+r" (right)
	    :
	    : "ecx", "mm0", "mm1", "memory"
	);

	memcpy(self->_values, result, 16 * sizeof(float));
}

static void
transformVectors_3DNow(OFMatrix4x4 *self, SEL _cmd, OFVector4D *vectors,
    size_t count)
{
	__asm__ __volatile__ (
	    "test	%[count], %[count]\n\t"
	    "jz		0f\n"
	    "\n\t"
	    "0:\n\t"
	    "movq	(%[vectors]), %%mm0\n\t"
	    "movq	8(%[vectors]), %%mm1\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	(%[matrix]), %%mm2\n\t"
	    "pfmul	8(%[matrix]), %%mm3\n\t"
	    "pfacc	%%mm3, %%mm2\n\t"
	    "pfacc	%%mm2, %%mm2\n\t"
	    "\n\t"
	    "movq	%%mm0, %%mm3\n\t"
	    "movq	%%mm1, %%mm4\n\t"
	    "pfmul	16(%[matrix]), %%mm3\n\t"
	    "pfmul	24(%[matrix]), %%mm4\n\t"
	    "pfacc	%%mm4, %%mm3\n\t"
	    "pfacc	%%mm3, %%mm3\n\t"
	    "\n\t"
	    "punpckldq	%%mm3, %%mm2\n\t"
	    "movq	%%mm2, (%[vectors])\n"
	    "\n\t"
	    "movq	%%mm0, %%mm2\n\t"
	    "movq	%%mm1, %%mm3\n\t"
	    "pfmul	32(%[matrix]), %%mm2\n\t"
	    "pfmul	40(%[matrix]), %%mm3\n\t"
	    "pfacc	%%mm3, %%mm2\n\t"
	    "pfacc	%%mm2, %%mm2\n\t"
	    "\n\t"
	    "pfmul	48(%[matrix]), %%mm0\n\t"
	    "pfmul	56(%[matrix]), %%mm1\n\t"
	    "pfacc	%%mm1, %%mm0\n\t"
	    "pfacc	%%mm0, %%mm0\n\t"
	    "\n\t"
	    "punpckldq	%%mm0, %%mm2\n\t"
	    "movq	%%mm2, 8(%[vectors])\n"
	    "\n\t"
	    "add	$16, %[vectors]\n\t"
	    "dec	%[count]\n\t"
	    "jnz	0b\n"
	    "\n\t"
	    "0:\n\t"
	    "femms"
	    : [count] "+r" (count),
	      [vectors] "+r" (vectors)
	    : [matrix] "r" (self->_values)
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

	if ([OFSystemInfo supportsSSE]) {
		REPLACE(@selector(transformVectors:count:),
		    transformVectors_SSE)
	} else if ([OFSystemInfo supports3DNow]) {
		REPLACE(@selector(multiplyWithMatrix:),
		    multiplyWithMatrix_3DNow)
		REPLACE(@selector(transformVectors:count:),
		    transformVectors_3DNow)
	}

# undef REPLACE
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

	memcpy(_values, values, 16 * sizeof(float));

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
	OF_ALIGN(16) OFVector4D copy = vector;

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
