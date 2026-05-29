/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <stdlib.h>
#include <string.h>

#include <math.h>

#import "OFString+JSONParsing.h"
#import "OFString+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFNull.h"

#import "OFInvalidJSONException.h"

#ifndef INFINITY
# define INFINITY __builtin_inf()
#endif

int _OFString_JSONParsing_reference;

static id nextObject(const char **pointer, const char *stop, size_t *line,
    size_t depthLimit, bool root);

static void
skipWhitespaces(const char **pointer, const char *stop, size_t *line)
{
	while (*pointer < stop && (**pointer == ' ' || **pointer == '\t' ||
	    **pointer == '\r' || **pointer == '\n')) {
		if (**pointer == '\n')
			(*line)++;

		(*pointer)++;
	}
}

static void
skipComment(const char **pointer, const char *stop, size_t *line)
{
	if OF_LIKELY (**pointer != '/')
		return;

	if OF_UNLIKELY (*pointer + 1 >= stop)
		return;

	(*pointer)++;

	if (**pointer == '*') {
		bool lastIsAsterisk = false;

		(*pointer)++;

		while (*pointer < stop) {
			if OF_UNLIKELY (lastIsAsterisk && **pointer == '/') {
				(*pointer)++;
				return;
			}

			lastIsAsterisk = (**pointer == '*');

			if OF_UNLIKELY (**pointer == '\r') {
				(*pointer)++;

				if OF_LIKELY (*pointer < stop &&
				    **pointer == '\n') {
					(*pointer)++;
					(*line)++;
				}

				continue;
			} else if OF_UNLIKELY (**pointer == '\n')
				(*line)++;

			(*pointer)++;
		}
	} else if (**pointer == '/') {
		(*pointer)++;

		while (*pointer < stop) {
			if (**pointer == '\n') {
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
skipWhitespacesAndComments(const char **pointer, const char *stop, size_t *line)
{
	const char *old = NULL;

	while (old != *pointer) {
		old = *pointer;

		skipWhitespaces(pointer, stop, line);
		skipComment(pointer, stop, line);
	}
}

static inline OFChar16
parseUnicodeEscape(const char *pointer, const char *stop)
{
	OFChar16 ret = 0;

	if OF_UNLIKELY (pointer + 5 >= stop)
		return 0xFFFF;

	if OF_UNLIKELY (pointer[0] != '\\' || pointer[1] != 'u')
		return 0xFFFF;

	for (uint8_t i = 0; i < 4; i++) {
		char c = pointer[i + 2];
		ret <<= 4;

		if OF_LIKELY (c >= '0' && c <= '9')
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

static inline OFChar16
parseHexEscape(const char *pointer, const char *stop)
{
	OFChar16 ret = 0;

	if OF_UNLIKELY (pointer + 3 >= stop)
		return 0xFFFF;

	if OF_UNLIKELY (pointer[0] != '\\' || pointer[1] != 'x')
		return 0xFFFF;

	for (uint8_t i = 0; i < 2; i++) {
		char c = pointer[i + 2];
		ret <<= 4;

		if OF_LIKELY (c >= '0' && c <= '9')
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

static inline OFString *
parseString(const char **pointer, const char *stop, size_t *line)
{
	char *buffer;
	size_t i = 0;
	char delimiter = **pointer;

	if OF_UNLIKELY (++(*pointer) >= stop)
		return nil;

	buffer = OFAllocMemory(stop - *pointer, 1);

	while (*pointer < stop) {
		/* Parse escape codes */
		if OF_UNLIKELY (**pointer == '\\') {
			if OF_UNLIKELY (++(*pointer) >= stop) {
				OFFreeMemory(buffer);
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
			case '0':
				buffer[i++] = '\0';
				(*pointer)++;
				break;
			/* Parse Unicode escape sequence */
			case 'u':;
				OFChar16 c1, c2;
				OFUnichar c;
				size_t l;

				c1 = parseUnicodeEscape(*pointer - 1, stop);
				if OF_UNLIKELY (c1 == 0xFFFF) {
					OFFreeMemory(buffer);
					return nil;
				}

				/* Low surrogate */
				if OF_UNLIKELY ((c1 & 0xFC00) == 0xDC00) {
					OFFreeMemory(buffer);
					return nil;
				}

				/* Normal character */
				if OF_UNLIKELY ((c1 & 0xFC00) != 0xD800) {
					l = _OFUTF8StringEncode(c1, buffer + i);
					if OF_UNLIKELY (l == 0) {
						OFFreeMemory(buffer);
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
				if OF_UNLIKELY (c2 == 0xFFFF) {
					OFFreeMemory(buffer);
					return nil;
				}

				c = (((c1 & 0x3FF) << 10) |
				    (c2 & 0x3FF)) + 0x10000;

				l = _OFUTF8StringEncode(c, buffer + i);
				if OF_UNLIKELY (l == 0) {
					OFFreeMemory(buffer);
					return nil;
				}

				i += l;
				*pointer += 11;

				break;
			case 'x':
				c1 = parseHexEscape(*pointer - 1, stop);
				if OF_UNLIKELY (c1 == 0xFFFF) {
					OFFreeMemory(buffer);
					return nil;
				}

				l = _OFUTF8StringEncode(c1, buffer + i);
				if OF_UNLIKELY (l == 0) {
					OFFreeMemory(buffer);
					return nil;
				}

				i += l;
				*pointer += 3;

				break;
			case '\r':
				if OF_LIKELY (*pointer < stop &&
				    **pointer == '\n') {
					(*pointer)++;
					(*line)++;
				}

				(*pointer)++;
				break;
			case '\n':
				(*pointer)++;
				(*line)++;
				break;
			default:
				OFFreeMemory(buffer);
				return nil;
			}
		/* End of string found */
		} else if (**pointer == delimiter) {
			OFString *ret;

			@try {
				ret = [OFString stringWithUTF8String: buffer
							      length: i];
			} @finally {
				OFFreeMemory(buffer);
			}

			(*pointer)++;

			return ret;
		/* Newlines in strings are disallowed */
		} else if OF_UNLIKELY (**pointer == '\n' || **pointer == '\r') {
			if OF_LIKELY (**pointer == '\n')
				(*line)++;
			OFFreeMemory(buffer);
			return nil;
		} else {
			buffer[i++] = **pointer;
			(*pointer)++;
		}
	}

	OFFreeMemory(buffer);
	return nil;
}

static inline OFString *
parseIdentifier(const char **pointer, const char *stop)
{
	char *buffer;
	size_t i = 0;

	buffer = OFAllocMemory(stop - *pointer, 1);

	while (*pointer < stop) {
		if OF_LIKELY ((**pointer >= 'a' && **pointer <= 'z') ||
		    (**pointer >= 'A' && **pointer <= 'Z') ||
		    (**pointer >= '0' && **pointer <= '9') ||
		    **pointer == '_' || **pointer == '$' ||
		    (**pointer & 0x80)) {
			buffer[i++] = **pointer;
			(*pointer)++;
		} else if (**pointer == '\\') {
			OFChar16 c1, c2;
			OFUnichar c;
			size_t l;

			if OF_UNLIKELY (++(*pointer) >= stop ||
			    **pointer != 'u') {
				OFFreeMemory(buffer);
				return nil;
			}

			c1 = parseUnicodeEscape(*pointer - 1, stop);
			if OF_UNLIKELY (c1 == 0xFFFF) {
				OFFreeMemory(buffer);
				return nil;
			}

			/* Low surrogate */
			if OF_UNLIKELY ((c1 & 0xFC00) == 0xDC00) {
				OFFreeMemory(buffer);
				return nil;
			}

			/* Normal character */
			if OF_LIKELY ((c1 & 0xFC00) != 0xD800) {
				l = _OFUTF8StringEncode(c1, buffer + i);
				if OF_UNLIKELY (l == 0) {
					OFFreeMemory(buffer);
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
			if OF_UNLIKELY (c2 == 0xFFFF) {
				OFFreeMemory(buffer);
				return nil;
			}

			c = (((c1 & 0x3FF) << 10) | (c2 & 0x3FF)) + 0x10000;

			l = _OFUTF8StringEncode(c, buffer + i);
			if OF_UNLIKELY (l == 0) {
				OFFreeMemory(buffer);
				return nil;
			}

			i += l;
			*pointer += 11;
		} else {
			OFString *ret;

			if OF_UNLIKELY (i == 0) {
				OFFreeMemory(buffer);
				return nil;
			}

			@try {
				ret = [OFString stringWithUTF8String: buffer
							      length: i];
			} @finally {
				OFFreeMemory(buffer);
			}

			return ret;
		}
	}

	/*
	 * It is never possible to end with an identifier, thus we should never
	 * reach stop.
	 */
	OFFreeMemory(buffer);
	return nil;
}

static inline OFMutableArray *
parseArray(const char **pointer, const char *stop, size_t *line,
    size_t depthLimit)
{
	OFMutableArray *array = [OFMutableArray array];

	if OF_UNLIKELY (++(*pointer) >= stop)
		return nil;

	if OF_UNLIKELY (--depthLimit == 0)
		return nil;

	while (**pointer != ']') {
		id object;

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer >= stop)
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

		object = nextObject(pointer, stop, line, depthLimit, false);
		if OF_UNLIKELY (object == nil)
			return nil;

		[array addObject: object];

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if OF_UNLIKELY (*pointer >= stop)
				return nil;
		} else if OF_UNLIKELY (**pointer != ']')
			return nil;
	}

	(*pointer)++;

	return array;
}

static inline OFMutableDictionary *
parseDictionary(const char **pointer, const char *stop, size_t *line,
    size_t depthLimit)
{
	OFMutableDictionary *dictionary = [OFMutableDictionary dictionary];

	if OF_UNLIKELY (++(*pointer) >= stop)
		return nil;

	if OF_UNLIKELY (--depthLimit == 0)
		return nil;

	while (**pointer != '}') {
		OFString *key;
		id object;

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer >= stop)
			return nil;

		if (**pointer == '}')
			break;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if OF_UNLIKELY (*pointer >= stop || **pointer != '}')
				return nil;

			break;
		}

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer + 1 >= stop)
			return nil;

		if OF_UNLIKELY ((**pointer >= 'a' && **pointer <= 'z') ||
		    (**pointer >= 'A' && **pointer <= 'Z') ||
		    **pointer == '_' || **pointer == '$' || **pointer == '\\')
			key = parseIdentifier(pointer, stop);
		else
			key = nextObject(pointer, stop, line, depthLimit,
			    false);

		if OF_UNLIKELY (![key isKindOfClass: [OFString class]])
			return nil;

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer + 1 >= stop || **pointer != ':')
			return nil;

		(*pointer)++;

		object = nextObject(pointer, stop, line, depthLimit, false);
		if OF_UNLIKELY (object == nil)
			return nil;

		[dictionary setObject: object forKey: key];

		skipWhitespacesAndComments(pointer, stop, line);
		if OF_UNLIKELY (*pointer >= stop)
			return nil;

		if (**pointer == ',') {
			(*pointer)++;
			skipWhitespacesAndComments(pointer, stop, line);

			if OF_UNLIKELY (*pointer >= stop)
				return nil;
		} else if OF_UNLIKELY (**pointer != '}')
			return nil;
	}

	(*pointer)++;

	return dictionary;
}

static inline OFNumber *
parseNumber(const char **pointer, const char *stop, size_t *line)
{
	bool isNegative = (*pointer < stop && (*pointer)[0] == '-');
	bool hasDecimal = false;
	size_t i;
	OFString *string;
	OFNumber *number;

	for (i = 0; *pointer + i < stop; i++) {
		if OF_UNLIKELY ((*pointer)[i] == '.')
			hasDecimal = true;

		if OF_LIKELY ((*pointer)[i] == ' ' || (*pointer)[i] == '\t' ||
		    (*pointer)[i] == '\r' || (*pointer)[i] == '\n' ||
		    (*pointer)[i] == ',' || (*pointer)[i] == ']' ||
		    (*pointer)[i] == '}') {
			if OF_UNLIKELY ((*pointer)[i] == '\n')
				(*line)++;

			break;
		}
	}

	string = [[OFString alloc] initWithUTF8String: *pointer length: i];
	*pointer += i;

	@try {
		if (hasDecimal)
			number = [OFNumber numberWithDouble:
			    string.doubleValue];
		else if ([string isEqual: @"Infinity"])
			number = [OFNumber numberWithDouble: INFINITY];
		else if ([string isEqual: @"-Infinity"])
			number = [OFNumber numberWithDouble: -INFINITY];
		else if (isNegative)
			number = [OFNumber numberWithLongLong:
			    [string longLongValueWithBase: 0]];
		else
			number = [OFNumber numberWithUnsignedLongLong:
			    [string unsignedLongLongValueWithBase: 0]];
	} @finally {
		objc_release(string);
	}

	return number;
}

static id
nextObject(const char **pointer, const char *stop, size_t *line,
    size_t depthLimit, bool root)
{
	skipWhitespacesAndComments(pointer, stop, line);

	if OF_UNLIKELY (*pointer >= stop)
		return nil;

	switch (**pointer) {
	case '"':
	case '\'':
		if OF_UNLIKELY (root)
			return nil;

		return parseString(pointer, stop, line);
	case '[':
		return parseArray(pointer, stop, line, depthLimit);
	case '{':
		return parseDictionary(pointer, stop, line, depthLimit);
	case 't':
		if OF_UNLIKELY (root)
			return nil;

		if OF_UNLIKELY (*pointer + 3 >= stop)
			return nil;

		if OF_UNLIKELY (memcmp(*pointer, "true", 4) != 0)
			return nil;

		(*pointer) += 4;

		return [OFNumber numberWithBool: true];
	case 'f':
		if OF_UNLIKELY (root)
			return nil;

		if OF_UNLIKELY (*pointer + 4 >= stop)
			return nil;

		if OF_UNLIKELY (memcmp(*pointer, "false", 5) != 0)
			return nil;

		(*pointer) += 5;

		return [OFNumber numberWithBool: false];
	case 'n':
		if OF_UNLIKELY (root)
			return nil;

		if OF_UNLIKELY (*pointer + 3 >= stop)
			return nil;

		if OF_UNLIKELY (memcmp(*pointer, "null", 4) != 0)
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
		if OF_UNLIKELY (root)
			return nil;

		return parseNumber(pointer, stop, line);
	default:
		return nil;
	}
}

@implementation OFString (JSONParsing)
- (id)objectByParsingJSON
{
	return [self objectByParsingJSONWithDepthLimit: 32];
}

- (id)objectByParsingJSONWithDepthLimit: (size_t)depthLimit
{
	void *pool = objc_autoreleasePoolPush();
	const char *pointer = self.UTF8String;
	const char *stop = pointer + self.UTF8StringLength;
	id object;
	size_t line = 1;

	object = nextObject(&pointer, stop, &line, depthLimit, true);
	skipWhitespacesAndComments(&pointer, stop, &line);

	if OF_UNLIKELY (pointer < stop || object == nil)
		@throw [OFInvalidJSONException exceptionWithString: self
							      line: line];

	objc_retain(object);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(object);
}
@end
