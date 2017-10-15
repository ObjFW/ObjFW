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
	RETURN_TYPE_COMPLEX_X87,
	RETURN_TYPE_JMP,
	RETURN_TYPE_JMP_STRET
};

struct call_context {
	uint64_t GPR[NUM_GPR_IN + NUM_GPR_OUT];
	__m128 SSE[NUM_SSE_IN];
	long double X87[NUM_X87_OUT];
	uint8_t numSSEUsed;
	uint8_t returnType;
	uint64_t stackSize;
	uint64_t stack[];
};

extern void of_invocation_call(struct call_context *);

static void
pushGPR(struct call_context **context, uint_fast8_t *currentGPR, uint64_t value)
{
	struct call_context *newContext;

	if (*currentGPR < NUM_GPR_IN) {
		(*context)->GPR[(*currentGPR)++] = value;
		return;
	}

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stackSize + 1) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stackSize + 1) * 8];
	}

	newContext->stack[newContext->stackSize] = value;
	newContext->stackSize++;
	*context = newContext;
}

static void
pushDouble(struct call_context **context, uint_fast8_t *currentSSE,
    double value)
{
	struct call_context *newContext;

	if (*currentSSE < NUM_SSE_IN) {
		(*context)->SSE[(*currentSSE)++] = (__m128)_mm_set_sd(value);
		(*context)->numSSEUsed++;
		return;
	}

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stackSize + 1) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stackSize + 1) * 8];
	}

	memcpy(&newContext->stack[newContext->stackSize], &value, 8);
	newContext->stackSize++;
	*context = newContext;
}

static void
pushQuad(struct call_context **context, uint_fast8_t *currentSSE,
    double low, double high)
{
	size_t stackSize;
	struct call_context *newContext;

	if (*currentSSE + 1 < NUM_SSE_IN) {
		(*context)->SSE[(*currentSSE)++] = (__m128)_mm_set_sd(low);
		(*context)->SSE[(*currentSSE)++] = (__m128)_mm_set_sd(high);
		(*context)->numSSEUsed += 2;
		return;
	}

	stackSize = (*context)->stackSize + 2;

	if ((newContext = realloc(*context,
	    sizeof(**context) + stackSize * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + stackSize * 8];
	}

	memset(&newContext->stack[newContext->stackSize], '\0',
	    (stackSize - newContext->stackSize) * 8);
	memcpy(&newContext->stack[stackSize - 2], &low, 8);
	memcpy(&newContext->stack[stackSize - 1], &high, 8);
	newContext->stackSize = stackSize;
	*context = newContext;
}

static void
pushLongDouble(struct call_context **context, long double value)
{
	struct call_context *newContext;

	if ((newContext = realloc(*context,
	    sizeof(**context) + ((*context)->stackSize + 2) * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + ((*context)->stackSize + 2) * 8];
	}

	memcpy(&newContext->stack[newContext->stackSize], &value, 16);
	newContext->stackSize += 2;
	*context = newContext;
}

static void
pushLongDoublePair(struct call_context **context, long double value[2])
{
	size_t stackSize;
	struct call_context *newContext;

	stackSize = OF_ROUND_UP_POW2(2UL, (*context)->stackSize) + 4;

	if ((newContext = realloc(*context,
	    sizeof(**context) + stackSize * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + stackSize * 8];
	}

	memset(&newContext->stack[newContext->stackSize], '\0',
	    (stackSize - newContext->stackSize) * 8);
	memcpy(&newContext->stack[stackSize - 4], value, 32);
	newContext->stackSize = stackSize;
	*context = newContext;
}

#if defined(__SIZEOF_INT128__) && !defined(__clang__)
static void
pushInt128(struct call_context **context, uint_fast8_t *currentGPR,
    uint64_t value[2])
{
	size_t stackSize;
	struct call_context *newContext;

	if (*currentGPR + 1 < NUM_GPR_IN) {
		(*context)->GPR[(*currentGPR)++] = value[0];
		(*context)->GPR[(*currentGPR)++] = value[1];
		return;
	}

	stackSize = OF_ROUND_UP_POW2(2, (*context)->stackSize) + 2;

	if ((newContext = realloc(*context,
	    sizeof(**context) + stackSize * 8)) == NULL) {
		free(*context);
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    sizeof(**context) + stackSize * 8];
	}

	memset(&newContext->stack[newContext->stackSize], '\0',
	    (stackSize - newContext->stackSize) * 8);
	memcpy(&newContext->stack[stackSize - 2], value, 16);
	newContext->stackSize = stackSize;
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
#define CASE_GPR(encoding, type)					       \
		case encoding:						       \
			{						       \
				type tmp;				       \
				[invocation getArgument: &tmp		       \
						atIndex: i];		       \
				pushGPR(&context, &currentGPR, (uint64_t)tmp); \
			}						       \
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
		CASE_GPR('B', _Bool)
		CASE_GPR('*', char *)
		CASE_GPR('@', id)
		CASE_GPR('#', Class)
		/*
		 * Using SEL triggers a warning that casting a SEL to an
		 * integer is deprecated.
		 */
		CASE_GPR(':', void *)
		CASE_GPR('^', void *)
#undef CASE_GPR
#ifdef __SIZEOF_INT128__
		case 't':
		case 'T':;
			uint64_t int128Tmp[2];
			[invocation getArgument: &int128Tmp
					atIndex: i];
# ifndef __clang__
			pushInt128(&context, &currentGPR, int128Tmp);
# else
			/* See https://bugs.llvm.org/show_bug.cgi?id=34646 */
			pushGPR(&context, &currentGPR, int128Tmp[0]);
			pushGPR(&context, &currentGPR, int128Tmp[1]);
# endif
			break;
#endif
		case 'f':;
			double floatTmp = 0;
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
#ifndef __STDC_NO_COMPLEX__
		case 'j':
			switch (typeEncoding[1]) {
			case 'f':;
				double complexFloatTmp;
				[invocation getArgument: &complexFloatTmp
						atIndex: i];
				pushDouble(&context, &currentSSE,
				    complexFloatTmp);
				break;
			case 'd':;
				double complexDoubleTmp[2];
				[invocation getArgument: &complexDoubleTmp
						atIndex: i];
				pushQuad(&context, &currentSSE,
				    complexDoubleTmp[0], complexDoubleTmp[1]);
				break;
			case 'D':;
				long double complexLongDoubleTmp[2];
				[invocation getArgument: &complexLongDoubleTmp
						atIndex: i];
				pushLongDoublePair(&context,
				    complexLongDoubleTmp);
				break;
			default:
				free(context);
				@throw [OFInvalidFormatException exception];
			}

			break;
#endif
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
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
	case 'B':
	case '*':
	case '@':
	case '#':
	case ':':
	case '^':
#ifdef __SIZEOF_INT128__
	case 't':
	case 'T':
#endif
	case 'f':
	case 'd':
		context->returnType = RETURN_TYPE_NORMAL;
		break;
	case 'D':
		context->returnType = RETURN_TYPE_X87;
		break;
#ifndef __STDC_NO_COMPLEX__
	case 'j':
		switch (typeEncoding[1]) {
		case 'f':
		case 'd':
			context->returnType = RETURN_TYPE_NORMAL;
			break;
		case 'D':
			context->returnType = RETURN_TYPE_COMPLEX_X87;
			break;
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
		}

		break;
#endif
	/* TODO: '[' */
	/* TODO: '{' */
	/* TODO: '(' */
	default:
		free(context);
		@throw [OFInvalidFormatException exception];
	}

	of_invocation_call(context);

	switch (*typeEncoding) {
#define CASE_GPR(encoding, type)					   \
		case encoding:						   \
			{						   \
				type tmp = (type)context->GPR[NUM_GPR_IN]; \
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
		CASE_GPR('B', _Bool)
		CASE_GPR('*', char *)
		CASE_GPR('@', id)
		CASE_GPR('#', Class)
		CASE_GPR(':', SEL)
		CASE_GPR('^', void *)
#undef CASE_GPR
#ifdef __SIZEOF_INT128__
		case 't':
		case 'T':;
			[invocation setReturnValue: &context->GPR[NUM_GPR_IN]];
			break;
#endif
		case 'f':;
			float floatTmp;
			_mm_store_ss(&floatTmp, context->SSE[0]);
			[invocation setReturnValue: &floatTmp];
			break;
		case 'd':;
			double doubleTmp;
			_mm_store_sd(&doubleTmp, (__m128d)context->SSE[0]);
			[invocation setReturnValue: &doubleTmp];
			break;
		case 'D':
			[invocation setReturnValue: &context->X87[0]];
			break;
#ifndef __STDC_NO_COMPLEX__
		case 'j':
			switch (typeEncoding[1]) {
			case 'f':;
				double complexFloatTmp;
				_mm_store_sd(&complexFloatTmp,
				    (__m128d)context->SSE[0]);
				[invocation setReturnValue: &complexFloatTmp];
				break;
			case 'd':;
				double complexDoubleTmp[2];
				_mm_store_sd(&complexDoubleTmp[0],
				    (__m128d)context->SSE[0]);
				_mm_store_sd(&complexDoubleTmp[1],
				    (__m128d)context->SSE[1]);
				[invocation setReturnValue: &complexDoubleTmp];
				break;
			case 'D':
				[invocation setReturnValue: context->X87];
				break;
			default:
				free(context);
				@throw [OFInvalidFormatException exception];
			}

			break;
#endif
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
	}

	free(context);
}
