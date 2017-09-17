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
#include <stdlib.h>
#include <xmmintrin.h>

#import "OFInvocation.h"
#import "OFMethodSignature.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

#import "macros.h"

#define NUM_GPR_IN 6
#define NUM_GPR_OUT 2
#define NUM_SSE_IN 8
#define NUM_X87_OUT 2

enum {
	RETURN_TYPE_NORMAL,
	RETURN_TYPE_STRUCT,
	RETURN_TYPE_X87,
	RETURN_TYPE_JMP,
	RETURN_TYPE_JMP_STRET
};

struct call_context {
	uint64_t gpr[NUM_GPR_IN + NUM_GPR_OUT];
	__m128 sse[NUM_SSE_IN];
	long double x87[NUM_X87_OUT];
	uint8_t num_sse_used;
	uint8_t return_type;
	uint64_t stack_size;
	uint64_t stack[];
};

extern void of_invocation_call(struct call_context *);

static void
pushGPR(struct call_context **context, uint_fast8_t *currentGPR, uint64_t value)
{
	struct call_context *newContext;

	if (*currentGPR < NUM_GPR_IN) {
		(*context)->gpr[(*currentGPR)++] = value;
		return;
	}

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stack_size + 1) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stack_size + 1) * 8];
	}

	newContext->stack[newContext->stack_size] = value;
	newContext->stack_size++;
	*context = newContext;
}

static void
pushDouble(struct call_context **context, uint_fast8_t *currentSSE,
    double value)
{
	struct call_context *newContext;

	if (*currentSSE < NUM_SSE_IN) {
		(*context)->sse[(*currentSSE)++] = (__m128)_mm_set_sd(value);
		(*context)->num_sse_used++;
		return;
	}

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stack_size + 1) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stack_size + 1) * 8];
	}

	memcpy(&newContext->stack[newContext->stack_size], &value, 8);
	newContext->stack_size++;
	*context = newContext;
}

static void
pushLongDouble(struct call_context **context, long double value)
{
	struct call_context *newContext;

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stack_size + 2) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stack_size + 2) * 8];
	}

	memcpy(&newContext->stack[newContext->stack_size], &value, 16);
	newContext->stack_size += 2;
	*context = newContext;
}

#if defined(__SIZEOF_INT128__) && !defined(__clang__)
static void
pushInt128(struct call_context **context, uint_fast8_t *currentGPR,
    uint64_t low, uint64_t high)
{
	struct call_context *newContext;
	size_t stackSize;

	if (*currentGPR + 1 < NUM_GPR_IN) {
		(*context)->gpr[(*currentGPR)++] = low;
		(*context)->gpr[(*currentGPR)++] = high;
		return;
	}

	stackSize = OF_ROUND_UP_POW2(2, (*context)->stack_size) + 2;

	if ((newContext = realloc(*context,
	    sizeof(**context) + stackSize * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + stackSize * 8];
	}

	memset(&newContext->stack[newContext->stack_size], '\0',
	    (stackSize - newContext->stack_size) * 8);
	newContext->stack[stackSize - 2] = low;
	newContext->stack[stackSize - 1] = high;
	newContext->stack_size = stackSize;
	*context = newContext;
}
#endif

void
of_invocation_invoke(OFInvocation *invocation)
{
	OFMethodSignature *methodSignature = [invocation methodSignature];
	size_t numberOfArguments = [methodSignature numberOfArguments];
	struct call_context *context;
	const char *typeEncoding;
	uint_fast8_t currentGPR = 0, currentSSE = 0;

	if ((context = calloc(sizeof(*context), 1)) == NULL)
		@throw [OFOutOfMemoryException exception];

	for (size_t i = 0; i < numberOfArguments; i++) {
		typeEncoding = [methodSignature argumentTypeAtIndex: i];

		if (*typeEncoding == 'r')
			typeEncoding++;

		switch (*typeEncoding) {
#define CASE_GPR(encoding, type)					\
		case encoding:						\
			{						\
				type tmp;				\
				[invocation getArgument: &tmp		\
						atIndex: i];		\
				pushGPR(&context, &currentGPR, tmp);	\
			}						\
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
		case 't':
		case 'T':;
			struct {
				uint64_t low, high;
			} int128Tmp;
			[invocation getArgument: &int128Tmp
					atIndex: i];
# ifndef __clang__
			pushInt128(&context, &currentGPR,
			    int128Tmp.low, int128Tmp.high);
# else
			pushGPR(&context, &currentGPR, int128Tmp.low);
			pushGPR(&context, &currentGPR, int128Tmp.high);
# endif
			break;
#endif
		case 'f':;
			float floatTmp;
			[invocation getArgument: &floatTmp
					atIndex: i];
			pushDouble(&context, &currentSSE, floatTmp);
			break;
		case 'd':;
			double doubleTmp;
			[invocation getArgument: &doubleTmp
					atIndex: i];
			pushDouble(&context, &currentSSE, doubleTmp);
			break;
		case 'D':;
			long double longDoubleTmp;
			[invocation getArgument: &longDoubleTmp
					atIndex: i];
			pushLongDouble(&context, longDoubleTmp);
			break;
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
			free(context);
			@throw [OFInvalidFormatException exception];
#undef CASE_GPR
		}
	}

	typeEncoding = [methodSignature methodReturnType];

	if (*typeEncoding == 'r')
		typeEncoding++;

	switch (*typeEncoding) {
	case 'c':
	case 'C':
	case 'i':
	case 'I':
	case 's':
	case 'S':
	case 'l':
	case 'L':
	case 'q':
	case 'Q':
#ifdef __SIZEOF_INT128__
	case 't':
	case 'T':
#endif
	case 'f':
	case 'd':
	case 'B':
	case '*':
	case '@':
	case '#':
	case ':':
	case '^':
		context->return_type = RETURN_TYPE_NORMAL;
		break;
	case 'D':
		context->return_type = RETURN_TYPE_X87;
		break;
	/* TODO: '[' */
	/* TODO: '{' */
	/* TODO: '(' */
#ifndef __STDC_NO_COMPLEX__
	/* TODO: 'j' */
#endif
	default:
		free(context);
		@throw [OFInvalidFormatException exception];
	}

	of_invocation_call(context);

	switch (*typeEncoding) {
#define CASE_GPR(encoding, type)					   \
		case encoding:						   \
			{						   \
				type tmp = (type)context->gpr[NUM_GPR_IN]; \
				[invocation setReturnValue: &tmp];	   \
			}						   \
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
		case 't':
		case 'T':;
			[invocation setReturnValue: &context->gpr[NUM_GPR_IN]];
			break;
#endif
		case 'f':;
			float floatTmp;
			_mm_store_ss(&floatTmp, context->sse[0]);
			[invocation setReturnValue: &floatTmp];
			break;
		case 'd':;
			double doubleTmp;
			_mm_store_sd(&doubleTmp, (__m128d)context->sse[0]);
			[invocation setReturnValue: &doubleTmp];
			break;
		case 'D':
			[invocation setReturnValue: &context->x87[0]];
			break;
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
			free(context);
			@throw [OFInvalidFormatException exception];
#undef CASE_GPR
	}

	free(context);
}
