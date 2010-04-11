/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#define _GNU_SOURCE
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>
#ifdef HAVE_MADVISE
# include <sys/mman.h>
#else
# define madvise(addr, len, advise)
#endif

#import "OFString.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

#import "asprintf.h"
#import "unicode.h"

#ifndef _WIN32
# define PATH_DELIM '/'
#else
# define PATH_DELIM '\\'
#endif

extern const uint16_t of_iso_8859_15[256];
extern const uint16_t of_windows_1252[256];

/* References for static linking */
void _references_to_categories_of_OFString()
{
	_OFHashing_reference = 1;
	_OFURLEncoding_reference = 1;
	_OFXMLElement_reference = 1;
	_OFXMLParser_reference = 1;
};

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
				return SIZE_MAX;

	return idx;
}

@implementation OFString
+ string
{
	return [[[self alloc] init] autorelease];
}

+ stringWithCString: (const char*)str
{
	return [[[self alloc] initWithCString: str] autorelease];
}

+ stringWithCString: (const char*)str
	   encoding: (enum of_string_encoding)encoding
{
	return [[[self alloc] initWithCString: str
				     encoding: encoding] autorelease];
}

+ stringWithCString: (const char*)str
	   encoding: (enum of_string_encoding)encoding
	     length: (size_t)len
{
	return [[[self alloc] initWithCString: str
				     encoding: encoding
				       length: len] autorelease];
}

+ stringWithCString: (const char*)str
	     length: (size_t)len
{
	return [[[self alloc] initWithCString: str
				       length: len] autorelease];
}

+ stringWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [[[self alloc] initWithFormat: fmt
				  arguments: args] autorelease];
	va_end(args);

	return ret;
}

+ stringWithPath: (OFString*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithPath: first
				arguments: args] autorelease];
	va_end(args);

	return ret;
}

+ stringWithString: (OFString*)str
{
	return [[[self alloc] initWithString: str] autorelease];
}

+ stringWithContentsOfFile: (OFString*)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ stringWithContentsOfFile: (OFString*)path
		  encoding: (enum of_string_encoding)encoding
{
	return [[[self alloc] initWithContentsOfFile: path
					    encoding: encoding] autorelease];
}

- init
{
	[super init];

	string = NULL;

	return self;
}

- initWithCString: (const char*)str
{
	return [self initWithCString: str
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: strlen(str)];
}

- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding
{
	return [self initWithCString: str
			    encoding: encoding
			      length: strlen(str)];
}

- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding
	   length: (size_t)len
{
	size_t i, j;

	self = [super init];

	length = len;

	@try {
		string = [self allocMemoryWithSize: length + 1];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here.
		 * Compiler bug? Anyway, [self dealloc] will do here as we
		 * don't reimplement dealloc.
		 */
		[self dealloc];
		@throw e;
	}

	switch (encoding) {
	case OF_STRING_ENCODING_UTF_8:
		switch (of_string_check_utf8(str, length)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:;
			/*
			 * We can't use [super dealloc] on OS X here.
			 * Compiler bug? Anyway, [self dealloc] will do here as
			 * we don't reimplement dealloc.
			 */
			Class c = isa;
			[self dealloc];
			@throw [OFInvalidEncodingException newWithClass: c];
		}

		memcpy(string, str, length);
		string[length] = 0;

		break;
	case OF_STRING_ENCODING_ISO_8859_1:
	case OF_STRING_ENCODING_ISO_8859_15:
	case OF_STRING_ENCODING_WINDOWS_1252:
		for (i = j = 0; i < len; i++) {
			if (!(str[i] & 0x80))
				string[j++] = str[i];
			else {
				char buf[4];
				of_unichar_t chr;
				size_t chr_bytes;

				switch (encoding) {
				case OF_STRING_ENCODING_ISO_8859_1:
					chr = (uint8_t)str[i];
					break;
				case OF_STRING_ENCODING_ISO_8859_15:
					chr = of_iso_8859_15[(uint8_t)str[i]];
					break;
				case OF_STRING_ENCODING_WINDOWS_1252:
					chr = of_windows_1252[(uint8_t)str[i]];
					break;
				default:;
					/*
					 * We can't use [super dealloc] on OS X
					 * here. Compiler bug? Anyway,
					 * [self dealloc] will do here as we
					 * don't reimplement dealloc.
					 */
					Class c = isa;
					[self dealloc];
					@throw [OFInvalidEncodingException
					    newWithClass: c];
				}

				if (chr == 0xFFFD) {
					/*
					 * We can't use [super dealloc] on OS X
					 * here. Compiler bug? Anyway,
					 * [self dealloc] will do here as we
					 * don't reimplement dealloc.
					 */
					Class c = isa;
					[self dealloc];
					@throw [OFInvalidEncodingException
					    newWithClass: c];
				}

				is_utf8 = YES;
				chr_bytes = of_string_unicode_to_utf8(chr, buf);

				if (chr_bytes == 0) {
					/*
					 * We can't use [super dealloc] on OS X
					 * here. Compiler bug? Anyway,
					 * [self dealloc] will do here as we
					 * don't reimplement dealloc.
					 */
					Class c = isa;
					[self dealloc];
					@throw [OFInvalidEncodingException
					    newWithClass: c];
				}

				length += chr_bytes - 1;
				@try {
					string = [self resizeMemory: string
							     toSize: length +
								     1];
				} @catch (OFException *e) {
					/*
					 * We can't use [super dealloc] on OS X
					 * here. Compiler bug? Anyway,
					 * [self dealloc] will do here as we
					 * don't reimplement dealloc.
					 */
					[self dealloc];
					@throw e;
				}

				memcpy(string + j, buf, chr_bytes);
				j += chr_bytes;
			}
		}

		string[length] = 0;

		break;
	default:;
		/*
		 * We can't use [super dealloc] on OS X here.
		 * Compiler bug? Anyway, [self dealloc] will do here as we
		 * don't reimplement dealloc.
		 */
		Class c = isa;
		[self dealloc];
		@throw [OFInvalidEncodingException newWithClass: c];
	}

	return self;
}

- initWithCString: (const char*)str
	   length: (size_t)len
{
	return [self initWithCString: str
			    encoding: OF_STRING_ENCODING_UTF_8
			      length: len];
}

- initWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self initWithFormat: fmt
			 arguments: args];
	va_end(args);

	return ret;
}

- initWithFormat: (OFString*)fmt
       arguments: (va_list)args
{
	int t;

	self = [super init];

	if (fmt == nil) {
		Class c = isa;
		[super dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	if ((t = vasprintf(&string, [fmt cString], args)) == -1) {
		Class c = isa;
		[super dealloc];

		/*
		 * This is only the most likely error to happen. Unfortunately,
		 * there is no good way to check what really happened.
		 */
		@throw [OFOutOfMemoryException newWithClass: c];
	}
	length = t;

	switch (of_string_check_utf8(string, length)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:;
		Class c = isa;
		free(string);
		[super dealloc];
		@throw [OFInvalidEncodingException newWithClass: c];
	}

	@try {
		[self addMemoryToPool: string];
	} @catch (OFException *e) {
		free(string);
		@throw e;
	}

	return self;
}

- initWithPath: (OFString*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithPath: first
		       arguments: args];
	va_end(args);

	return ret;
}

- initWithPath: (OFString*)first
     arguments: (va_list)args
{
	OFString *component;
	size_t len, i;
	va_list args2;
	Class c;

	self = [super init];

	len = [first cStringLength];
	switch (of_string_check_utf8([first cString], len)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		c = isa;
		[self dealloc];
		@throw [OFInvalidEncodingException newWithClass: c];
	}
	length += len;

	va_copy(args2, args);
	while ((component = va_arg(args2, OFString*)) != nil) {
		len = [component cStringLength];
		length += 1 + len;

		switch (of_string_check_utf8([component cString], len)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:
			c = isa;
			[self dealloc];
			@throw [OFInvalidEncodingException newWithClass: c];
		}
	}

	@try {
		string = [self allocMemoryWithSize: length + 1];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	len = [first cStringLength];
	memcpy(string, [first cString], len);
	i = len;

	while ((component = va_arg(args, OFString*)) != nil) {
		len = [component length];
		string[i] = PATH_DELIM;
		memcpy(string + i + 1, [component cString], len);
		i += len + 1;
	}

	string[i] = '\0';

	return self;
}

- initWithString: (OFString*)str
{
	self = [super init];

	string = (char*)[str cString];
	length = [str cStringLength];

	switch (of_string_check_utf8(string, length)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:;
		Class c = isa;
		[self dealloc];
		@throw [OFInvalidEncodingException newWithClass: c];
	}

	if ((string = strdup(string)) == NULL) {
		Class c = isa;
		[self dealloc];
		@throw [OFOutOfMemoryException newWithClass: c
						       size: length + 1];
	}

	@try {
		[self addMemoryToPool: string];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here.
		 * Compiler bug? Anyway, [self dealloc] will do here as we
		 * don't reimplement dealloc.
		 */
		free(string);
		[self dealloc];
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
		encoding: (enum of_string_encoding)encoding
{
	OFFile *file = nil;
	char *tmp;
	struct stat s;

	if (stat([path cString], &s) == -1) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	if ((tmp = malloc(s.st_size)) == NULL) {
		Class c = isa;
		[super dealloc];
		@throw [OFOutOfMemoryException newWithClass: c
						       size: s.st_size];
	}

	@try {
		file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];
		[file readExactlyNBytes: s.st_size
			     intoBuffer: tmp];
	} @catch (OFException *e) {
		free(tmp);
		[super dealloc];
		@throw e;
	} @finally {
		[file release];
	}

	@try {
		self = [self initWithCString: tmp
				    encoding: encoding
				      length: s.st_size];
	} @finally {
		free(tmp);
	}

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

- (BOOL)isEqual: (OFObject*)obj
{
	if (![obj isKindOfClass: [OFString class]])
		return NO;
	if (strcmp(string, [(OFString*)obj cString]))
		return NO;

	return YES;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (of_comparison_result_t)compare: (OFString*)str
{
	int cmp;
	size_t str_len, min_len;

	if (![str isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	str_len = [str cStringLength];
	min_len = (length > str_len ? str_len : length);

	if ((cmp = memcmp(string, [str cString], min_len)) == 0) {
		if (length > str_len)
			return OF_ORDERED_DESCENDING;
		if (length < str_len)
			return OF_ORDERED_ASCENDING;
		return OF_ORDERED_SAME;
	}

	if (cmp > 0)
		return OF_ORDERED_DESCENDING;
	else
		return OF_ORDERED_ASCENDING;
}

- (of_comparison_result_t)caseInsensitiveCompare: (OFString*)str
{
	const char *str_cstr;
	size_t i, j, str_len;

	if (![str isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	str_cstr = [str cString];
	str_len = [str cStringLength];

	i = j = 0;

	while (i < length && j < str_len) {
		of_unichar_t c1, c2;
		size_t l1, l2;

		l1 = of_string_utf8_to_unicode(string + i, length - i, &c1);
		l2 = of_string_utf8_to_unicode(str_cstr + j, str_len - j, &c2);

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

	if (length - i > str_len - j)
		return OF_ORDERED_DESCENDING;
	else if (length - i < str_len - j)
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

- (of_unichar_t)characterAtIndex: (size_t)index
{
	of_unichar_t c;

	index = of_string_index_to_position(string, index, length);

	if (index >= length)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (!of_string_utf8_to_unicode(string + index, length - index, &c))
		@throw [OFInvalidEncodingException newWithClass: isa];

	return c;
}

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)str
{
	const char *str_c = [str cString];
	size_t str_len = [str cStringLength];
	size_t i;

	if (str_len == 0)
		return 0;

	if (str_len > length)
		return SIZE_MAX;

	for (i = 0; i <= length - str_len; i++)
		if (!memcmp(string + i, str_c, str_len))
			return of_string_position_to_index(string, i);

	return SIZE_MAX;
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)str
{
	const char *str_c = [str cString];
	size_t str_len = [str cStringLength];
	size_t i;

	if (str_len == 0)
		return of_string_position_to_index(string, length);

	if (str_len > length)
		return SIZE_MAX;

	for (i = length - str_len;; i--) {
		if (!memcmp(string + i, str_c, str_len))
			return of_string_position_to_index(string, i);

		/* Did not match and we're at the last char */
		if (i == 0)
			return SIZE_MAX;
	}
}

- (OFString*)substringFromIndex: (size_t)start
			toIndex: (size_t)end
{
	start = of_string_index_to_position(string, start, length);
	end = of_string_index_to_position(string, end, length);

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

- (OFString*)stringByAppendingString: (OFString*)str
{
	return [[OFMutableString stringWithString: self] appendString: str];
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	size_t len = [prefix cStringLength];

	if (len > length)
		return NO;

	return (memcmp(string, [prefix cString], len) ? NO : YES);
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	size_t len = [suffix cStringLength];

	if (len > length)
		return NO;

	return (memcmp(string + (length - len), [suffix cString], len)
	    ? NO : YES);
}

- (OFArray*)componentsSeparatedByString: (OFString*)delimiter
{
	OFAutoreleasePool *pool;
	OFMutableArray *array;
	const char *delim = [delimiter cString];
	size_t delim_len = [delimiter cStringLength];
	size_t i, last;

	array = [OFMutableArray array];
	pool = [[OFAutoreleasePool alloc] init];

	if (delim_len > length) {
		[array addObject: [[self copy] autorelease]];
		[pool release];

		return array;
	}

	for (i = 0, last = 0; i <= length - delim_len; i++) {
		if (memcmp(string + i, delim, delim_len))
			continue;

		[array addObject: [OFString stringWithCString: string + last
						       length: i - last]];
		i += delim_len - 1;
		last = i + 1;
	}
	[array addObject: [OFString stringWithCString: string + last]];

	[pool release];

	return array;
}

- (intmax_t)decimalValueAsInteger
{
	int i = 0;
	intmax_t num = 0;

	if (string[0] == '-')
		i++;

	for (; i < length; i++) {
		if (string[i] >= '0' && string[i] <= '9') {
			intmax_t newnum = (num * 10) + (string[i] - '0');

			if (newnum < num)
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			num = newnum;
		} else
			@throw [OFInvalidEncodingException newWithClass: isa];
	}

	if (string[0] == '-')
		num *= -1;

	return num;
}

- (uintmax_t)hexadecimalValueAsInteger
{
	int i = 0;
	uintmax_t num = 0;

	if (length == 0)
		return 0;

	if (length >= 2 && string[0] == '0' && string[1] == 'x')
		i = 2;
	else if (length >= 1 && (string[0] == 'x' || string[0] == '$'))
		i = 1;

	if (i == length)
		@throw [OFInvalidEncodingException newWithClass: isa];

	for (; i < length; i++) {
		uintmax_t newnum;

		if (string[i] >= '0' && string[i] <= '9')
			newnum = (num << 4) | (string[i] - '0');
		else if (string[i] >= 'A' && string[i] <= 'F')
			newnum = (num << 4) | (string[i] - 'A' + 10);
		else if (string[i] >= 'a' && string[i] <= 'f')
			newnum = (num << 4) | (string[i] - 'a' + 10);
		else
			@throw [OFInvalidEncodingException newWithClass: isa];

		if (newnum < num)
			@throw [OFOutOfRangeException newWithClass: isa];

		num = newnum;
	}

	return num;
}
@end
