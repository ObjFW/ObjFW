/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include <stdint.h>
#include <xmmintrin.h>

#import "OFInvocation.h"
#import "OFMethodSignature.h"

#import "OFInvalidFormatException.h"

#define NUM_GPR_IN 6
#define NUM_GPR_OUT 2
#define NUM_SSE_IN 8
#define NUM_SSE_OUT 2

struct registers {
	uint64_t gpr[NUM_GPR_IN + NUM_GPR_OUT];
	__m128 sse[NUM_SSE_IN];
	uint8_t num_sse;
};

extern void of_invocation_call(struct registers *);

void
of_invocation_invoke(OFInvocation *invocation)
{
	OFMethodSignature *methodSignature = [invocation methodSignature];
	size_t numberOfArguments = [methodSignature numberOfArguments];
	const char *typeEncoding;
	struct registers registers;
	size_t currentGPR = 0, currentSSE = 0;

	memset(&registers, '\0', sizeof(registers));

	for (size_t i = 0; i < numberOfArguments; i++) {
		union {
			uint64_t gpr;
			__m128 sse;
		} value;
		enum {
			VALUE_GPR,
			VALUE_SSE
		} valueType;

		typeEncoding = [methodSignature argumentTypeAtIndex: i];

		if (*typeEncoding == 'r')
			typeEncoding++;

		switch (*typeEncoding) {
#define CASE_GPR(encoding, type)				\
		case encoding:					\
			{					\
				type tmp;			\
				[invocation getArgument: &tmp	\
						atIndex: i];	\
				value.gpr = tmp;		\
				valueType = VALUE_GPR;		\
			}					\
			break;
		CASE_GPR('c', char)
		CASE_GPR('C', unsigned char)
		CASE_GPR('i', int)
		CASE_GPR('I', unsigned int)
		CASE_GPR('s', short)
		CASE_GPR('S', unsigned short)
		CASE_GPR('l', long)
		CASE_GPR('L', unsigned long)
		CASE_GPR('q', long long)
		CASE_GPR('Q', unsigned long long)
#ifdef __SIZEOF_INT128__
		/* TODO: 't' */
		/* TODO: 'T' */
#endif
		case 'f':
			{
				float tmp;
				[invocation getArgument: &tmp
						atIndex: i];
				value.sse = _mm_set_ss(tmp);
				valueType = VALUE_SSE;
			}
			break;
		case 'd':
			{
				double tmp;
				[invocation getArgument: &tmp
						atIndex: i];
				value.sse = _mm_set_sd(tmp);
				valueType = VALUE_SSE;
			}
			break;
		/* TODO: 'D' */
		CASE_GPR('B', _Bool)
		CASE_GPR('*', uintptr_t)
		CASE_GPR('@', uintptr_t)
		CASE_GPR('#', uintptr_t)
		CASE_GPR(':', uintptr_t)
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		CASE_GPR('^', uintptr_t)
#ifndef __STDC_NO_COMPLEX__
		/* TODO: 'j' */
#endif
		default:
			@throw [OFInvalidFormatException exception];
#undef CASE_GPR
		}

		if (valueType == VALUE_GPR) {
			if (currentGPR < NUM_GPR_IN)
				registers.gpr[currentGPR++] = value.gpr;
			else
				/* TODO */
				abort();
		} else if (valueType == VALUE_SSE) {
			if (currentSSE < NUM_SSE_IN) {
				registers.sse[currentSSE++] = value.sse;
				registers.num_sse++;
			} else
				/* TODO */
				abort();
		}
	}

	of_invocation_call(&registers);

	typeEncoding = [methodSignature methodReturnType];

	if (*typeEncoding == 'r')
		typeEncoding++;

	switch (*typeEncoding) {
#define CASE_GPR(encoding, type)					    \
		case encoding:						    \
			{						    \
				type tmp = (type)registers.gpr[NUM_GPR_IN]; \
				[invocation setReturnValue: &tmp];	    \
			}						    \
			break;
		CASE_GPR('c', char)
		CASE_GPR('C', unsigned char)
		CASE_GPR('i', int)
		CASE_GPR('I', unsigned int)
		CASE_GPR('s', short)
		CASE_GPR('S', unsigned short)
		CASE_GPR('l', long)
		CASE_GPR('L', unsigned long)
		CASE_GPR('q', long long)
		CASE_GPR('Q', unsigned long long)
#ifdef __SIZEOF_INT128__
		/* TODO: 't' */
		/* TODO: 'T' */
#endif
		case 'f':
			{
				float tmp;
				_mm_store_ss(&tmp, registers.sse[0]);
				[invocation setReturnValue: &tmp];
			}
			break;
		case 'd':
			{
				double tmp;
				_mm_store_sd(&tmp, registers.sse[0]);
				[invocation setReturnValue: &tmp];
			}
			break;
		/* TODO: 'D' */
		CASE_GPR('B', _Bool)
		CASE_GPR('*', uintptr_t)
		CASE_GPR('@', uintptr_t)
		CASE_GPR('#', uintptr_t)
		CASE_GPR(':', uintptr_t)
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		CASE_GPR('^', uintptr_t)
#ifndef __STDC_NO_COMPLEX__
		/* TODO: 'j' */
#endif
		default:
			@throw [OFInvalidFormatException exception];
#undef CASE_GPR
	}
}
