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
#import "OFFile.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
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
	_OFString_URLEncoding_reference = 1;
	_OFString_XMLEscaping_reference = 1;
	_OFString_XMLUnescaping_reference = 1;
};

static inline int
memcasecmp(const char *first, const char *second, size_t len)
{
	size_t i;

	for (i = 0; i < len; i++) {
		if (tolower((int)first[i]) > tolower((int)second[i]))
			return OF_ORDERED_DESCENDING;
		if (tolower((int)first[i]) < tolower((int)second[i]))
			return OF_ORDERED_ASCENDING;
	}

	return OF_ORDERED_SAME;
}

int
of_string_check_utf8(const char *str, size_t len)
{
	size_t i;
	int utf8 = 0;

	madvise((void*)str, len, MADV_SEQUENTIAL);

	for (i = 0; i < len; i++) {
		/* No sign of UTF-8 here */
		if (OF_LIKELY(!(str[i] & 0x80)))
			continue;

		utf8 = 1;

		/* We're missing a start byte here */
		if (OF_UNLIKELY(!(str[i] & 0x40))) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* We have at minimum a 2 byte character -> check next byte */
		if (OF_UNLIKELY(len < i + 1 || (str[i + 1] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* Check if we have at minimum a 3 byte character */
		if (OF_LIKELY(!(str[i] & 0x20))) {
			i++;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if (OF_UNLIKELY(len < i + 2 || (str[i + 2] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* Check if we have a 4 byte character */
		if (OF_LIKELY(!(str[i] & 0x10))) {
			i += 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if (OF_UNLIKELY(len < i + 3 || (str[i + 3] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if (OF_UNLIKELY(str[i] & 0x08)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		i += 3;
	}

	madvise((void*)str, len, MADV_NORMAL);

	return utf8;
}

size_t
of_string_unicode_to_utf8(of_unichar_t c, char *buf)
{
	size_t i = 0;

	if (c < 0x80) {
		buf[i] = c;
		return 1;
	}
	if (c < 0x800) {
		buf[i++] = 0xC0 | (c >> 6);
		buf[i] = 0x80 | (c & 0x3F);
		return 2;
	}
	if (c < 0x10000) {
		buf[i++] = 0xE0 | (c >> 12);
		buf[i++] = 0x80 | (c >> 6 & 0x3F);
		buf[i] = 0x80 | (c & 0x3F);
		return 3;
	}
	if (c < 0x110000) {
		buf[i++] = 0xF0 | (c >> 18);
		buf[i++] = 0x80 | (c >> 12 & 0x3F);
		buf[i++] = 0x80 | (c >> 6 & 0x3F);
		buf[i] = 0x80 | (c & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_utf8_to_unicode(const char *buf_, size_t len, of_unichar_t *ret)
{
	const uint8_t *buf = (const uint8_t*)buf_;

	if (!(*buf & 0x80)) {
		*ret = buf[0];
		return 1;
	}

	if ((*buf & 0xE0) == 0xC0) {
		if (OF_UNLIKELY(len < 2))
			return 0;

		*ret = ((buf[0] & 0x1F) << 6) | (buf[1] & 0x3F);
		return 2;
	}

	if ((*buf & 0xF0) == 0xE0) {
		if (OF_UNLIKELY(len < 3))
			return 0;

		*ret = ((buf[0] & 0x0F) << 12) | ((buf[1] & 0x3F) << 6) |
		    (buf[2] & 0x3F);
		return 3;
	}

	if ((*buf & 0xF8) == 0xF0) {
		if (OF_UNLIKELY(len < 4))
			return 0;

		*ret = ((buf[0] & 0x07) << 18) | ((buf[1] & 0x3F) << 12) |
		    ((buf[2] & 0x3F) << 6) | (buf[3] & 0x3F);
		return 4;
	}

	return 0;
}

size_t
of_string_position_to_index(const char *str, size_t pos)
{
	size_t i, idx = pos;

	for (i = 0; i < pos; i++)
		if (OF_UNLIKELY((str[i] & 0xC0) == 0x80))
			idx--;

	return idx;
}

size_t
of_string_index_to_position(const char *str, size_t idx, size_t len)
{
	size_t i;

	for (i = 0; i <= idx; i++)
		if (OF_UNLIKELY((str[i] & 0xC0) == 0x80))
			if (++idx > len)
				return OF_INVALID_INDEX;

	return idx;
}

@implementation OFString
+ string
{
	return [[[self alloc] init] autorelease];
}

+ stringWithCString: (const char*)string
{
	return [[[self alloc] initWithCString: string] autorelease];
}

+ stringWithCString: (const char*)string
	   encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithCString: string
				     encoding: encoding] autorelease];
}

+ stringWithCString: (const char*)string
	   encoding: (of_string_encoding_t)encoding
	     length: (size_t)length
{
	return [[[self alloc] initWithCString: string
				     encoding: encoding
				       length: length] autorelease];
}

+ stringWithCString: (const char*)string
	     length: (size_t)length
{
	return [[[self alloc] initWithCString: string
				       length: length] autorelease];
}

+ stringWithFormat: (OFString*)format, ...
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

+ stringWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
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
		string = [self allocMemoryWithSize: 1];
		string[0] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCString: (const char*)string_
{
	return [self initWithCString: string_
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: strlen(string_)];
}

- initWithCString: (const char*)string_
	 encoding: (of_string_encoding_t)encoding
{
	return [self initWithCString: string_
			    encoding: encoding
			      length: strlen(string_)];
}

- initWithCString: (const char*)string_
	 encoding: (of_string_encoding_t)encoding
	   length: (size_t)length_
{
	self = [super init];

	@try {
		size_t i, j;
		const uint16_t *table;

		if (encoding == OF_STRING_ENCODING_UTF_8 &&
		    length_ >= 3 && !memcmp(string_, "\xEF\xBB\xBF", 3)) {
			string_ += 3;
			length_ -= 3;
		}

		string = [self allocMemoryWithSize: length_ + 1];
		length = length_;

		if (encoding == OF_STRING_ENCODING_UTF_8) {
			switch (of_string_check_utf8(string_, length)) {
			case 1:
				isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			}

			memcpy(string, string_, length);
			string[length] = 0;

			return self;
		}

		if (encoding == OF_STRING_ENCODING_ISO_8859_1) {
			for (i = j = 0; i < length_; i++) {
				char buf[4];
				size_t bytes;

				if (!(string_[i] & 0x80)) {
					string[j++] = string_[i];
					continue;
				}

				isUTF8 = YES;
				bytes = of_string_unicode_to_utf8(
				    (uint8_t)string_[i], buf);

				if (bytes == 0)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				length += bytes - 1;
				string = [self resizeMemory: string
						     toSize: length + 1];

				memcpy(string + j, buf, bytes);
				j += bytes;
			}

			string[length] = 0;

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

		for (i = j = 0; i < length_; i++) {
			char buf[4];
			of_unichar_t character;
			size_t characterBytes;

			if (!(string_[i] & 0x80)) {
				string[j++] = string_[i];
				continue;
			}

			character = table[(uint8_t)string_[i]];

			if (character == 0xFFFD)
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			isUTF8 = YES;
			characterBytes = of_string_unicode_to_utf8(character,
			    buf);

			if (characterBytes == 0)
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			length += characterBytes - 1;
			string = [self resizeMemory: string
					     toSize: length + 1];

			memcpy(string + j, buf, characterBytes);
			j += characterBytes;
		}

		string[length] = 0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCString: (const char*)string_
	   length: (size_t)length_
{
	return [self initWithCString: string_
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: length_];
}

- initWithFormat: (OFString*)format, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, format);
	ret = [self initWithFormat: format
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithFormat: (OFString*)format
       arguments: (va_list)arguments
{
	self = [super init];

	@try {
		int len;

		if (format == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		if ((len = of_vasprintf(&string, [format cString],
		    arguments)) == -1)
			@throw [OFInvalidFormatException newWithClass: isa];

		@try {
			length = len;

			switch (of_string_check_utf8(string, length)) {
			case 1:
				isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			}

			[self addMemoryToPool: string];
		} @catch (id e) {
			free(string);
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
		size_t len, i;
		va_list argumentsCopy;

		length = [firstComponent cStringLength];

		switch (of_string_check_utf8([firstComponent cString],
		    length)) {
		case 1:
			isUTF8 = YES;
			break;
		case -1:
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Calculate length */
		va_copy(argumentsCopy, arguments);
		while ((component = va_arg(argumentsCopy, OFString*)) != nil) {
			len = [component cStringLength];
			length += 1 + len;

			switch (of_string_check_utf8([component cString],
			    len)) {
			case 1:
				isUTF8 = YES;
				break;
			case -1:
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			}
		}

		string = [self allocMemoryWithSize: length + 1];

		len = [firstComponent cStringLength];
		memcpy(string, [firstComponent cString], len);
		i = len;

		while ((component = va_arg(arguments, OFString*)) != nil) {
			len = [component cStringLength];
			string[i] = OF_PATH_DELIM;
			memcpy(string + i + 1, [component cString], len);
			i += len + 1;
		}

		string[i] = '\0';
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithString: (OFString*)string_
{
	self = [super init];

	@try {
		/* We have no -[dealloc], so this is ok */
		string = (char*)[string_ cString];
		length = [string_ cStringLength];

		switch (of_string_check_utf8(string, length)) {
		case 1:
			isUTF8 = YES;
			break;
		case -1:;
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		if ((string = strdup(string)) == NULL)
			@throw [OFOutOfMemoryException
			     newWithClass: isa
			    requestedSize: length + 1];

		@try {
			[self addMemoryToPool: string];
		} @catch (id e) {
			free(string);
			@throw e;
		}
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
	struct stat s;

	self = [super init];

	@try {
		OFFile *file;

		if (stat([path cString], &s) == -1)
			@throw [OFOpenFileFailedException newWithClass: isa
								  path: path
								  mode: @"rb"];

		file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

		@try {
			tmp = [self allocMemoryWithSize: s.st_size];

			[file readExactlyNBytes: s.st_size
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
			      length: s.st_size];
	[self freeMemory: tmp];

	return self;
}

- initWithContentsOfURL: (OFURL*)URL
{
	return [self initWithContentsOfURL: URL
				  encoding: OF_STRING_ENCODING_UTF_8];
}

- initWithContentsOfURL: (OFURL*)URL
	       encoding: (of_string_encoding_t)encoding
{
	OFAutoreleasePool *pool;
	OFHTTPRequest *request;
	OFHTTPRequestResult *result;
	Class c;

	c = isa;
	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	if ([[URL scheme] isEqual: @"file"]) {
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
		      statusCode: [result statusCode]];

	self = [[c alloc] initWithCString: (char*)[[result data] cArray]
				 encoding: encoding
				   length: [[result data] count]];
	[pool release];
	return self;
}

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	/* FIXME: Maybe cache this in an ivar? */

	return of_string_position_to_index(string, length);
}

- (size_t)cStringLength
{
	return length;
}

- (BOOL)isUTF8
{
	return isUTF8;
}

- (BOOL)isEqual: (id)object
{
	OFString *otherString;

	if (![object isKindOfClass: [OFString class]])
		return NO;

	otherString = (OFString*)object;

	if (strcmp(string, [otherString cString]))
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
	size_t otherLen, minLen;
	int cmp;

	if (![object isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	otherString = (OFString*)object;

	otherLen = [otherString cStringLength];
	minLen = (length > otherLen ? otherLen : length);

	if ((cmp = memcmp(string, [otherString cString], minLen)) == 0) {
		if (length > otherLen)
			return OF_ORDERED_DESCENDING;
		if (length < otherLen)
			return OF_ORDERED_ASCENDING;
		return OF_ORDERED_SAME;
	}

	if (cmp > 0)
		return OF_ORDERED_DESCENDING;
	else
		return OF_ORDERED_ASCENDING;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)otherString;
{
	const char *otherCString;
	size_t i, j, otherLen, minLen;
	int cmp;

	if (![otherString isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	otherCString = [otherString cString];
	otherLen = [otherString cStringLength];

	if (![self isUTF8]) {
		minLen = (length > otherLen ? otherLen : length);

		if ((cmp = memcasecmp(string, otherCString, minLen)) == 0) {
			if (length > otherLen)
				return OF_ORDERED_DESCENDING;
			if (length < otherLen)
				return OF_ORDERED_ASCENDING;
			return OF_ORDERED_SAME;
		}

		if (cmp > 0)
			return OF_ORDERED_DESCENDING;
		else
			return OF_ORDERED_ASCENDING;
	}

	i = j = 0;

	while (i < length && j < otherLen) {
		of_unichar_t c1, c2;
		size_t l1, l2;

		l1 = of_string_utf8_to_unicode(string + i, length - i, &c1);
		l2 = of_string_utf8_to_unicode(otherCString + j, otherLen - j,
		    &c2);

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

	if (length - i > otherLen - j)
		return OF_ORDERED_DESCENDING;
	else if (length - i < otherLen - j)
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_SAME;
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < length; i++)
		OF_HASH_ADD(hash, string[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString*)description
{
	return [[self copy] autorelease];
}

- (of_unichar_t)characterAtIndex: (size_t)index
{
	of_unichar_t c;

	if (![self isUTF8]) {
		if (index >= length)
			@throw [OFOutOfRangeException newWithClass: isa];

		return string[index];
	}

	index = of_string_index_to_position(string, index, length);

	if (index >= length)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (!of_string_utf8_to_unicode(string + index, length - index, &c))
		@throw [OFInvalidEncodingException newWithClass: isa];

	return c;
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)string_
{
	const char *cString = [string_ cString];
	size_t stringLen = [string_ cStringLength];
	size_t i;

	if (stringLen == 0)
		return 0;

	if (stringLen > length)
		return OF_INVALID_INDEX;

	for (i = 0; i <= length - stringLen; i++)
		if (!memcmp(string + i, cString, stringLen))
			return of_string_position_to_index(string, i);

	return OF_INVALID_INDEX;
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)string_
{
	const char *cString = [string_ cString];
	size_t stringLen = [string_ cStringLength];
	size_t i;

	if (stringLen == 0)
		return of_string_position_to_index(string, length);

	if (stringLen > length)
		return OF_INVALID_INDEX;

	for (i = length - stringLen;; i--) {
		if (!memcmp(string + i, cString, stringLen))
			return of_string_position_to_index(string, i);

		/* Did not match and we're at the last char */
		if (i == 0)
			return OF_INVALID_INDEX;
	}
}

- (BOOL)containsString: (OFString*)string_
{
	const char *cString = [string_ cString];
	size_t stringLen = [string_ cStringLength];
	size_t i;

	if (stringLen == 0)
		return YES;

	if (stringLen > length)
		return NO;

	for (i = 0; i <= length - stringLen; i++)
		if (!memcmp(string + i, cString, stringLen))
			return YES;

	return NO;
}

- (OFString*)substringFromIndex: (size_t)start
			toIndex: (size_t)end
{
	if ([self isUTF8]) {
		start = of_string_index_to_position(string, start, length);
		end = of_string_index_to_position(string, end, length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	return [OFString stringWithCString: string + start
				    length: end - start];
}

- (OFString*)substringWithRange: (of_range_t)range
{
	return [self substringFromIndex: range.start
				toIndex: range.start + range.length];
}

- (OFString*)stringByAppendingString: (OFString*)string_
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new appendString: string_];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (OFString*)uppercaseString
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new upper];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (OFString*)lowercaseString
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new lower];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (OFString*)stringByDeletingLeadingWhitespaces
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new deleteLeadingWhitespaces];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (OFString*)stringByDeletingTrailingWhitespaces
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new deleteTrailingWhitespaces];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (OFString*)stringByDeletingLeadingAndTrailingWhitespaces
{
	OFMutableString *new;

	new = [OFMutableString stringWithString: self];
	[new deleteLeadingAndTrailingWhitespaces];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFString class];
	return new;
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	size_t len = [prefix cStringLength];

	if (len > length)
		return NO;

	return !memcmp(string, [prefix cString], len);
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	size_t len = [suffix cStringLength];

	if (len > length)
		return NO;

	return !memcmp(string + (length - len), [suffix cString], len);
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	OFAutoreleasePool *pool;
	OFMutableArray *array;
	const char *delim = [delimiter cString];
	size_t delimLen = [delimiter cStringLength];
	size_t i, last;

	array = [OFMutableArray array];
	pool = [[OFAutoreleasePool alloc] init];

	if (delimLen > length) {
		[array addObject: [[self copy] autorelease]];
		[pool release];

		return array;
	}

	for (i = 0, last = 0; i <= length - delimLen; i++) {
		if (memcmp(string + i, delim, delimLen))
			continue;

		[array addObject: [OFString stringWithCString: string + last
						       length: i - last]];
		i += delimLen - 1;
		last = i + 1;
	}
	[array addObject: [OFString stringWithCString: string + last]];

	[pool release];

	/*
	 * Class swizzle the array to be immutable. We declared the return type
	 * to be OFArray*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	array->isa = [OFArray class];
	return array;
}

- (OFArray*)pathComponents
{
	OFMutableArray *ret;
	OFAutoreleasePool *pool;
	size_t i, last = 0, pathLen = length;

	ret = [OFMutableArray array];

	if (pathLen == 0)
		return ret;

	pool = [[OFAutoreleasePool alloc] init];

#ifndef _WIN32
	if (string[pathLen - 1] == OF_PATH_DELIM)
#else
	if (string[pathLen - 1] == '/' || string[pathLen - 1] == '\\')
#endif
		pathLen--;

	for (i = 0; i < pathLen; i++) {
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIM) {
#else
		if (string[i] == '/' || string[i] == '\\') {
#endif
			[ret addObject:
			    [OFString stringWithCString: string + last
						 length: i - last]];
			last = i + 1;
		}
	}

	[ret addObject: [OFString stringWithCString: string + last
					     length: i - last]];

	[pool release];

	/*
	 * Class swizzle the array to be immutable. We declared the return type
	 * to be OFArray*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFArray class];
	return ret;
}

- (OFString*)lastPathComponent
{
	size_t pathLen = length;
	ssize_t i;

	if (pathLen == 0)
		return @"";

#ifndef _WIN32
	if (string[pathLen - 1] == OF_PATH_DELIM)
#else
	if (string[pathLen - 1] == '/' || string[pathLen - 1] == '\\')
#endif
		pathLen--;

	for (i = pathLen - 1; i >= 0; i--) {
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIM) {
#else
		if (string[i] == '/' || string[i] == '\\') {
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

	return [OFString stringWithCString: string + i
				    length: pathLen - i];
}

- (OFString*)stringByDeletingLastPathComponent;
{
	size_t i, pathLen = length;

	if (pathLen == 0)
		return @"";

#ifndef _WIN32
	if (string[pathLen - 1] == OF_PATH_DELIM)
#else
	if (string[pathLen - 1] == '/' || string[pathLen - 1] == '\\')
#endif
		pathLen--;

	if (pathLen == 0)
		return [OFString stringWithCString: string
					    length: 1];

	for (i = pathLen - 1; i >= 1; i--)
#ifndef _WIN32
		if (string[i] == OF_PATH_DELIM)
#else
		if (string[i] == '/' || string[i] == '\\')
#endif
			return [OFString stringWithCString: string
						    length: i];

#ifndef _WIN32
	if (string[0] == OF_PATH_DELIM)
#else
	if (string[i] == '/' || string[i] == '\\')
#endif
		return [OFString stringWithCString: string
					    length: 1];

	return @".";
}

- (intmax_t)decimalValue
{
	const char *str = string;
	size_t len = length;
	int i = 0;
	intmax_t num = 0;
	BOOL expectWhitespace = NO;

	while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r') {
		str++;
		len--;
	}

	if (str[0] == '-' || str[0] == '+')
		i++;

	for (; i < len; i++) {
		if (expectWhitespace) {
			if (str[i] != ' ' && str[i] != '\t' &&
			    str[i] != '\n' && str[i] != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
			continue;
		}

		if (str[i] >= '0' && str[i] <= '9') {
			if (INTMAX_MAX / 10 < num ||
			    INTMAX_MAX - num * 10 < str[i] - '0')
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			num = (num * 10) + (str[i] - '0');
		} else if (str[i] == ' ' || str[i] == '\t' ||
		    str[i] == '\n' || str[i] == '\r')
			expectWhitespace = YES;
		else
			@throw [OFInvalidFormatException newWithClass: isa];
	}

	if (str[0] == '-')
		num *= -1;

	return num;
}

- (uintmax_t)hexadecimalValue
{
	const char *str = string;
	size_t len = length;
	int i = 0;
	uintmax_t num = 0;
	BOOL expectWhitespace = NO, gotNumber = NO;

	while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r') {
		str++;
		len--;
	}

	if (len == 0)
		return 0;

	if (len >= 2 && str[0] == '0' && str[1] == 'x')
		i = 2;
	else if (len >= 1 && (str[0] == 'x' || str[0] == '$'))
		i = 1;

	for (; i < len; i++) {
		uintmax_t newnum;

		if (expectWhitespace) {
			if (str[i] != ' ' && str[i] != '\t' &&
			    str[i] != '\n' && str[i] != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
			continue;
		}

		if (str[i] >= '0' && str[i] <= '9') {
			newnum = (num << 4) | (str[i] - '0');
			gotNumber = YES;
		} else if (str[i] >= 'A' && str[i] <= 'F') {
			newnum = (num << 4) | (str[i] - 'A' + 10);
			gotNumber = YES;
		} else if (str[i] >= 'a' && str[i] <= 'f') {
			newnum = (num << 4) | (str[i] - 'a' + 10);
			gotNumber = YES;
		} else if (str[i] == 'h' || str[i] == ' ' || str[i] == '\t' ||
		    str[i] == '\n' || str[i] == '\r') {
			expectWhitespace = YES;
			continue;
		} else
			@throw [OFInvalidFormatException newWithClass: isa];

		if (newnum < num)
			@throw [OFOutOfRangeException newWithClass: isa];

		num = newnum;
	}

	if (!gotNumber)
		@throw [OFInvalidFormatException newWithClass: isa];

	return num;
}

- (float)floatValue
{
	const char *str = string;
	char *endPtr;
	float value;

	/* Don't depend on isspace and thus the used locale */
	while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r')
		str++;

	value = strtof(str, &endPtr);

	/* Check if there are any invalid chars left */
	if (endPtr != NULL) {
		for (; *endPtr != '\0'; endPtr++)
			if (*endPtr != ' ' && *endPtr != '\t' &&
			    *endPtr != '\n' && *endPtr != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
	}

	return value;
}

- (double)doubleValue
{
	const char *str = string;
	char *endPtr;
	double value;

	/* Don't depend on isspace and thus the used locale */
	while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r')
		str++;

	value = strtod(str, &endPtr);

	/* Check if there are any invalid chars left */
	if (endPtr != NULL) {
		for (; *endPtr != '\0'; endPtr++)
			if (*endPtr != ' ' && *endPtr != '\t' &&
			    *endPtr != '\n' && *endPtr != '\r')
				@throw [OFInvalidFormatException
				    newWithClass: isa];
	}

	return value;
}

- (of_unichar_t*)unicodeString
{
	of_unichar_t *ret;
	size_t i, j, len;

	len = [self length];

	if ((ret = malloc((len + 1) * sizeof(of_unichar_t))) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa];

	i = j = 0;

	while (i < length) {
		of_unichar_t c;
		size_t cLen;

		cLen = of_string_utf8_to_unicode(string + i, length - 1, &c);

		if (cLen == 0 || c > 0x10FFFF) {
			free(ret);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

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
