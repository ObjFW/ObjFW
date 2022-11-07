/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include <assert.h>
#include <ctype.h>

#import "OFMethodSignature.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static size_t alignmentOfEncoding(const char **type, size_t *length,
    bool inStruct);
static size_t sizeOfEncoding(const char **type, size_t *length);

static size_t
alignmentOfArray(const char **type, size_t *length)
{
	size_t alignment;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	while (*length > 0 && OFASCIIIsDigit(**type)) {
		(*type)++;
		(*length)--;
	}

	alignment = alignmentOfEncoding(type, length, true);

	if (*length == 0 || **type != ']')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return alignment;
}

static size_t
alignmentOfStruct(const char **type, size_t *length)
{
	size_t alignment = 0;
#if defined(OF_POWERPC) && defined(OF_MACOS)
	bool first = true;
#endif

	assert(*length > 0);

	(*type)++;
	(*length)--;

	/* Skip name */
	while (*length > 0 && **type != '=') {
		(*type)++;
		(*length)--;
	}

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	/* Skip '=' */
	(*type)++;
	(*length)--;

	while (*length > 0 && **type != '}') {
		size_t fieldAlignment = alignmentOfEncoding(type, length, true);

#if defined(OF_POWERPC) && defined(OF_MACOS)
		if (!first && fieldAlignment > 4)
			fieldAlignment = 4;

		first = false;
#endif

		if (fieldAlignment > alignment)
			alignment = fieldAlignment;
	}

	if (*length == 0 || **type != '}')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return alignment;
}

static size_t
alignmentOfUnion(const char **type, size_t *length)
{
	size_t alignment = 0;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	/* Skip name */
	while (*length > 0 && **type != '=') {
		(*type)++;
		(*length)--;
	}

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	/* Skip '=' */
	(*type)++;
	(*length)--;

	while (*length > 0 && **type != ')') {
		size_t fieldAlignment = alignmentOfEncoding(type, length, true);

		if (fieldAlignment > alignment)
			alignment = fieldAlignment;
	}

	if (*length == 0 || **type != ')')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return alignment;
}

static size_t
#if defined(__clang__) && __clang_major__ == 3 && __clang_minor__ <= 7
/* Work around an ICE in Clang 3.7.0 on Windows/x86 */
__attribute__((__optnone__))
#endif
alignmentOfEncoding(const char **type, size_t *length, bool inStruct)
{
	size_t alignment;

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	if (**type == 'r') {
		(*type)++;
		(*length)--;

		if (*length == 0)
			@throw [OFInvalidFormatException exception];
	}

	switch (**type) {
	case 'c':
	case 'C':
		alignment = OF_ALIGNOF(char);
		break;
	case 'i':
	case 'I':
		alignment = OF_ALIGNOF(int);
		break;
	case 's':
	case 'S':
		alignment = OF_ALIGNOF(short);
		break;
	case 'l':
	case 'L':
		alignment = OF_ALIGNOF(long);
		break;
	case 'q':
	case 'Q':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			alignment = 4;
		else
#endif
			alignment = OF_ALIGNOF(long long);
		break;
#ifdef __SIZEOF_INT128__
	case 't':
	case 'T':
		alignment = __extension__ OF_ALIGNOF(__int128);
		break;
#endif
	case 'f':
		alignment = OF_ALIGNOF(float);
		break;
	case 'd':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			alignment = 4;
		else
#endif
			alignment = OF_ALIGNOF(double);
		break;
	case 'D':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			alignment = 4;
		else
#endif
			alignment = OF_ALIGNOF(long double);
		break;
	case 'B':
		alignment = OF_ALIGNOF(_Bool);
		break;
	case 'v':
		alignment = 0;
		break;
	case '*':
		alignment = OF_ALIGNOF(char *);
		break;
	case '@':
		alignment = OF_ALIGNOF(id);
		break;
	case '#':
		alignment = OF_ALIGNOF(Class);
		break;
	case ':':
		alignment = OF_ALIGNOF(SEL);
		break;
	case '[':
		return alignmentOfArray(type, length);
	case '{':
		return alignmentOfStruct(type, length);
	case '(':
		return alignmentOfUnion(type, length);
	case '^':
		/* Just to skip over the rest */
		(*type)++;
		(*length)--;
		alignmentOfEncoding(type, length, false);

		return OF_ALIGNOF(void *);
#ifndef __STDC_NO_COMPLEX__
	case 'j':
		(*type)++;
		(*length)--;

		if (*length == 0)
			@throw [OFInvalidFormatException exception];

		switch (**type) {
		case 'f':
			alignment = OF_ALIGNOF(float _Complex);
			break;
		case 'd':
# if defined(OF_X86) && !defined(OF_WINDOWS)
			if (inStruct)
				alignment = 4;
			else
# endif
				alignment = OF_ALIGNOF(double _Complex);
			break;
		case 'D':
			alignment = OF_ALIGNOF(long double _Complex);
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		break;
#endif
	default:
		@throw [OFInvalidFormatException exception];
	}

	(*type)++;
	(*length)--;

	return alignment;
}

static size_t
sizeOfArray(const char **type, size_t *length)
{
	size_t count = 0;
	size_t size;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	while (*length > 0 && OFASCIIIsDigit(**type)) {
		count = count * 10 + **type - '0';

		(*type)++;
		(*length)--;
	}

	if (count == 0)
		@throw [OFInvalidFormatException exception];

	size = sizeOfEncoding(type, length);

	if (*length == 0 || **type != ']')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	if (SIZE_MAX / count < size)
		@throw [OFOutOfRangeException exception];

	return count * size;
}

static size_t
sizeOfStruct(const char **type, size_t *length)
{
	size_t size = 0;
	const char *typeCopy = *type;
	size_t lengthCopy = *length;
	size_t alignment = alignmentOfStruct(&typeCopy, &lengthCopy);
#if defined(OF_POWERPC) && defined(OF_MACOS)
	bool first = true;
#endif

	assert(*length > 0);

	(*type)++;
	(*length)--;

	/* Skip name */
	while (*length > 0 && **type != '=') {
		(*type)++;
		(*length)--;
	}

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	/* Skip '=' */
	(*type)++;
	(*length)--;

	while (*length > 0 && **type != '}') {
		size_t fieldSize, fieldAlignment;

		typeCopy = *type;
		lengthCopy = *length;
		fieldSize = sizeOfEncoding(type, length);
		fieldAlignment = alignmentOfEncoding(&typeCopy, &lengthCopy,
		    true);

#if defined(OF_POWERPC) && defined(OF_MACOS)
		if (!first && fieldAlignment > 4)
			fieldAlignment = 4;

		first = false;
#endif

		if (size % fieldAlignment != 0) {
			size_t padding =
			    fieldAlignment - (size % fieldAlignment);

			if (SIZE_MAX - size < padding)
				@throw [OFOutOfRangeException exception];

			size += padding;
		}

		if (SIZE_MAX - size < fieldSize)
			@throw [OFOutOfRangeException exception];

		size += fieldSize;
	}

	if (*length == 0 || **type != '}')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	if (size % alignment != 0) {
		size_t padding = alignment - (size % alignment);

		if (SIZE_MAX - size < padding)
			@throw [OFOutOfRangeException exception];

		size += padding;
	}

	return size;
}

static size_t
sizeOfUnion(const char **type, size_t *length)
{
	size_t size = 0;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	/* Skip name */
	while (*length > 0 && **type != '=') {
		(*type)++;
		(*length)--;
	}

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	/* Skip '=' */
	(*type)++;
	(*length)--;

	while (*length > 0 && **type != ')') {
		size_t fieldSize = sizeOfEncoding(type, length);

		if (fieldSize > size)
			size = fieldSize;
	}

	if (*length == 0 || **type != ')')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return size;
}

static size_t
sizeOfEncoding(const char **type, size_t *length)
{
	size_t size;

	if (*length == 0)
		@throw [OFInvalidFormatException exception];

	if (**type == 'r') {
		(*type)++;
		(*length)--;

		if (*length == 0)
			@throw [OFInvalidFormatException exception];
	}

	switch (**type) {
	case 'c':
	case 'C':
		size = sizeof(char);
		break;
	case 'i':
	case 'I':
		size = sizeof(int);
		break;
	case 's':
	case 'S':
		size = sizeof(short);
		break;
	case 'l':
	case 'L':
		size = sizeof(long);
		break;
	case 'q':
	case 'Q':
		size = sizeof(long long);
		break;
#ifdef __SIZEOF_INT128__
	case 't':
	case 'T':
		size = __extension__ sizeof(__int128);
		break;
#endif
	case 'f':
		size = sizeof(float);
		break;
	case 'd':
		size = sizeof(double);
		break;
	case 'D':
		size = sizeof(long double);
		break;
	case 'B':
		size = sizeof(_Bool);
		break;
	case 'v':
		size = 0;
		break;
	case '*':
		size = sizeof(char *);
		break;
	case '@':
		size = sizeof(id);
		break;
	case '#':
		size = sizeof(Class);
		break;
	case ':':
		size = sizeof(SEL);
		break;
	case '[':
		return sizeOfArray(type, length);
	case '{':
		return sizeOfStruct(type, length);
	case '(':
		return sizeOfUnion(type, length);
	case '^':
		/* Just to skip over the rest */
		(*type)++;
		(*length)--;
		sizeOfEncoding(type, length);

		return sizeof(void *);
#ifndef __STDC_NO_COMPLEX__
	case 'j':
		(*type)++;
		(*length)--;

		if (*length == 0)
			@throw [OFInvalidFormatException exception];

		switch (**type) {
		case 'f':
			size = sizeof(float _Complex);
			break;
		case 'd':
			size = sizeof(double _Complex);
			break;
		case 'D':
			size = sizeof(long double _Complex);
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		break;
#endif
	default:
		@throw [OFInvalidFormatException exception];
	}

	(*type)++;
	(*length)--;

	return size;
}

size_t
OFSizeOfTypeEncoding(const char *type)
{
	size_t length = strlen(type);
	size_t ret = sizeOfEncoding(&type, &length);

	if (length > 0)
		@throw [OFInvalidFormatException exception];

	return ret;
}

size_t
OFAlignmentOfTypeEncoding(const char *type)
{
	size_t length = strlen(type);
	size_t ret = alignmentOfEncoding(&type, &length, false);

	if (length > 0)
		@throw [OFInvalidFormatException exception];

	return ret;
}

@implementation OFMethodSignature
+ (instancetype)signatureWithObjCTypes: (const char*)types
{
	return [[[self alloc] initWithObjCTypes: types] autorelease];
}

- (instancetype)initWithObjCTypes: (const char *)types
{
	self = [super init];

	@try {
		size_t length;
		const char *last;

		if (types == NULL)
			@throw [OFInvalidArgumentException exception];

		length = strlen(types);

		if (length == 0)
			@throw [OFInvalidFormatException exception];

		_types = OFAllocMemory(length + 1, 1);
		memcpy(_types, types, length);

		_typesPointers = [[OFMutableData alloc]
		    initWithItemSize: sizeof(char *)];
		_offsets = [[OFMutableData alloc]
		    initWithItemSize: sizeof(size_t)];

		last = _types;
		for (size_t i = 0; i < length; i++) {
			if (OFASCIIIsDigit(_types[i])) {
				size_t offset = _types[i] - '0';

				if (last == _types + i)
					@throw [OFInvalidFormatException
					    exception];

				_types[i] = '\0';
				[_typesPointers addItem: &last];

				i++;
				for (; i < length &&
				    OFASCIIIsDigit(_types[i]); i++)
					offset = offset * 10 + _types[i] - '0';

				[_offsets addItem: &offset];

				last = _types + i;
				i--;
			} else if (_types[i] == '{') {
				size_t depth = 0;

				for (; i < length; i++) {
					if (_types[i] == '{')
						depth++;
					else if (_types[i] == '}') {
						if (--depth == 0)
							break;
					}
				}

				if (depth != 0)
					@throw [OFInvalidFormatException
					    exception];
			} else if (_types[i] == '(') {
				size_t depth = 0;

				for (; i < length; i++) {
					if (_types[i] == '(')
						depth++;
					else if (_types[i] == ')') {
						if (--depth == 0)
							break;
					}
				}

				if (depth != 0)
					@throw [OFInvalidFormatException
					    exception];
			}
		}

		if (last < _types + length)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_types);
	[_typesPointers release];
	[_offsets release];

	[super dealloc];
}

- (size_t)numberOfArguments
{
	return _typesPointers.count - 1;
}

- (const char *)methodReturnType
{
	return *(const char **)_typesPointers.firstItem;
}

- (size_t)frameLength
{
	return *(size_t *)_offsets.firstItem;
}

- (const char *)argumentTypeAtIndex: (size_t)idx
{
	return *(const char **)[_typesPointers itemAtIndex: idx + 1];
}

- (size_t)argumentOffsetAtIndex: (size_t)idx
{
	return *(size_t *)[_offsets itemAtIndex: idx + 1];
}
@end
