/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <assert.h>
#include <ctype.h>

#import "OFMethodSignature.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static size_t alignofEncoding(const char **type, size_t *length, bool inStruct);
static size_t sizeofEncoding(const char **type, size_t *length);

static size_t
alignofArray(const char **type, size_t *length)
{
	size_t align;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	while (*length > 0 && of_ascii_isdigit(**type)) {
		(*type)++;
		(*length)--;
	}

	align = alignofEncoding(type, length, true);

	if (*length == 0 || **type != ']')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return align;
}

static size_t
alignofStruct(const char **type, size_t *length)
{
	size_t align = 0;
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
		size_t fieldAlign = alignofEncoding(type, length, true);

#if defined(OF_POWERPC) && defined(OF_MACOS)
		if (!first && fieldAlign > 4)
			fieldAlign = 4;

		first = false;
#endif

		if (fieldAlign > align)
			align = fieldAlign;
	}

	if (*length == 0 || **type != '}')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return align;
}

static size_t
alignofUnion(const char **type, size_t *length)
{
	size_t align = 0;

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
		size_t fieldAlign = alignofEncoding(type, length, true);

		if (fieldAlign > align)
			align = fieldAlign;
	}

	if (*length == 0 || **type != ')')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	return align;
}

static size_t
alignofEncoding(const char **type, size_t *length, bool inStruct)
{
	size_t align;

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
		align = OF_ALIGNOF(char);
		break;
	case 'i':
	case 'I':
		align = OF_ALIGNOF(int);
		break;
	case 's':
	case 'S':
		align = OF_ALIGNOF(short);
		break;
	case 'l':
	case 'L':
		align = OF_ALIGNOF(long);
		break;
	case 'q':
	case 'Q':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			align = 4;
		else
#endif
			align = OF_ALIGNOF(long long);
		break;
#ifdef __SIZEOF_INT128__
	case 't':
	case 'T':
		align = __extension__ OF_ALIGNOF(__int128);
		break;
#endif
	case 'f':
		align = OF_ALIGNOF(float);
		break;
	case 'd':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			align = 4;
		else
#endif
			align = OF_ALIGNOF(double);
		break;
	case 'D':
#if defined(OF_X86) && !defined(OF_WINDOWS)
		if (inStruct)
			align = 4;
		else
#endif
			align = OF_ALIGNOF(long double);
		break;
	case 'B':
		align = OF_ALIGNOF(_Bool);
		break;
	case 'v':
		align = 0;
		break;
	case '*':
		align = OF_ALIGNOF(char *);
		break;
	case '@':
		align = OF_ALIGNOF(id);
		break;
	case '#':
		align = OF_ALIGNOF(Class);
		break;
	case ':':
		align = OF_ALIGNOF(SEL);
		break;
	case '[':
		return alignofArray(type, length);
	case '{':
		return alignofStruct(type, length);
	case '(':
		return alignofUnion(type, length);
	case '^':
		/* Just to skip over the rest */
		(*type)++;
		(*length)--;
		alignofEncoding(type, length, false);

		return OF_ALIGNOF(void *);
#ifndef __STDC_NO_COMPLEX__
	case 'j':
		(*type)++;
		(*length)--;

		if (*length == 0)
			@throw [OFInvalidFormatException exception];

		switch (**type) {
		case 'f':
			align = OF_ALIGNOF(float _Complex);
			break;
		case 'd':
# if defined(OF_X86) && !defined(OF_WINDOWS)
			if (inStruct)
				align = 4;
			else
# endif
				align = OF_ALIGNOF(double _Complex);
			break;
		case 'D':
			align = OF_ALIGNOF(long double _Complex);
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

	return align;
}

static size_t
sizeofArray(const char **type, size_t *length)
{
	size_t count = 0;
	size_t size;

	assert(*length > 0);

	(*type)++;
	(*length)--;

	while (*length > 0 && of_ascii_isdigit(**type)) {
		count = count * 10 + **type - '0';

		(*type)++;
		(*length)--;
	}

	if (count == 0)
		@throw [OFInvalidFormatException exception];

	size = sizeofEncoding(type, length);

	if (*length == 0 || **type != ']')
		@throw [OFInvalidFormatException exception];

	(*type)++;
	(*length)--;

	if (SIZE_MAX / count < size)
		@throw [OFOutOfRangeException exception];

	return count * size;
}

static size_t
sizeofStruct(const char **type, size_t *length)
{
	size_t size = 0;
	const char *typeCopy = *type;
	size_t lengthCopy = *length;
	size_t alignment = alignofStruct(&typeCopy, &lengthCopy);
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
		size_t fieldSize, fieldAlign;

		typeCopy = *type;
		lengthCopy = *length;
		fieldSize = sizeofEncoding(type, length);
		fieldAlign = alignofEncoding(&typeCopy, &lengthCopy, true);

#if defined(OF_POWERPC) && defined(OF_MACOS)
		if (!first && fieldAlign > 4)
			fieldAlign = 4;

		first = false;
#endif

		if (size % fieldAlign != 0) {
			size_t padding = fieldAlign - (size % fieldAlign);

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
sizeofUnion(const char **type, size_t *length)
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
		size_t fieldSize = sizeofEncoding(type, length);

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
sizeofEncoding(const char **type, size_t *length)
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
		return sizeofArray(type, length);
	case '{':
		return sizeofStruct(type, length);
	case '(':
		return sizeofUnion(type, length);
	case '^':
		/* Just to skip over the rest */
		(*type)++;
		(*length)--;
		sizeofEncoding(type, length);

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
of_sizeof_type_encoding(const char *type)
{
	size_t length = strlen(type);
	size_t ret = sizeofEncoding(&type, &length);

	if (length > 0)
		@throw [OFInvalidFormatException exception];

	return ret;
}

size_t
of_alignof_type_encoding(const char *type)
{
	size_t length = strlen(type);
	size_t ret = alignofEncoding(&type, &length, false);

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

		_types = [self allocMemoryWithSize: length + 1];
		memcpy(_types, types, length);

		_typesPointers = [[OFMutableData alloc]
		    initWithItemSize: sizeof(char *)];
		_offsets = [[OFMutableData alloc]
		    initWithItemSize: sizeof(size_t)];

		last = _types;
		for (size_t i = 0; i < length; i++) {
			if (of_ascii_isdigit(_types[i])) {
				size_t offset = _types[i] - '0';

				if (last == _types + i)
					@throw [OFInvalidFormatException
					    exception];

				_types[i] = '\0';
				[_typesPointers addItem: &last];

				i++;
				for (; i < length &&
				    of_ascii_isdigit(_types[i]); i++)
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
	[_typesPointers release];
	[_offsets release];

	[super dealloc];
}

- (size_t)numberOfArguments
{
	return [_typesPointers count] - 1;
}

- (const char *)methodReturnType
{
	return *(const char **)[_typesPointers firstItem];
}

- (size_t)frameLength
{
	return *(size_t *)[_offsets firstItem];
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
