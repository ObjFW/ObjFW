/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#import "OFString+JSONValue.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFNull.h"

#import "OFInvalidEncodingException.h"

#import "macros.h"

int _OFString_JSONValue_reference;

static id nextObject(const char *restrict *, const char*);

static void
skipWhitespaces(const char *restrict *pointer, const char *stop)
{
	while (*pointer < stop && (**pointer == ' ' || **pointer == '\t' ||
	    **pointer == '\r' || **pointer == '\n'))
		(*pointer)++;
}

static void
skipComment(const char *restrict *pointer, const char *stop)
{
	if (**pointer != '/')
		return;

	if (*pointer + 1 >= stop)
		return;

	(*pointer)++;

	if (**pointer == '*') {
		BOOL lastIsAsterisk = NO;

		(*pointer)++;

		while (*pointer < stop) {
			if (lastIsAsterisk && **pointer == '/') {
				(*pointer)++;
				return;
			}

			lastIsAsterisk = (**pointer == '*');

			(*pointer)++;
		}
	} else {
		(*pointer)++;

		while (*pointer < stop) {
			if (**pointer == '\r' || **pointer == '\n') {
				(*pointer)++;
				return;
			}

			(*pointer)++;
		}
	}
}

static void
skipWhitespacesAndComments(const char *restrict *pointer, const char *stop)
{
	const char *old = NULL;

	while (old != *pointer) {
		old = *pointer;

		skipWhitespaces(pointer, stop);
		skipComment(pointer, stop);
	}
}

static OF_INLINE uint16_t
parseUnicodeEscape(const char *pointer, const char *stop)
{
	uint16_t ret = 0;
	char i;

	if (pointer + 5 >= stop)
		return 0xFFFF;

	if (pointer[0] != '\\' || pointer[1] != 'u')
		return 0xFFFF;

	for (i = 0; i < 4; i++) {
		char c = pointer[i + 2];
		ret <<= 4;

		if (c >= '0' && c <= '9')
			ret |= c - '0';
		else if (c >= 'a' && c <= 'f')
			ret |= c + 10 - 'a';
		else if (c >= 'A' && c <= 'F')
			ret |= c + 10 - 'A';
		else
			return 0xFFFF;
	}

	return ret;
}

static OF_INLINE OFString*
parseString(const char *restrict *pointer, const char *stop)
{
	char *buffer;
	size_t i = 0;

	if (++(*pointer) + 1 >= stop)
		return nil;

	if ((buffer = malloc(stop - *pointer)) == NULL)
		return nil;

	while (*pointer < stop) {
		/* Parse escape codes */
		if (**pointer == '\\') {
			if (++(*pointer) >= stop) {
				free(buffer);
				return nil;
			}

			switch (**pointer) {
			case '"':
			case '\\':
			case '/':
				buffer[i++] = **pointer;
				(*pointer)++;
				break;
			case 'b':
				buffer[i++] = '\b';
				(*pointer)++;
				break;
			case 'f':
				buffer[i++] = '\f';
				(*pointer)++;
				break;
			case 'n':
				buffer[i++] = '\n';
				(*pointer)++;
				break;
			case 'r':
				buffer[i++] = '\r';
				(*pointer)++;
				break;
			case 't':
				buffer[i++] = '\t';
				(*pointer)++;
				break;
			/* Parse unicode escape sequence */
			case 'u':;
				uint16_t c1, c2;
				of_unichar_t c;
				size_t l;

				c1 = parseUnicodeEscape(*pointer - 1, stop);
				if (c1 == 0xFFFF) {
					free(buffer);
					return nil;
				}

				/* Low surrogate */
				if ((c1 & 0xFC00) == 0xDC00) {
					free(buffer);
					return nil;
				}

				/* Normal character */
				if ((c1 & 0xFC00) != 0xD800) {
					l = of_string_unicode_to_utf8(c1,
					    buffer + i);

					if (l == 0) {
						free(buffer);
						return nil;
					}

					i += l;
					*pointer += 5;

					break;
				}

				/*
				 * If we are still here, we only got one UTF-16
				 * surrogate and now need to get the other one
				 * in order to produce UTF-8 and not CESU-8.
				 */
				c2 = parseUnicodeEscape(*pointer + 5, stop);
				if (c2 == 0xFFFF) {
					free(buffer);
					return nil;
				}

				c = (((c1 & 0x3FF) << 10) |
				    (c2 & 0x3FF)) + 0x10000;

				l = of_string_unicode_to_utf8(c, buffer + i);

				if (l == 0) {
					free(buffer);
					return nil;
				}

				i += l;
				*pointer += 11;

				break;
			default:
				 free(buffer);
				 return nil;
			}
		/* End of string found */
		} else if (**pointer == '"') {
			OFString *ret;

			@try {
				ret = [OFString stringWithUTF8String: buffer
							      length: i];
			} @finally {
				free(buffer);
			}

			(*pointer)++;

			return ret;
		} else {
			buffer[i++] = **pointer;
			(*pointer)++;
		}
	}

	free(buffer);
	return nil;
}

static OF_INLINE OFMutableArray*
parseArray(const char *restrict *pointer, const char *stop)
{
	OFMutableArray *array = [OFMutableArray array];

	if (++(*pointer) >= stop)
		return nil;

	while (**pointer != ']') {
		id object;

		skipWhitespacesAndComments(pointer, stop);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ']')
			break;

		if ((object = nextObject(pointer, stop)) == nil)
			return nil;

		[array addObject: object];

		skipWhitespacesAndComments(pointer, stop);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop);

			if (*pointer >= stop)
				return nil;
		} else if (**pointer != ']')
			return nil;
	}

	(*pointer)++;

	return array;
}

static OF_INLINE OFMutableDictionary*
parseDictionary(const char *restrict *pointer, const char *stop)
{
	OFMutableDictionary *dictionary = [OFMutableDictionary dictionary];

	if (++(*pointer) >= stop)
		return nil;

	while (**pointer != '}') {
		id key, object;

		skipWhitespacesAndComments(pointer, stop);
		if (*pointer >= stop)
			return nil;

		if (**pointer == '}')
			break;

		if ((key = nextObject(pointer, stop)) == nil)
			return nil;

		skipWhitespacesAndComments(pointer, stop);
		if (*pointer + 1 >= stop || **pointer != ':')
			return nil;

		(*pointer)++;

		if ((object = nextObject(pointer, stop)) == nil)
			return nil;

		[dictionary setObject: object
			       forKey: key];

		skipWhitespacesAndComments(pointer, stop);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop);

			if (*pointer >= stop)
				return nil;
		} else if (**pointer != '}')
			return nil;
	}

	(*pointer)++;

	return dictionary;
}

static OF_INLINE OFNumber*
parseNumber(const char *restrict *pointer, const char *stop)
{
	BOOL hasDecimal = NO;
	size_t i;
	OFString *string;
	OFNumber *number;

	for (i = 1; *pointer + i < stop; i++) {
		if ((*pointer)[i] == '.')
			hasDecimal = YES;

		if ((*pointer)[i] == ' ' || (*pointer)[i] == '\t' ||
		    (*pointer)[i] == '\r' || (*pointer)[i] == '\n' ||
		    (*pointer)[i] == ',' || (*pointer)[i] == ']' ||
		    (*pointer)[i] == '}')
			break;
	}

	string = [[OFString alloc] initWithUTF8String: *pointer
					       length: i];
	*pointer += i;

	@try {
		if (hasDecimal)
			number = [OFNumber numberWithDouble:
			    [string doubleValue]];
		else
			number = [OFNumber numberWithIntMax:
			    [string decimalValue]];
	} @finally {
		[string release];
	}

	return number;
}

static id
nextObject(const char *restrict *pointer, const char *stop)
{
	skipWhitespacesAndComments(pointer, stop);

	if (*pointer >= stop)
		return nil;

	switch (**pointer) {
	case '"':
		return parseString(pointer, stop);
	case '[':
		return parseArray(pointer, stop);
	case '{':
		return parseDictionary(pointer, stop);
	case 't':
		if (*pointer + 3 >= stop)
			return nil;

		if (memcmp(*pointer, "true", 4))
			return nil;

		(*pointer) += 4;

		return [OFNumber numberWithBool: YES];
	case 'f':
		if (*pointer + 4 >= stop)
			return nil;

		if (memcmp(*pointer, "false", 5))
			return nil;

		(*pointer) += 5;

		return [OFNumber numberWithBool: NO];
	case 'n':
		if (*pointer + 3 >= stop)
			return nil;

		if (memcmp(*pointer, "null", 4))
			return nil;

		(*pointer) += 4;

		return [OFNull null];
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	case '-':
		return parseNumber(pointer, stop);
	default:
		return nil;
	}
}

@implementation OFString (JSONValue)
- (id)JSONValue
{
	const char *pointer = [self UTF8String];
	const char *stop = pointer + [self UTF8StringLength];
	id object;

	object = nextObject(&pointer, stop);
	skipWhitespacesAndComments(&pointer, stop);

	if (pointer < stop || object == nil)
		@throw [OFInvalidEncodingException exceptionWithClass: isa];

	return object;
}
@end
