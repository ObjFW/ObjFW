/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdint.h>
#include <stdlib.h>
#include <xmmintrin.h>

#import "OFInvocation.h"
#import "OFMethodSignature.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

#import "invoke-amd64.h"

#import "macros.h"

struct CallContext {
	uint64_t GPR[numGPRIn + numGPROut];
	__m128 SSE[numSSEInOut];
	long double X87[numX87Out];
	uint8_t numSSEUsed;
	uint8_t returnType;
	uint64_t stackSize;
	uint64_t stack[];
};

extern void OFInvocationCall(struct CallContext *);

static void
pushGPR(struct CallContext **context, uint_fast8_t *currentGPR, uint64_t value)
{
	struct CallContext *newContext;

	if (*currentGPR < numGPRIn) {
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
pushDouble(struct CallContext **context, uint_fast8_t *currentSSE,
    double value)
{
	struct CallContext *newContext;

	if (*currentSSE < numSSEInOut) {
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
pushQuad(struct CallContext **context, uint_fast8_t *currentSSE,
    double low, double high)
{
	size_t stackSize;
	struct CallContext *newContext;

	if (*currentSSE + 1 < numSSEInOut) {
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
pushLongDouble(struct CallContext **context, long double value)
{
	struct CallContext *newContext;

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
pushLongDoublePair(struct CallContext **context, long double value[2])
{
	size_t stackSize;
	struct CallContext *newContext;

	stackSize = OFRoundUpToPowerOf2(2UL, (*context)->stackSize) + 4;

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

#ifdef __SIZEOF_INT128__
static void
pushInt128(struct CallContext **context, uint_fast8_t *currentGPR,
    uint64_t value[2])
{
	size_t stackSize;
	struct CallContext *newContext;

	if (*currentGPR + 1 < numGPRIn) {
		(*context)->GPR[(*currentGPR)++] = value[0];
		(*context)->GPR[(*currentGPR)++] = value[1];
		return;
	}

	stackSize = OFRoundUpToPowerOf2(2, (*context)->stackSize) + 2;

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
OFInvocationInvoke(OFInvocation *invocation)
{
	OFMethodSignature *methodSignature = invocation.methodSignature;
	size_t numberOfArguments = methodSignature.numberOfArguments;
	struct CallContext *context;
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
			pushInt128(&context, &currentGPR, int128Tmp);
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
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
		}
	}

	typeEncoding = methodSignature.methodReturnType;

	if (*typeEncoding == 'r')
		typeEncoding++;

	switch (*typeEncoding) {
	case 'v':
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
		context->returnType = returnTypeNormal;
		break;
	case 'D':
		context->returnType = returnTypeX87;
		break;
	case 'j':
		switch (typeEncoding[1]) {
		case 'f':
		case 'd':
			context->returnType = returnTypeNormal;
			break;
		case 'D':
			context->returnType = returnTypeComplexX87;
			break;
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
		}

		break;
	/* TODO: '[' */
	/* TODO: '{' */
	/* TODO: '(' */
	default:
		free(context);
		@throw [OFInvalidFormatException exception];
	}

	OFInvocationCall(context);

	switch (*typeEncoding) {
		case 'v':
			break;
#define CASE_GPR(encoding, type)					 \
		case encoding:						 \
			{						 \
				type tmp = (type)context->GPR[numGPRIn]; \
				[invocation setReturnValue: &tmp];	 \
			}						 \
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
			[invocation setReturnValue: &context->GPR[numGPRIn]];
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
		/* TODO: '[' */
		/* TODO: '{' */
		/* TODO: '(' */
		default:
			free(context);
			@throw [OFInvalidFormatException exception];
	}

	free(context);
}
