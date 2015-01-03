/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include <math.h>

#include <assert.h>

#import "OFString+JSONValue.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFNull.h"

#import "OFInvalidJSONException.h"

int _OFString_JSONValue_reference;

static id nextObject(const char *restrict *, const char*,
    size_t *restrict line, size_t depth, size_t depthLimit);

static void
skipWhitespaces(const char *restrict *pointer, const char *stop,
    size_t *restrict line)
{
	while (*pointer < stop && (**pointer == ' ' || **pointer == '\t' ||
	    **pointer == '\r' || **pointer == '\n')) {
		if (**pointer == '\n')
			(*line)++;

		(*pointer)++;
	}
}

static void
skipComment(const char *restrict *pointer, const char *stop,
    size_t *restrict line)
{
	if (**pointer != '/')
		return;

	if (*pointer + 1 >= stop)
		return;

	(*pointer)++;

	if (**pointer == '*') {
		bool lastIsAsterisk = false;

		(*pointer)++;

		while (*pointer < stop) {
			if (lastIsAsterisk && **pointer == '/') {
				(*pointer)++;
				return;
			}

			lastIsAsterisk = (**pointer == '*');

			if (**pointer == '\n')
				(*line)++;

			(*pointer)++;
		}
	} else if (**pointer == '/') {
		(*pointer)++;

		while (*pointer < stop) {
			if (**pointer == '\r' || **pointer == '\n') {
				(*pointer)++;
				(*line)++;
				return;
			}

			(*pointer)++;
		}
	} else
		(*pointer)--;
}

static void
skipWhitespacesAndComments(const char *restrict *pointer, const char *stop,
    size_t *restrict line)
{
	const char *old = NULL;

	while (old != *pointer) {
		old = *pointer;

		skipWhitespaces(pointer, stop, line);
		skipComment(pointer, stop, line);
	}
}

static inline of_char16_t
parseUnicodeEscape(const char *pointer, const char *stop)
{
	of_char16_t ret = 0;
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

	if (ret == 0)
		return 0xFFFF;

	return ret;
}

static inline OFString*
parseString(const char *restrict *pointer, const char *stop,
    size_t *restrict line)
{
	char *buffer;
	size_t i = 0;
	char delimiter = **pointer;

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
				of_char16_t c1, c2;
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
					l = of_string_utf8_encode(c1,
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

				l = of_string_utf8_encode(c, buffer + i);
				if (l == 0) {
					free(buffer);
					return nil;
				}

				i += l;
				*pointer += 11;

				break;
			case '\r':
				(*pointer)++;

				if (*pointer < stop && **pointer == '\n') {
					(*pointer)++;
					(*line)++;
				}

				break;
			case '\n':
				(*pointer)++;
				(*line)++;
				break;
			default:
				free(buffer);
				return nil;
			}
		/* End of string found */
		} else if (**pointer == delimiter) {
			OFString *ret;

			@try {
				ret = [OFString stringWithUTF8String: buffer
							      length: i];
			} @finally {
				free(buffer);
			}

			(*pointer)++;

			return ret;
		/* Newlines in strings are disallowed */
		} else if (**pointer == '\n' || **pointer == '\r') {
			(*line)++;
			free(buffer);
			return nil;
		} else {
			buffer[i++] = **pointer;
			(*pointer)++;
		}
	}

	free(buffer);
	return nil;
}

static inline OFString*
parseIdentifier(const char *restrict *pointer, const char *stop)
{
	char *buffer;
	size_t i = 0;

	if ((buffer = malloc(stop - *pointer)) == NULL)
		return nil;

	while (*pointer < stop) {
		if ((**pointer >= 'a' && **pointer <= 'z') ||
		    (**pointer >= 'A' && **pointer <= 'Z') ||
		    (**pointer >= '0' && **pointer <= '9') ||
		    **pointer == '_' || **pointer == '$' ||
		    (**pointer & 0x80)) {
			buffer[i++] = **pointer;
			(*pointer)++;
		} else if (**pointer == '\\') {
			of_char16_t c1, c2;
			of_unichar_t c;
			size_t l;

			if (++(*pointer) >= stop || **pointer != 'u') {
				free(buffer);
				return nil;
			}

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
				l = of_string_utf8_encode(c1, buffer + i);
				if (l == 0) {
					free(buffer);
					return nil;
				}

				i += l;
				*pointer += 5;

				continue;
			}

			/*
			 * If we are still here, we only got one UTF-16
			 * surrogate and now need to get the other one in order
			 * to produce UTF-8 and not CESU-8.
			 */
			c2 = parseUnicodeEscape(*pointer + 5, stop);
			if (c2 == 0xFFFF) {
				free(buffer);
				return nil;
			}

			c = (((c1 & 0x3FF) << 10) | (c2 & 0x3FF)) + 0x10000;

			l = of_string_utf8_encode(c, buffer + i);
			if (l == 0) {
				free(buffer);
				return nil;
			}

			i += l;
			*pointer += 11;
		} else {
			OFString *ret;

			if (i == 0 || (buffer[0] >= '0' && buffer[0] <= '9')) {
				free(buffer);
				return nil;
			}

			@try {
				ret = [OFString stringWithUTF8String: buffer
							      length: i];
			} @finally {
				free(buffer);
			}

			return ret;
		}
	}

	/*
	 * It is never possible to end with an identifier, thus we should never
	 * reach stop.
	 */
	return nil;
}

static inline OFMutableArray*
parseArray(const char *restrict *pointer, const char *stop,
    size_t *restrict line, size_t depth, size_t depthLimit)
{
	OFMutableArray *array = [OFMutableArray array];

	if (++(*pointer) >= stop)
		return nil;

	if (++depth > depthLimit)
		return nil;

	while (**pointer != ']') {
		id object;

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ']')
			break;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if (*pointer >= stop || **pointer != ']')
				return nil;

			break;
		}

		object = nextObject(pointer, stop, line, depth, depthLimit);
		if (object == nil)
			return nil;

		[array addObject: object];

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if (*pointer >= stop)
				return nil;
		} else if (**pointer != ']')
			return nil;
	}

	(*pointer)++;

	return array;
}

static inline OFMutableDictionary*
parseDictionary(const char *restrict *pointer, const char *stop,
    size_t *restrict line, size_t depth, size_t depthLimit)
{
	OFMutableDictionary *dictionary = [OFMutableDictionary dictionary];

	if (++(*pointer) >= stop)
		return nil;

	if (++depth > depthLimit)
		return nil;

	while (**pointer != '}') {
		id key, object;

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer >= stop)
			return nil;

		if (**pointer == '}')
			break;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if (*pointer >= stop || **pointer != '}')
				return nil;

			break;
		}

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer + 1 >= stop)
			return nil;

		if ((**pointer >= 'a' && **pointer <= 'z') ||
		    (**pointer >= 'A' && **pointer <= 'Z') ||
		    **pointer == '_' || **pointer == '$' || **pointer == '\\')
			key = parseIdentifier(pointer, stop);
		else
			key = nextObject(pointer, stop, line,
			    depth, depthLimit);

		if (key == nil)
			return nil;

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer + 1 >= stop || **pointer != ':')
			return nil;

		(*pointer)++;

		object = nextObject(pointer, stop, line, depth, depthLimit);
		if (object == nil)
			return nil;

		[dictionary setObject: object
			       forKey: key];

		skipWhitespacesAndComments(pointer, stop, line);
		if (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if (*pointer >= stop)
				return nil;
		} else if (**pointer != '}')
			return nil;
	}

	(*pointer)++;

	return dictionary;
}

static inline OFNumber*
parseNumber(const char *restrict *pointer, const char *stop,
    size_t *restrict line)
{
	bool isHex = (*pointer + 1 < stop && (*pointer)[1] == 'x');
	bool hasDecimal = false;
	size_t i;
	OFString *string;
	OFNumber *number;

	for (i = 0; *pointer + i < stop; i++) {
		if ((*pointer)[i] == '.')
			hasDecimal = true;

		if ((*pointer)[i] == ' ' || (*pointer)[i] == '\t' ||
		    (*pointer)[i] == '\r' || (*pointer)[i] == '\n' ||
		    (*pointer)[i] == ',' || (*pointer)[i] == ']' ||
		    (*pointer)[i] == '}') {
			if ((*pointer)[i] == '\n')
				(*line)++;

			break;
		}
	}

	string = [[OFString alloc] initWithUTF8String: *pointer
					       length: i];
	*pointer += i;

	@try {
		if (hasDecimal)
			number = [OFNumber numberWithDouble:
			    [string doubleValue]];
		else if (isHex)
			number = [OFNumber numberWithIntMax:
			    [string hexadecimalValue]];
		else if ([string isEqual: @"Infinity"])
			number = [OFNumber numberWithDouble: INFINITY];
		else if ([string isEqual: @"-Infinity"])
			number = [OFNumber numberWithDouble: -INFINITY];
		else
			number = [OFNumber numberWithIntMax:
			    [string decimalValue]];
	} @finally {
		[string release];
	}

	return number;
}

static id
nextObject(const char *restrict *pointer, const char *stop,
    size_t *restrict line, size_t depth, size_t depthLimit)
{
	skipWhitespacesAndComments(pointer, stop, line);

	if (*pointer >= stop)
		return nil;

	switch (**pointer) {
	case '"':
	case '\'':
		return parseString(pointer, stop, line);
	case '[':
		return parseArray(pointer, stop, line, depth, depthLimit);
	case '{':
		return parseDictionary(pointer, stop, line, depth, depthLimit);
	case 't':
		if (*pointer + 3 >= stop)
			return nil;

		if (memcmp(*pointer, "true", 4) != 0)
			return nil;

		(*pointer) += 4;

		return [OFNumber numberWithBool: true];
	case 'f':
		if (*pointer + 4 >= stop)
			return nil;

		if (memcmp(*pointer, "false", 5) != 0)
			return nil;

		(*pointer) += 5;

		return [OFNumber numberWithBool: false];
	case 'n':
		if (*pointer + 3 >= stop)
			return nil;

		if (memcmp(*pointer, "null", 4) != 0)
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
	case '+':
	case '-':
	case '.':
	case 'I':
		return parseNumber(pointer, stop, line);
	default:
		return nil;
	}
}

@implementation OFString (JSONValue)
- (id)JSONValue
{
	return [self JSONValueWithDepthLimit: 32];
}

- (id)JSONValueWithDepthLimit: (size_t)depthLimit
{
	void *pool = objc_autoreleasePoolPush();
	const char *pointer = [self UTF8String];
	const char *stop = pointer + [self UTF8StringLength];
	id object;
	size_t line = 1;

	object = nextObject(&pointer, stop, &line, 0, depthLimit);
	skipWhitespacesAndComments(&pointer, stop, &line);

	if (pointer < stop || object == nil)
		@throw [OFInvalidJSONException exceptionWithString: self
							      line: line];

	[object retain];

	objc_autoreleasePoolPop(pool);

	return [object autorelease];
}
@end
