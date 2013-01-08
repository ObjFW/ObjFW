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

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <sys/types.h>

#import "OFString_UTF8.h"
#import "OFMutableString_UTF8.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"
#import "of_asprintf.h"
#import "unicode.h"

extern const uint16_t of_iso_8859_15[256];
extern const uint16_t of_windows_1252[256];

static inline int
memcasecmp(const char *first, const char *second, size_t length)
{
	size_t i;

	for (i = 0; i < length; i++) {
		if (tolower((int)first[i]) > tolower((int)second[i]))
			return OF_ORDERED_DESCENDING;
		if (tolower((int)first[i]) < tolower((int)second[i]))
			return OF_ORDERED_ASCENDING;
	}

	return OF_ORDERED_SAME;
}

int
of_string_utf8_check(const char *UTF8String, size_t UTF8Length, size_t *length)
{
	size_t i, tmpLength = UTF8Length;
	int isUTF8 = 0;

	for (i = 0; i < UTF8Length; i++) {
		/* No sign of UTF-8 here */
		if OF_LIKELY (!(UTF8String[i] & 0x80))
			continue;

		isUTF8 = 1;

		/* We're missing a start byte here */
		if OF_UNLIKELY (!(UTF8String[i] & 0x40))
			return -1;

		/* 2 byte sequences for code points 0 - 127 are forbidden */
		if OF_UNLIKELY ((UTF8String[i] & 0x7E) == 0x40)
			return -1;

		/* We have at minimum a 2 byte character -> check next byte */
		if OF_UNLIKELY (UTF8Length <= i + 1 ||
		    (UTF8String[i + 1] & 0xC0) != 0x80)
			return -1;

		/* Check if we have at minimum a 3 byte character */
		if OF_LIKELY (!(UTF8String[i] & 0x20)) {
			i++;
			tmpLength--;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if OF_UNLIKELY (UTF8Length <= i + 2 ||
		    (UTF8String[i + 2] & 0xC0) != 0x80)
			return -1;

		/* Check if we have a 4 byte character */
		if OF_LIKELY (!(UTF8String[i] & 0x10)) {
			i += 2;
			tmpLength -= 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if OF_UNLIKELY (UTF8Length <= i + 3 ||
		    (UTF8String[i + 3] & 0xC0) != 0x80)
			return -1;

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if OF_UNLIKELY (UTF8String[i] & 0x08)
			return -1;

		i += 3;
		tmpLength -= 3;
	}

	if (length != NULL)
		*length = tmpLength;

	return isUTF8;
}

size_t
of_string_utf8_get_index(const char *string, size_t position)
{
	size_t i, index = position;

	for (i = 0; i < position; i++)
		if OF_UNLIKELY ((string[i] & 0xC0) == 0x80)
			index--;

	return index;
}

size_t
of_string_utf8_get_position(const char *string, size_t index, size_t length)
{
	size_t i;

	for (i = 0; i <= index; i++)
		if OF_UNLIKELY ((string[i] & 0xC0) == 0x80)
			if (++index > length)
				return OF_NOT_FOUND;

	return index;
}

@implementation OFString_UTF8
- init
{
	self = [super init];

	@try {
		s = &s_store;

		s->cString = [self allocMemoryWithSize: 1];
		s->cString[0] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- OF_initWithUTF8String: (const char*)UTF8String
		 length: (size_t)UTF8StringLength
		storage: (char*)storage
{
	self = [super init];

	@try {
		if (UTF8StringLength >= 3 &&
		    !memcmp(UTF8String, "\xEF\xBB\xBF", 3)) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		s = &s_store;

		s->cString = storage;
		s->cStringLength = UTF8StringLength;

		switch (of_string_utf8_check(UTF8String, UTF8StringLength,
		    &s->length)) {
		case 1:
			s->isUTF8 = YES;
			break;
		case -1:
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];
		}

		memcpy(s->cString, UTF8String, UTF8StringLength);
		s->cString[UTF8StringLength] = 0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)cStringLength
{
	self = [super init];

	@try {
		size_t i, j;
		const uint16_t *table;

		if (encoding == OF_STRING_ENCODING_UTF_8 &&
		    cStringLength >= 3 && !memcmp(cString, "\xEF\xBB\xBF", 3)) {
			cString += 3;
			cStringLength -= 3;
		}

		s = &s_store;

		s->cString = [self allocMemoryWithSize: cStringLength + 1];
		s->cStringLength = cStringLength;

		if (encoding == OF_STRING_ENCODING_UTF_8 ||
		    encoding == OF_STRING_ENCODING_ASCII) {
			switch (of_string_utf8_check(cString, cStringLength,
			    &s->length)) {
			case 1:
				if (encoding == OF_STRING_ENCODING_ASCII)
					@throw [OFInvalidEncodingException
					    exceptionWithClass: [self class]];

				s->isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];
			}

			memcpy(s->cString, cString, cStringLength);
			s->cString[cStringLength] = 0;

			return self;
		}

		/* All other encodings we support are single byte encodings */
		s->length = cStringLength;

		if (encoding == OF_STRING_ENCODING_ISO_8859_1) {
			for (i = j = 0; i < cStringLength; i++) {
				char buffer[4];
				size_t bytes;

				if (!(cString[i] & 0x80)) {
					s->cString[j++] = cString[i];
					continue;
				}

				s->isUTF8 = YES;
				bytes = of_string_utf8_encode(
				    (uint8_t)cString[i], buffer);

				if (bytes == 0)
					@throw [OFInvalidEncodingException
					    exceptionWithClass: [self class]];

				s->cStringLength += bytes - 1;
				s->cString = [self
				    resizeMemory: s->cString
					    size: s->cStringLength + 1];

				memcpy(s->cString + j, buffer, bytes);
				j += bytes;
			}

			s->cString[s->cStringLength] = 0;

			return self;
		}

		switch (encoding) {
		case OF_STRING_ENCODING_ISO_8859_15:
			table = of_iso_8859_15;
			break;
		case OF_STRING_ENCODING_WINDOWS_1252:
			table = of_windows_1252;
			break;
		default:
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];
		}

		for (i = j = 0; i < cStringLength; i++) {
			char buffer[4];
			of_unichar_t character;
			size_t characterBytes;

			if (!(cString[i] & 0x80)) {
				s->cString[j++] = cString[i];
				continue;
			}

			character = table[(uint8_t)cString[i]];

			if (character == 0xFFFD)
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];

			s->isUTF8 = YES;
			characterBytes = of_string_utf8_encode(character,
			    buffer);

			if (characterBytes == 0)
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];

			s->cStringLength += characterBytes - 1;
			s->cString = [self resizeMemory: s->cString
						   size: s->cStringLength + 1];

			memcpy(s->cString + j, buffer, characterBytes);
			j += characterBytes;
		}

		s->cString[s->cStringLength] = 0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithUTF8StringNoCopy: (char*)UTF8String
	      freeWhenDone: (BOOL)freeWhenDone
{
	self = [super init];

	@try {
		size_t UTF8StringLength = strlen(UTF8String);

		if (UTF8StringLength >= 3 &&
		    !memcmp(UTF8String, "\xEF\xBB\xBF", 3)) {
			UTF8String += 3;
			UTF8StringLength -= 3;
		}

		s = &s_store;

		s->cString = (char*)UTF8String;
		s->cStringLength = UTF8StringLength;

		if (freeWhenDone)
			s->freeWhenDone = UTF8String;

		switch (of_string_utf8_check(UTF8String, UTF8StringLength,
		    &s->length)) {
		case 1:
			s->isUTF8 = YES;
			break;
		case -1:
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		s = &s_store;

		s->cStringLength = [string UTF8StringLength];

		if ([string isKindOfClass: [OFString_UTF8 class]] ||
		    [string isKindOfClass: [OFMutableString_UTF8 class]])
			s->isUTF8 = ((OFString_UTF8*)string)->s->isUTF8;
		else
			s->isUTF8 = YES;

		s->length = [string length];

		s->cString = [self allocMemoryWithSize: s->cStringLength + 1];
		memcpy(s->cString, [string UTF8String], s->cStringLength + 1);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCharacters: (const of_unichar_t*)characters
	      length: (size_t)length
	   byteOrder: (of_byte_order_t)byteOrder
{
	self = [super init];

	@try {
		size_t i, j = 0;
		BOOL swap = NO;

		if (length > 0 && *characters == 0xFEFF) {
			characters++;
			length--;
		} else if (length > 0 && *characters == 0xFFFE0000) {
			swap = YES;
			characters++;
			length--;
		} else if (byteOrder != OF_BYTE_ORDER_NATIVE)
			swap = YES;

		s = &s_store;

		s->cStringLength = length;
		s->cString = [self allocMemoryWithSize: (length * 4) + 1];
		s->length = length;

		for (i = 0; i < length; i++) {
			char buffer[4];
			size_t characterLen = of_string_utf8_encode(
			    (swap ? OF_BSWAP32(characters[i]) : characters[i]),
			    buffer);

			switch (characterLen) {
			case 1:
				s->cString[j++] = buffer[0];
				break;
			case 2:
				s->isUTF8 = YES;
				s->cStringLength++;

				memcpy(s->cString + j, buffer, 2);
				j += 2;

				break;
			case 3:
				s->isUTF8 = YES;
				s->cStringLength += 2;

				memcpy(s->cString + j, buffer, 3);
				j += 3;

				break;
			case 4:
				s->isUTF8 = YES;
				s->cStringLength += 3;

				memcpy(s->cString + j, buffer, 4);
				j += 4;

				break;
			default:
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];
			}
		}

		s->cString[j] = '\0';

		@try {
			s->cString = [self resizeMemory: s->cString
						   size: s->cStringLength + 1];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithUTF16String: (const uint16_t*)string
	       length: (size_t)length
	    byteOrder: (of_byte_order_t)byteOrder
{
	self = [super init];

	@try {
		size_t i, j = 0;
		BOOL swap = NO;

		if (length > 0 && *string == 0xFEFF) {
			string++;
			length--;
		} else if (length > 0 && *string == 0xFFFE) {
			swap = YES;
			string++;
			length--;
		} else if (byteOrder != OF_BYTE_ORDER_NATIVE)
			swap = YES;

		s = &s_store;

		s->cStringLength = length;
		s->cString = [self allocMemoryWithSize: (length * 4) + 1];
		s->length = length;

		for (i = 0; i < length; i++) {
			char buffer[4];
			of_unichar_t character =
			    (swap ? OF_BSWAP16(string[i]) : string[i]);
			size_t characterLen;

			/* Missing high surrogate */
			if ((character & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];

			if ((character & 0xFC00) == 0xD800) {
				uint16_t nextCharacter;

				if (length <= i + 1)
					@throw [OFInvalidEncodingException
					    exceptionWithClass: [self class]];

				nextCharacter = (swap
				    ? OF_BSWAP16(string[i + 1])
				    : string[i + 1]);

				if ((nextCharacter & 0xFC00) != 0xDC00)
					@throw [OFInvalidEncodingException
					    exceptionWithClass: [self class]];

				character = (((character & 0x3FF) << 10) |
				    (nextCharacter & 0x3FF)) + 0x10000;

				i++;
				s->cStringLength--;
				s->length--;
			}

			characterLen = of_string_utf8_encode(character, buffer);

			switch (characterLen) {
			case 1:
				s->cString[j++] = buffer[0];
				break;
			case 2:
				s->isUTF8 = YES;
				s->cStringLength++;

				memcpy(s->cString + j, buffer, 2);
				j += 2;

				break;
			case 3:
				s->isUTF8 = YES;
				s->cStringLength += 2;

				memcpy(s->cString + j, buffer, 3);
				j += 3;

				break;
			case 4:
				s->isUTF8 = YES;
				s->cStringLength += 3;

				memcpy(s->cString + j, buffer, 4);
				j += 4;

				break;
			default:
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];
			}
		}

		s->cString[j] = '\0';

		@try {
			s->cString = [self resizeMemory: s->cString
						   size: s->cStringLength + 1];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFormat: (OFConstantString*)format
       arguments: (va_list)arguments
{
	self = [super init];

	@try {
		char *tmp;
		int cStringLength;

		if (format == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		s = &s_store;

		if ((cStringLength = of_vasprintf(&tmp, [format UTF8String],
		    arguments)) == -1)
			@throw [OFInvalidFormatException
			    exceptionWithClass: [self class]];

		s->cStringLength = cStringLength;

		@try {
			switch (of_string_utf8_check(tmp, cStringLength,
			    &s->length)) {
			case 1:
				s->isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];
			}

			s->cString = [self
			    allocMemoryWithSize: cStringLength + 1];
			memcpy(s->cString, tmp, cStringLength + 1);
		} @finally {
			free(tmp);
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		OFString *component;
		size_t i, cStringLength;
		va_list argumentsCopy;

		s = &s_store;

		s->cStringLength = [firstComponent UTF8StringLength];

		if ([firstComponent isKindOfClass: [OFString_UTF8 class]] ||
		    [firstComponent isKindOfClass:
		    [OFMutableString_UTF8 class]])
			s->isUTF8 = ((OFString_UTF8*)firstComponent)->s->isUTF8;
		else
			s->isUTF8 = YES;

		s->length = [firstComponent length];

		/* Calculate length and see if we need UTF-8 */
		va_copy(argumentsCopy, arguments);
		while ((component = va_arg(argumentsCopy, OFString*)) != nil) {
			s->cStringLength += 1 + [component UTF8StringLength];
			s->length += 1 + [component length];

			if ([component isKindOfClass: [OFString_UTF8 class]] ||
			    [component isKindOfClass:
			    [OFMutableString_UTF8 class]])
				s->isUTF8 =
				    ((OFString_UTF8*)component)->s->isUTF8;
			else
				s->isUTF8 = YES;
		}

		s->cString = [self allocMemoryWithSize: s->cStringLength + 1];

		cStringLength = [firstComponent UTF8StringLength];
		memcpy(s->cString, [firstComponent UTF8String], cStringLength);
		i = cStringLength;

		while ((component = va_arg(arguments, OFString*)) != nil) {
			cStringLength = [component UTF8StringLength];

			s->cString[i] = OF_PATH_DELIMITER;
			memcpy(s->cString + i + 1, [component UTF8String],
			    cStringLength);

			i += 1 + cStringLength;
		}

		s->cString[i] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (s != NULL && s->freeWhenDone != NULL)
		free(s->freeWhenDone);

	[super dealloc];
}

- (const char*)cStringUsingEncoding: (of_string_encoding_t)encoding
{
	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:
		return s->cString;
	case OF_STRING_ENCODING_ASCII:
		if (s->isUTF8)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];

		return s->cString;
	default:
		return [super cStringUsingEncoding: encoding];
	}
}

- (const char*)UTF8String
{
	return s->cString;
}

- (size_t)length
{
	return s->length;
}

- (size_t)lengthOfBytesUsingEncoding: (of_string_encoding_t)encoding
{
	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:
	case OF_STRING_ENCODING_ASCII:
		return s->cStringLength;
	default:
		return [super lengthOfBytesUsingEncoding: encoding];
	}
}

- (size_t)UTF8StringLength
{
	return s->cStringLength;
}

- (BOOL)isEqual: (id)object
{
	OFString_UTF8 *otherString;

	if (object == self)
		return YES;

	if (![object isKindOfClass: [OFString class]])
		return NO;

	otherString = object;

	if ([otherString UTF8StringLength] != s->cStringLength ||
	    [otherString length] != s->length)
		return NO;

	if (strcmp(s->cString, [otherString UTF8String]))
		return NO;

	return YES;
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFString *otherString;
	size_t otherCStringLength, minimumCStringLength;
	int compare;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherString = (OFString*)object;
	otherCStringLength = [otherString UTF8StringLength];
	minimumCStringLength = (s->cStringLength > otherCStringLength
	    ? otherCStringLength : s->cStringLength);

	if ((compare = memcmp(s->cString, [otherString UTF8String],
	    minimumCStringLength)) == 0) {
		if (s->cStringLength > otherCStringLength)
			return OF_ORDERED_DESCENDING;
		if (s->cStringLength < otherCStringLength)
			return OF_ORDERED_ASCENDING;
		return OF_ORDERED_SAME;
	}

	if (compare > 0)
		return OF_ORDERED_DESCENDING;
	else
		return OF_ORDERED_ASCENDING;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString
{
	const char *otherCString;
	size_t i, j, otherCStringLength, minimumCStringLength;
	int compare;

	if (otherString == self)
		return OF_ORDERED_SAME;

	if (![otherString isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherCString = [otherString UTF8String];
	otherCStringLength = [otherString UTF8StringLength];

	if (!s->isUTF8) {
		minimumCStringLength = (s->cStringLength > otherCStringLength
		    ? otherCStringLength : s->cStringLength);

		if ((compare = memcasecmp(s->cString, otherCString,
		    minimumCStringLength)) == 0) {
			if (s->cStringLength > otherCStringLength)
				return OF_ORDERED_DESCENDING;
			if (s->cStringLength < otherCStringLength)
				return OF_ORDERED_ASCENDING;
			return OF_ORDERED_SAME;
		}

		if (compare > 0)
			return OF_ORDERED_DESCENDING;
		else
			return OF_ORDERED_ASCENDING;
	}

	i = j = 0;

	while (i < s->cStringLength && j < otherCStringLength) {
		of_unichar_t c1, c2;
		size_t l1, l2;

		l1 = of_string_utf8_decode(s->cString + i,
		    s->cStringLength - i, &c1);
		l2 = of_string_utf8_decode(otherCString + j,
		    otherCStringLength - j, &c2);

		if (l1 == 0 || l2 == 0 || c1 > 0x10FFFF || c2 > 0x10FFFF)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];

		if (c1 >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			of_unichar_t tc =
			    of_unicode_casefolding_table[c1 >> 8][c1 & 0xFF];

			if (tc)
				c1 = tc;
		}

		if (c2 >> 8 < OF_UNICODE_CASEFOLDING_TABLE_SIZE) {
			of_unichar_t tc =
			    of_unicode_casefolding_table[c2 >> 8][c2 & 0xFF];

			if (tc)
				c2 = tc;
		}

		if (c1 > c2)
			return OF_ORDERED_DESCENDING;
		if (c1 < c2)
			return OF_ORDERED_ASCENDING;

		i += l1;
		j += l2;
	}

	if (s->cStringLength - i > otherCStringLength - j)
		return OF_ORDERED_DESCENDING;
	else if (s->cStringLength - i < otherCStringLength - j)
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (uint32_t)hash
{
	size_t i;
	uint32_t hash;

	if (s->hashed)
		return s->hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < s->cStringLength; i++) {
		of_unichar_t c;
		size_t length;

		if ((length = of_string_utf8_decode(s->cString + i,
		    s->cStringLength - i, &c)) == 0)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];

		OF_HASH_ADD(hash, (c & 0xFF0000) >> 16);
		OF_HASH_ADD(hash, (c & 0x00FF00) >>  8);
		OF_HASH_ADD(hash,  c & 0x0000FF);

		i += length - 1;
	}

	OF_HASH_FINALIZE(hash);

	s->hash = hash;
	s->hashed = YES;

	return hash;
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	of_unichar_t character;

	if (index >= s->length)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	if (!s->isUTF8)
		return s->cString[index];

	index = of_string_utf8_get_position(s->cString, index,
	    s->cStringLength);

	if (!of_string_utf8_decode(s->cString + index, s->cStringLength - index,
	    &character))
		@throw [OFInvalidEncodingException
		    exceptionWithClass: [self class]];

	return character;
}

- (void)getCharacters: (of_unichar_t*)buffer
	      inRange: (of_range_t)range
{
	/* TODO: Could be slightly optimized */
	void *pool = objc_autoreleasePoolPush();
	const of_unichar_t *characters = [self characters];

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > s->length)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	memcpy(buffer, characters + range.location,
	    range.length * sizeof(of_unichar_t));

	objc_autoreleasePoolPop(pool);
}

- (of_range_t)rangeOfString: (OFString*)string
		    options: (int)options
		      range: (of_range_t)range
{
	const char *cString = [string UTF8String];
	size_t i, cStringLength = [string UTF8StringLength];
	size_t rangeLocation, rangeLength;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > s->length)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	if (s->isUTF8) {
		rangeLocation = of_string_utf8_get_position(
		    s->cString, range.location, s->cStringLength);
		rangeLength = of_string_utf8_get_position(
		    s->cString + rangeLocation, range.length,
		    s->cStringLength - rangeLocation);
	} else {
		rangeLocation = range.location;
		rangeLength = range.length;
	}

	if (cStringLength == 0)
		return of_range(0, 0);

	if (cStringLength > rangeLength)
		return of_range(OF_NOT_FOUND, 0);

	if (options & OF_STRING_SEARCH_BACKWARDS) {
		for (i = rangeLength - cStringLength;; i--) {
			if (!memcmp(s->cString + rangeLocation + i, cString,
			    cStringLength)) {
				range.location += of_string_utf8_get_index(
				    s->cString + rangeLocation, i);
				range.length = [string length];

				return range;
			}

			/* Did not match and we're at the last char */
			if (i == 0)
				return of_range(OF_NOT_FOUND, 0);
		}
	} else {
		for (i = 0; i <= rangeLength - cStringLength; i++) {
			if (!memcmp(s->cString + rangeLocation + i, cString,
			    cStringLength)) {
				range.location += of_string_utf8_get_index(
				    s->cString + rangeLocation, i);
				range.length = [string length];

				return range;
			}
		}
	}

	return of_range(OF_NOT_FOUND, 0);
}

- (BOOL)containsString: (OFString*)string
{
	const char *cString = [string UTF8String];
	size_t i, cStringLength = [string UTF8StringLength];

	if (cStringLength == 0)
		return YES;

	if (cStringLength > s->cStringLength)
		return NO;

	for (i = 0; i <= s->cStringLength - cStringLength; i++)
		if (!memcmp(s->cString + i, cString, cStringLength))
			return YES;

	return NO;
}

- (OFString*)substringWithRange: (of_range_t)range
{
	size_t start = range.location;
	size_t end = range.location + range.length;

	if (range.length > SIZE_MAX - range.location || end > s->length)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	if (s->isUTF8) {
		start = of_string_utf8_get_position(s->cString, start,
		    s->cStringLength);
		end = of_string_utf8_get_position(s->cString, end,
		    s->cStringLength);
	}

	return [OFString stringWithUTF8String: s->cString + start
				       length: end - start];
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	size_t cStringLength = [prefix UTF8StringLength];

	if (cStringLength > s->cStringLength)
		return NO;

	return !memcmp(s->cString, [prefix UTF8String], cStringLength);
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	size_t cStringLength = [suffix UTF8StringLength];

	if (cStringLength > s->cStringLength)
		return NO;

	return !memcmp(s->cString + (s->cStringLength - cStringLength),
	    [suffix UTF8String], cStringLength);
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
				options: (int)options
{
	void *pool;
	OFMutableArray *array;
	const char *cString = [delimiter UTF8String];
	size_t cStringLength = [delimiter UTF8StringLength];
	BOOL skipEmpty = (options & OF_STRING_SKIP_EMPTY);
	size_t i, last;
	OFString *component;

	array = [OFMutableArray array];
	pool = objc_autoreleasePoolPush();

	if (cStringLength > s->cStringLength) {
		[array addObject: [[self copy] autorelease]];
		objc_autoreleasePoolPop(pool);

		return array;
	}

	for (i = 0, last = 0; i <= s->cStringLength - cStringLength; i++) {
		if (memcmp(s->cString + i, cString, cStringLength))
			continue;

		component = [OFString stringWithUTF8String: s->cString + last
						    length: i - last];
		if (!skipEmpty || ![component isEqual: @""])
			[array addObject: component];

		i += cStringLength - 1;
		last = i + 1;
	}
	component = [OFString stringWithUTF8String: s->cString + last];
	if (!skipEmpty || ![component isEqual: @""])
		[array addObject: component];

	[array makeImmutable];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (OFArray*)pathComponents
{
	OFMutableArray *ret;
	void *pool;
	size_t i, last = 0, pathCStringLength = s->cStringLength;

	ret = [OFMutableArray array];

	if (pathCStringLength == 0)
		return ret;

	pool = objc_autoreleasePoolPush();

#ifndef _WIN32
	if (s->cString[pathCStringLength - 1] == OF_PATH_DELIMITER)
#else
	if (s->cString[pathCStringLength - 1] == '/' ||
	    s->cString[pathCStringLength - 1] == '\\')
#endif
		pathCStringLength--;

	for (i = 0; i < pathCStringLength; i++) {
#ifndef _WIN32
		if (s->cString[i] == OF_PATH_DELIMITER) {
#else
		if (s->cString[i] == '/' || s->cString[i] == '\\') {
#endif
			[ret addObject:
			    [OFString stringWithUTF8String: s->cString + last
						    length: i - last]];
			last = i + 1;
		}
	}

	[ret addObject: [OFString stringWithUTF8String: s->cString + last
						length: i - last]];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFString*)lastPathComponent
{
	size_t pathCStringLength = s->cStringLength;
	ssize_t i;

	if (pathCStringLength == 0)
		return @"";

#ifndef _WIN32
	if (s->cString[pathCStringLength - 1] == OF_PATH_DELIMITER)
#else
	if (s->cString[pathCStringLength - 1] == '/' ||
	    s->cString[pathCStringLength - 1] == '\\')
#endif
		pathCStringLength--;

	for (i = pathCStringLength - 1; i >= 0; i--) {
#ifndef _WIN32
		if (s->cString[i] == OF_PATH_DELIMITER) {
#else
		if (s->cString[i] == '/' || s->cString[i] == '\\') {
#endif
			i++;
			break;
		}
	}

	/*
	 * Only one component, but the trailing delimiter might have been
	 * removed, so return a new string anyway.
	 */
	if (i < 0)
		i = 0;

	return [OFString stringWithUTF8String: s->cString + i
				       length: pathCStringLength - i];
}

- (OFString*)stringByDeletingLastPathComponent
{
	size_t i, pathCStringLength = s->cStringLength;

	if (pathCStringLength == 0)
		return @"";

#ifndef _WIN32
	if (s->cString[pathCStringLength - 1] == OF_PATH_DELIMITER)
#else
	if (s->cString[pathCStringLength - 1] == '/' ||
	    s->cString[pathCStringLength - 1] == '\\')
#endif
		pathCStringLength--;

	if (pathCStringLength == 0)
		return [OFString stringWithUTF8String: s->cString
					       length: 1];

	for (i = pathCStringLength - 1; i >= 1; i--)
#ifndef _WIN32
		if (s->cString[i] == OF_PATH_DELIMITER)
#else
		if (s->cString[i] == '/' || s->cString[i] == '\\')
#endif
			return [OFString stringWithUTF8String: s->cString
						       length: i];

#ifndef _WIN32
	if (s->cString[0] == OF_PATH_DELIMITER)
#else
	if (s->cString[0] == '/' || s->cString[0] == '\\')
#endif
		return [OFString stringWithUTF8String: s->cString
					       length: 1];

	return @".";
}

- (const of_unichar_t*)characters
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	of_unichar_t *ret;
	size_t i, j;

	ret = [object allocMemoryWithSize: sizeof(of_unichar_t)
				    count: s->length];

	i = j = 0;

	while (i < s->cStringLength) {
		of_unichar_t c;
		size_t cLen;

		cLen = of_string_utf8_decode(s->cString + i,
		    s->cStringLength - i, &c);

		if (cLen == 0 || c > 0x10FFFF)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];

		ret[j++] = c;
		i += cLen;
	}

	return ret;
}

- (const of_unichar_t*)UTF32StringWithByteOrder: (of_byte_order_t)byteOrder
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	of_unichar_t *ret;
	size_t i, j;

	ret = [object allocMemoryWithSize: sizeof(of_unichar_t)
				    count: s->length + 1];

	i = j = 0;

	while (i < s->cStringLength) {
		of_unichar_t c;
		size_t cLen;

		cLen = of_string_utf8_decode(s->cString + i,
		    s->cStringLength - i, &c);

		if (cLen == 0 || c > 0x10FFFF)
			@throw [OFInvalidEncodingException
			    exceptionWithClass: [self class]];

		if (byteOrder != OF_BYTE_ORDER_NATIVE)
			ret[j++] = OF_BSWAP32(c);
		else
			ret[j++] = c;

		i += cLen;
	}
	ret[j] = 0;

	return ret;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateLinesUsingBlock: (of_string_line_enumeration_block_t)block
{
	void *pool;
	const char *cString = s->cString;
	const char *last = cString;
	BOOL stop = NO, lastCarriageReturn = NO;

	while (!stop && *cString != 0) {
		if (lastCarriageReturn && *cString == '\n') {
			lastCarriageReturn = NO;

			cString++;
			last++;

			continue;
		}

		if (*cString == '\n' || *cString == '\r') {
			pool = objc_autoreleasePoolPush();

			block([OFString
			    stringWithUTF8String: last
					  length: cString - last], &stop);
			last = cString + 1;

			objc_autoreleasePoolPop(pool);
		}

		lastCarriageReturn = (*cString == '\r');
		cString++;
	}

	pool = objc_autoreleasePoolPush();

	if (!stop)
		block([OFString stringWithUTF8String: last
					      length: cString - last], &stop);

	objc_autoreleasePoolPop(pool);
}
#endif
@end
