/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>

#include <sys/stat.h>
#ifdef HAVE_MADVISE
# include <sys/mman.h>
#else
# define madvise(addr, len, advise)
#endif

#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
#import "OFDataArray.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"
#import "of_asprintf.h"
#import "unicode.h"

extern const uint16_t of_iso_8859_15[256];
extern const uint16_t of_windows_1252[256];

/* References for static linking */
void _references_to_categories_of_OFString(void)
{
	_OFString_Hashing_reference = 1;
	_OFString_Serialization_reference = 1;
	_OFString_URLEncoding_reference = 1;
	_OFString_XMLEscaping_reference = 1;
	_OFString_XMLUnescaping_reference = 1;
}

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
of_string_check_utf8(const char *cString, size_t cStringLength, size_t *length)
{
	size_t i, tmpLength = cStringLength;
	int isUTF8 = 0;

	madvise((void*)cString, cStringLength, MADV_SEQUENTIAL);

	for (i = 0; i < cStringLength; i++) {
		/* No sign of UTF-8 here */
		if (OF_LIKELY(!(cString[i] & 0x80)))
			continue;

		isUTF8 = 1;

		/* We're missing a start byte here */
		if (OF_UNLIKELY(!(cString[i] & 0x40))) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		/* 2 byte sequences for code points 0 - 127 are forbidden */
		if (OF_UNLIKELY((cString[i] & 0x7E) == 0x40)) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		/* We have at minimum a 2 byte character -> check next byte */
		if (OF_UNLIKELY(cStringLength <= i + 1 ||
		    (cString[i + 1] & 0xC0) != 0x80)) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		/* Check if we have at minimum a 3 byte character */
		if (OF_LIKELY(!(cString[i] & 0x20))) {
			i++;
			tmpLength--;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if (OF_UNLIKELY(cStringLength <= i + 2 ||
		    (cString[i + 2] & 0xC0) != 0x80)) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		/* Check if we have a 4 byte character */
		if (OF_LIKELY(!(cString[i] & 0x10))) {
			i += 2;
			tmpLength -= 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if (OF_UNLIKELY(cStringLength <= i + 3 ||
		    (cString[i + 3] & 0xC0) != 0x80)) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if (OF_UNLIKELY(cString[i] & 0x08)) {
			madvise((void*)cString, cStringLength, MADV_NORMAL);
			return -1;
		}

		i += 3;
		tmpLength -= 3;
	}

	madvise((void*)cString, cStringLength, MADV_NORMAL);

	if (length != NULL)
		*length = tmpLength;

	return isUTF8;
}

size_t
of_string_unicode_to_utf8(of_unichar_t character, char *buffer)
{
	size_t i = 0;

	if (character < 0x80) {
		buffer[i] = character;
		return 1;
	}
	if (character < 0x800) {
		buffer[i++] = 0xC0 | (character >> 6);
		buffer[i] = 0x80 | (character & 0x3F);
		return 2;
	}
	if (character < 0x10000) {
		buffer[i++] = 0xE0 | (character >> 12);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 3;
	}
	if (character < 0x110000) {
		buffer[i++] = 0xF0 | (character >> 18);
		buffer[i++] = 0x80 | (character >> 12 & 0x3F);
		buffer[i++] = 0x80 | (character >> 6 & 0x3F);
		buffer[i] = 0x80 | (character & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_utf8_to_unicode(const char *buffer_, size_t length, of_unichar_t *ret)
{
	const uint8_t *buffer = (const uint8_t*)buffer_;

	if (!(*buffer & 0x80)) {
		*ret = buffer[0];
		return 1;
	}

	if ((*buffer & 0xE0) == 0xC0) {
		if (OF_UNLIKELY(length < 2))
			return 0;

		*ret = ((buffer[0] & 0x1F) << 6) | (buffer[1] & 0x3F);
		return 2;
	}

	if ((*buffer & 0xF0) == 0xE0) {
		if (OF_UNLIKELY(length < 3))
			return 0;

		*ret = ((buffer[0] & 0x0F) << 12) | ((buffer[1] & 0x3F) << 6) |
		    (buffer[2] & 0x3F);
		return 3;
	}

	if ((*buffer & 0xF8) == 0xF0) {
		if (OF_UNLIKELY(length < 4))
			return 0;

		*ret = ((buffer[0] & 0x07) << 18) | ((buffer[1] & 0x3F) << 12) |
		    ((buffer[2] & 0x3F) << 6) | (buffer[3] & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_position_to_index(const char *string, size_t position)
{
	size_t i, index = position;

	for (i = 0; i < position; i++)
		if (OF_UNLIKELY((string[i] & 0xC0) == 0x80))
			index--;

	return index;
}

size_t
of_string_index_to_position(const char *string, size_t index, size_t length)
{
	size_t i;

	for (i = 0; i <= index; i++)
		if (OF_UNLIKELY((string[i] & 0xC0) == 0x80))
			if (++index > length)
				return OF_INVALID_INDEX;

	return index;
}

size_t
of_unicode_string_length(const of_unichar_t *string)
{
	const of_unichar_t *string_ = string;

	while (*string_ != 0)
		string_++;

	return (size_t)(string_ - string);
}

size_t
of_utf16_string_length(const uint16_t *string)
{
	const uint16_t *string_ = string;

	while (*string_ != 0)
		string_++;

	return (size_t)(string_ - string);
}

@implementation OFString
+ string
{
	return [[[self alloc] init] autorelease];
}

+ stringWithCString: (const char*)cString
{
	return [[[self alloc] initWithCString: cString] autorelease];
}

+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding] autorelease];
}

+ stringWithCString: (const char*)cString
	   encoding: (of_string_encoding_t)encoding
	     length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				     encoding: encoding
				       length: cStringLength] autorelease];
}

+ stringWithCString: (const char*)cString
	     length: (size_t)cStringLength
{
	return [[[self alloc] initWithCString: cString
				       length: cStringLength] autorelease];
}

+ stringWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ stringWithUnicodeString: (of_unichar_t*)string
{
	return [[[self alloc] initWithUnicodeString: string] autorelease];
}

+ stringWithUnicodeString: (of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
{
	return [[[self alloc] initWithUnicodeString: string
					  byteOrder: byteOrder] autorelease];
}

+ stringWithUnicodeString: (of_unichar_t*)string
		   length: (size_t)length
{
	return [[[self alloc] initWithUnicodeString: string
					     length: length] autorelease];
}

+ stringWithUnicodeString: (of_unichar_t*)string
		byteOrder: (of_endianess_t)byteOrder
		   length: (size_t)length
{
	return [[[self alloc] initWithUnicodeString: string
					  byteOrder: byteOrder
					     length: length] autorelease];
}

+ stringWithUTF16String: (uint16_t*)string
{
	return [[[self alloc] initWithUTF16String: string] autorelease];
}

+ stringWithUTF16String: (uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder] autorelease];
}

+ stringWithUTF16String: (uint16_t*)string
		 length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					   length: length] autorelease];
}

+ stringWithUTF16String: (uint16_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	return [[[self alloc] initWithUTF16String: string
					byteOrder: byteOrder
					   length: length] autorelease];
}

+ stringWithFormat: (OFConstantString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [[[self alloc] initWithFormat: format
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ stringWithPath: (OFString*)firstComponent, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstComponent);
	ret = [[[self alloc] initWithPath: firstComponent
				arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ stringWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ stringWithContentsOfFile: (OFString*)path
		  encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}

+ stringWithContentsOfURL: (OFURL*)URL
{
	return [[[self alloc] initWithContentsOfURL: URL] autorelease];
}

+ stringWithContentsOfURL: (OFURL*)URL
		 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithContentsOfURL: URL
					   encoding: encoding] autorelease];
}

- init
{
	self = [super init];

	@try {
		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		s->cString = [self allocMemoryWithSize: 1];
		s->cString[0] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCString: (const char*)cString
{
	return [self initWithCString: cString
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: strlen(cString)];
}

- initWithCString: (const char*)cString
	 encoding: (of_string_encoding_t)encoding
{
	return [self initWithCString: cString
			    encoding: encoding
			      length: strlen(cString)];
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

		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		s->cString = [self allocMemoryWithSize: cStringLength + 1];
		s->cStringLength = cStringLength;

		if (encoding == OF_STRING_ENCODING_UTF_8) {
			switch (of_string_check_utf8(cString, cStringLength,
			    &s->length)) {
			case 1:
				s->isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
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
				bytes = of_string_unicode_to_utf8(
				    (uint8_t)cString[i], buffer);

				if (bytes == 0)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				s->cStringLength += bytes - 1;
				s->cString = [self
				    resizeMemory: s->cString
					  toSize: s->cStringLength + 1];

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
			@throw [OFInvalidEncodingException newWithClass: isa];
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
				    newWithClass: isa];

			s->isUTF8 = YES;
			characterBytes = of_string_unicode_to_utf8(character,
			    buffer);

			if (characterBytes == 0)
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			s->cStringLength += characterBytes - 1;
			s->cString = [self resizeMemory: s->cString
						 toSize: s->cStringLength + 1];

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

- initWithCString: (const char*)cString
	   length: (size_t)cStringLength
{
	return [self initWithCString: cString
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: cStringLength];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		/*
		 * We need one call to make sure it's initialized (in case it's
		 * a constant string).
		 */
		s->cStringLength = [string cStringLength];
		s->isUTF8 = string->s->isUTF8;
		s->length = string->s->length;

		s->cString = [self allocMemoryWithSize: s->cStringLength + 1];
		memcpy(s->cString, string->s->cString, s->cStringLength + 1);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithUnicodeString: (of_unichar_t*)string
{
	return [self initWithUnicodeString: string
				 byteOrder: OF_ENDIANESS_NATIVE
				    length: of_unicode_string_length(string)];
}

- initWithUnicodeString: (of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
{
	return [self initWithUnicodeString: string
				 byteOrder: byteOrder
				    length: of_unicode_string_length(string)];
}

- initWithUnicodeString: (of_unichar_t*)string
		 length: (size_t)length
{
	return [self initWithUnicodeString: string
				 byteOrder: OF_ENDIANESS_NATIVE
				    length: length];
}

- initWithUnicodeString: (of_unichar_t*)string
	      byteOrder: (of_endianess_t)byteOrder
		 length: (size_t)length
{
	self = [super init];

	@try {
		size_t i, j = 0;
		BOOL swap = NO;

		if (length > 0 && *string == 0xFEFF) {
			string++;
			length--;
		} else if (length > 0 && *string == 0xFFFE0000) {
			swap = YES;
			string++;
			length--;
		} else if (byteOrder != OF_ENDIANESS_NATIVE)
			swap = YES;

		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		s->cStringLength = length;
		s->cString = [self allocMemoryWithSize: (length * 4) + 1];
		s->length = length;

		for (i = 0; i < length; i++) {
			char buffer[4];
			size_t characterLen = of_string_unicode_to_utf8(
			    (swap ? of_bswap32(string[i]) : string[i]),
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
				    newWithClass: isa];
			}
		}

		s->cString[j] = '\0';

		@try {
			s->cString = [self resizeMemory: s->cString
						 toSize: s->cStringLength + 1];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
			[e release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithUTF16String: (uint16_t*)string
{
	return [self initWithUTF16String: string
			       byteOrder: OF_ENDIANESS_NATIVE
				  length: of_utf16_string_length(string)];
}

- initWithUTF16String: (uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
{
	return [self initWithUTF16String: string
			       byteOrder: byteOrder
				  length: of_utf16_string_length(string)];
}

- initWithUTF16String: (uint16_t*)string
	       length: (size_t)length
{
	return [self initWithUTF16String: string
			       byteOrder: OF_ENDIANESS_NATIVE
				  length: length];
}

- initWithUTF16String: (uint16_t*)string
	    byteOrder: (of_endianess_t)byteOrder
	       length: (size_t)length
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
		} else if (byteOrder != OF_ENDIANESS_NATIVE)
			swap = YES;

		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		s->cStringLength = length;
		s->cString = [self allocMemoryWithSize: (length * 4) + 1];
		s->length = length;

		for (i = 0; i < length; i++) {
			char buffer[4];
			of_unichar_t character =
			    (swap ? of_bswap16(string[i]) : string[i]);
			size_t characterLen;

			/* Missing high surrogate */
			if ((character & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			if ((character & 0xFC00) == 0xD800) {
				uint16_t nextCharacter;

				if (length <= i + 1)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				nextCharacter = (swap
				    ? of_bswap16(string[i + 1])
				    : string[i + 1]);
				character = (((character & 0x3FF) << 10) |
				    (nextCharacter & 0x3FF)) + 0x10000;

				i++;
				s->cStringLength--;
				s->length--;
			}

			characterLen = of_string_unicode_to_utf8(
			    character, buffer);

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
				    newWithClass: isa];
			}
		}

		s->cString[j] = '\0';

		@try {
			s->cString = [self resizeMemory: s->cString
						 toSize: s->cStringLength + 1];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only tried to make it smaller */
			[e release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFormat: (OFConstantString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self initWithFormat: format
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithFormat: (OFConstantString*)format
       arguments: (va_list)arguments
{
	self = [super init];

	@try {
		int cStringLength;

		if (format == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		if ((cStringLength = of_vasprintf(&s->cString, [format cString],
		    arguments)) == -1)
			@throw [OFInvalidFormatException newWithClass: isa];

		s->cStringLength = cStringLength;

		@try {
			switch (of_string_check_utf8(s->cString,
			    cStringLength, &s->length)) {
			case 1:
				s->isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			}

			[self addMemoryToPool: s->cString];
		} @catch (id e) {
			free(s->cString);
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithPath: (OFString*)firstComponent, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstComponent);
	ret = [self initWithPath: firstComponent
		       arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithPath: (OFString*)firstComponent
     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		OFString *component;
		size_t i, cStringLength;
		va_list argumentsCopy;

		s = [self allocMemoryWithSize: sizeof(*s)];
		memset(s, 0, sizeof(*s));

		/*
		 * First needs to be a call to be sure it is initialized, in
		 * case it's a constant string.
		 */
		s->cStringLength = [firstComponent cStringLength];
		s->isUTF8 = firstComponent->s->isUTF8;
		s->length = firstComponent->s->length;

		/* Calculate length and see if we need UTF-8 */
		va_copy(argumentsCopy, arguments);
		while ((component = va_arg(argumentsCopy, OFString*)) != nil) {
			/* First needs to be a call, see above */
			s->cStringLength += 1 + [component cStringLength];
			s->length += 1 + component->s->length;

			if (component->s->isUTF8)
				s->isUTF8 = YES;
		}

		s->cString = [self allocMemoryWithSize: s->cStringLength + 1];

		cStringLength = [firstComponent cStringLength];
		memcpy(s->cString, [firstComponent cString], cStringLength);
		i = cStringLength;

		while ((component = va_arg(arguments, OFString*)) != nil) {
			/*
			 * We already sent each component a message, so we can
			 * be sure they are initialized and access them
			 * directly.
			 */
			cStringLength = component->s->cStringLength;

			s->cString[i] = OF_PATH_DELIMITER;
			memcpy(s->cString + i + 1, component->s->cString,
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

- initWithContentsOfFile: (OFString*)path
{
	return [self initWithContentsOfFile: path
				   encoding: OF_STRING_ENCODING_UTF_8];
}

- initWithContentsOfFile: (OFString*)path
		encoding: (of_string_encoding_t)encoding
{
	char *tmp;
	struct stat st;

	@try {
		OFFile *file;

		if (stat([path cString], &st) == -1)
			@throw [OFOpenFileFailedException newWithClass: isa
								  path: path
								  mode: @"rb"];

		if (st.st_size > SIZE_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

		@try {
			tmp = [self allocMemoryWithSize: (size_t)st.st_size];

			[file readExactlyNBytes: (size_t)st.st_size
				     intoBuffer: tmp];
		} @finally {
			[file release];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCString: tmp
			    encoding: encoding
			      length: (size_t)st.st_size];
	[self freeMemory: tmp];

	return self;
}

- initWithContentsOfURL: (OFURL*)URL
{
	return [self initWithContentsOfURL: URL
				  encoding: OF_STRING_ENCODING_AUTODETECT];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	OFAutoreleasePool *pool;
	OFHTTPRequest *request;
	OFHTTPRequestResult *result;
	OFMutableString *contentType;
	Class c;

	c = isa;
	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	if ([[URL scheme] isEqual: @"file"]) {
		if (encoding == OF_STRING_ENCODING_AUTODETECT)
			encoding = OF_STRING_ENCODING_UTF_8;

		self = [[c alloc] initWithContentsOfFile: [URL path]
						encoding: encoding];
		[pool release];
		return self;
	}

	request = [OFHTTPRequest requestWithURL: URL];
	result = [request perform];

	if ([result statusCode] != 200)
		@throw [OFHTTPRequestFailedException
		    newWithClass: [request class]
		     HTTPRequest: request
			  result: result];

	if (encoding == OF_STRING_ENCODING_AUTODETECT &&
	    (contentType = [[result headers] objectForKey: @"Content-Type"])) {
		contentType = [[contentType mutableCopy] autorelease];
		[contentType lower];

		if ([contentType hasSuffix: @"charset=UTF-8"])
			encoding = OF_STRING_ENCODING_UTF_8;
		if ([contentType hasSuffix: @"charset=iso-8859-1"])
			encoding = OF_STRING_ENCODING_ISO_8859_1;
		if ([contentType hasSuffix: @"charset=iso-8859-15"])
			encoding = OF_STRING_ENCODING_ISO_8859_15;
		if ([contentType hasSuffix: @"charset=windows-1252"])
			encoding = OF_STRING_ENCODING_WINDOWS_1252;
	}

	if (encoding == OF_STRING_ENCODING_AUTODETECT)
		encoding = OF_STRING_ENCODING_UTF_8;

	self = [[c alloc] initWithCString: (char*)[[result data] cArray]
				 encoding: encoding
				   length: [[result data] count]];

	[pool release];
	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		self = [self initWithString: [element stringValue]];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (const char*)cString
{
	return s->cString;
}

- (size_t)length
{
	return s->length;
}

- (size_t)cStringLength
{
	return s->cStringLength;
}

- (BOOL)isEqual: (id)object
{
	OFString *otherString;

	if (![object isKindOfClass: [OFString class]])
		return NO;

	otherString = object;

	if ([otherString cStringLength] != s->cStringLength ||
	    otherString->s->length != s->length)
		return NO;

	if (strcmp(s->cString, otherString->s->cString))
		return NO;

	return YES;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (of_comparison_result_t)compare: (id)object
{
	OFString *otherString;
	size_t otherCStringLength, minimumCStringLength;
	int compare;

	if (![object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	otherString = object;
	otherCStringLength = [otherString cStringLength];
	minimumCStringLength = (s->cStringLength > otherCStringLength
	    ? otherCStringLength : s->cStringLength);

	if ((compare = memcmp(s->cString, [otherString cString],
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

	if (![otherString isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	otherCString = [otherString cString];
	otherCStringLength = [otherString cStringLength];

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

		l1 = of_string_utf8_to_unicode(s->cString + i,
		    s->cStringLength - i, &c1);
		l2 = of_string_utf8_to_unicode(otherCString + j,
		    otherCStringLength - j, &c2);

		if (l1 == 0 || l2 == 0 || c1 > 0x10FFFF || c2 > 0x10FFFF)
			@throw [OFInvalidEncodingException newWithClass: isa];

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
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < s->cStringLength; i++)
		OF_HASH_ADD(hash, s->cString[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	return [[self copy] autorelease];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;
	OFString *className;

	if ([self isKindOfClass: [OFConstantString class]])
		className = @"OFString";
	else
		className = [self className];

	element = [OFXMLElement elementWithName: className
				      namespace: OF_SERIALIZATION_NS
				    stringValue: self];

	[element retain];
	@try {
		[pool release];
	} @finally {
		[element autorelease];
	}

	return element;
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	of_unichar_t character;

	if (index >= s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (!s->isUTF8)
		return s->cString[index];

	index = of_string_index_to_position(s->cString, index,
	    s->cStringLength);

	if (!of_string_utf8_to_unicode(s->cString + index,
	    s->cStringLength - index, &character))
		@throw [OFInvalidEncodingException newWithClass: isa];

	return character;
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string
{
	const char *cString = [string cString];
	size_t i, cStringLength = [string cStringLength];

	if (cStringLength == 0)
		return 0;

	if (cStringLength > s->cStringLength)
		return OF_INVALID_INDEX;

	for (i = 0; i <= s->cStringLength - cStringLength; i++)
		if (!memcmp(s->cString + i, cString, cStringLength))
			return of_string_position_to_index(s->cString, i);

	return OF_INVALID_INDEX;
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)string
{
	const char *cString = [string cString];
	size_t i, cStringLength = [string cStringLength];

	if (cStringLength == 0)
		return of_string_position_to_index(s->cString,
		    s->cStringLength);

	if (cStringLength > s->cStringLength)
		return OF_INVALID_INDEX;

	for (i = s->cStringLength - cStringLength;; i--) {
		if (!memcmp(s->cString + i, cString, cStringLength))
			return of_string_position_to_index(s->cString, i);

		/* Did not match and we're at the last char */
		if (i == 0)
			return OF_INVALID_INDEX;
	}
}

- (BOOL)containsString: (OFString*)string
{
	const char *cString = [string cString];
	size_t i, cStringLength = string->s->cStringLength;

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
	size_t start = range.start;
	size_t end = range.start + range.length;

	if (end > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (s->isUTF8) {
		start = of_string_index_to_position(s->cString, start,
		    s->cStringLength);
		end = of_string_index_to_position(s->cString, end,
		    s->cStringLength);
	}

	return [OFString stringWithCString: s->cString + start
				    length: end - start];
}

- (OFString*)stringByAppendingString: (OFString*)string
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendString: string];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByPrependingString: (OFString*)string
{
	OFMutableString *new = [[string mutableCopy] autorelease];

	[new appendString: self];

	[new makeImmutable];

	return new;
}

- (OFString*)uppercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new upper];

	[new makeImmutable];

	return new;
}

- (OFString*)lowercaseString
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new lower];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingLeadingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteLeadingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingTrailingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteTrailingWhitespaces];

	[new makeImmutable];

	return new;
}

- (OFString*)stringByDeletingEnclosingWhitespaces
{
	OFMutableString *new = [[self mutableCopy] autorelease];

	[new deleteEnclosingWhitespaces];

	[new makeImmutable];

	return new;
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	size_t cStringLength = [prefix cStringLength];

	if (cStringLength > s->cStringLength)
		return NO;

	return !memcmp(s->cString, [prefix cString], cStringLength);
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	size_t cStringLength = [suffix cStringLength];

	if (cStringLength > s->cStringLength)
		return NO;

	return !memcmp(s->cString + (s->cStringLength - cStringLength),
	    [suffix cString], cStringLength);
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	OFAutoreleasePool *pool;
	OFMutableArray *array;
	const char *cString = [delimiter cString];
	size_t cStringLength = [delimiter cStringLength];
	size_t i, last;

	array = [OFMutableArray array];
	pool = [[OFAutoreleasePool alloc] init];

	if (cStringLength > s->cStringLength) {
		[array addObject: [[self copy] autorelease]];
		[pool release];

		return array;
	}

	for (i = 0, last = 0; i <= s->cStringLength - cStringLength; i++) {
		if (memcmp(s->cString + i, cString, cStringLength))
			continue;

		[array addObject: [OFString stringWithCString: s->cString + last
						       length: i - last]];
		i += cStringLength - 1;
		last = i + 1;
	}
	[array addObject: [OFString stringWithCString: s->cString + last]];

	[array makeImmutable];

	[pool release];

	return array;
}

- (OFArray*)pathComponents
{
	OFMutableArray *ret;
	OFAutoreleasePool *pool;
	size_t i, last = 0, pathCStringLength = s->cStringLength;

	ret = [OFMutableArray array];

	if (pathCStringLength == 0)
		return ret;

	pool = [[OFAutoreleasePool alloc] init];

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
			    [OFString stringWithCString: s->cString + last
						 length: i - last]];
			last = i + 1;
		}
	}

	[ret addObject: [OFString stringWithCString: s->cString + last
					     length: i - last]];

	[ret makeImmutable];

	[pool release];

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
		if (s->cString[i] == '/' || s->string[i] == '\\') {
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

	return [OFString stringWithCString: s->cString + i
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
		return [OFString stringWithCString: s->cString
					    length: 1];

	for (i = pathCStringLength - 1; i >= 1; i--)
#ifndef _WIN32
		if (s->cString[i] == OF_PATH_DELIMITER)
#else
		if (s->cString[i] == '/' || s->cString[i] == '\\')
#endif
			return [OFString stringWithCString: s->cString
						    length: i];

#ifndef _WIN32
	if (s->cString[0] == OF_PATH_DELIMITER)
#else
	if (s->cString[0] == '/' || s->cString[0] == '\\')
#endif
		return [OFString stringWithCString: s->cString
					    length: 1];

	return @".";
}

- (intmax_t)decimalValue
{
	const char *cString = s->cString;
	size_t cStringLength = s->cStringLength;
	int i = 0;
	intmax_t value = 0;
	BOOL expectWhitespace = NO;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r') {
		cString++;
		cStringLength--;
	}

	if (cString[0] == '-' || cString[0] == '+')
		i++;

	for (; i < cStringLength; i++) {
		if (expectWhitespace) {
			if (cString[i] != ' ' && cString[i] != '\t' &&
			    cString[i] != '\n' && cString[i] != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
			continue;
		}

		if (cString[i] >= '0' && cString[i] <= '9') {
			if (INTMAX_MAX / 10 < value ||
			    INTMAX_MAX - value * 10 < cString[i] - '0')
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			value = (value * 10) + (cString[i] - '0');
		} else if (cString[i] == ' ' || cString[i] == '\t' ||
		    cString[i] == '\n' || cString[i] == '\r')
			expectWhitespace = YES;
		else
			@throw [OFInvalidFormatException newWithClass: isa];
	}

	if (cString[0] == '-')
		value *= -1;

	return value;
}

- (uintmax_t)hexadecimalValue
{
	const char *cString = s->cString;
	size_t cStringLength = s->cStringLength;
	int i = 0;
	uintmax_t value = 0;
	BOOL expectWhitespace = NO, foundValue = NO;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r') {
		cString++;
		cStringLength--;
	}

	if (cStringLength == 0)
		return 0;

	if (cStringLength >= 2 && cString[0] == '0' && cString[1] == 'x')
		i = 2;
	else if (cStringLength >= 1 && (cString[0] == 'x' || cString[0] == '$'))
		i = 1;

	for (; i < cStringLength; i++) {
		uintmax_t newValue;

		if (expectWhitespace) {
			if (cString[i] != ' ' && cString[i] != '\t' &&
			    cString[i] != '\n' && cString[i] != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
			continue;
		}

		if (cString[i] >= '0' && cString[i] <= '9') {
			newValue = (value << 4) | (cString[i] - '0');
			foundValue = YES;
		} else if (cString[i] >= 'A' && cString[i] <= 'F') {
			newValue = (value << 4) | (cString[i] - 'A' + 10);
			foundValue = YES;
		} else if (cString[i] >= 'a' && cString[i] <= 'f') {
			newValue = (value << 4) | (cString[i] - 'a' + 10);
			foundValue = YES;
		} else if (cString[i] == 'h' || cString[i] == ' ' ||
		    cString[i] == '\t' || cString[i] == '\n' ||
		    cString[i] == '\r') {
			expectWhitespace = YES;
			continue;
		} else
			@throw [OFInvalidFormatException newWithClass: isa];

		if (newValue < value)
			@throw [OFOutOfRangeException newWithClass: isa];

		value = newValue;
	}

	if (!foundValue)
		@throw [OFInvalidFormatException newWithClass: isa];

	return value;
}

- (float)floatValue
{
	const char *cString = s->cString;
	char *endPointer = NULL;
	float value;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r')
		cString++;

	value = strtof(cString, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];

	return value;
}

- (double)doubleValue
{
	const char *cString = s->cString;
	char *endPointer = NULL;
	double value;

	while (*cString == ' ' || *cString == '\t' || *cString == '\n' ||
	    *cString == '\r')
		cString++;

	value = strtod(cString, &endPointer);

	/* Check if there are any invalid chars left */
	if (endPointer != NULL)
		for (; *endPointer != '\0'; endPointer++)
			if (*endPointer != ' ' && *endPointer != '\t' &&
			    *endPointer != '\n' && *endPointer != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];

	return value;
}

- (of_unichar_t*)unicodeString
{
	OFObject *object = [[[OFObject alloc] init] autorelease];
	of_unichar_t *ret;
	size_t i, j;

	ret = [object allocMemoryForNItems: s->length + 2
				  withSize: sizeof(of_unichar_t)];

	i = 0;
	j = 0;

	ret[j++] = 0xFEFF;

	while (i < s->cStringLength) {
		of_unichar_t c;
		size_t cLen;

		cLen = of_string_utf8_to_unicode(s->cString + i,
		    s->cStringLength - i, &c);

		if (cLen == 0 || c > 0x10FFFF)
			@throw [OFInvalidEncodingException newWithClass: isa];

		ret[j++] = c;
		i += cLen;
	}

	ret[j] = 0;

	return ret;
}

- (void)writeToFile: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *file;

	file = [OFFile fileWithPath: path
			       mode: @"wb"];
	[file writeString: self];

	[pool release];
}
@end
