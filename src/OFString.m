/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#define _GNU_SOURCE
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_MADVISE
#include <sys/mman.h>
#else
#define madvise(addr, len, advise)
#endif

#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#import "asprintf.h"

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
of_string_unicode_to_utf8(uint32_t c, char *buf)
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

+ stringWithString: (OFString*)str
{
	return [[[self alloc] initWithString: str] autorelease];
}

- init
{
	[super init];

	string = NULL;

	return self;
}

- initWithCString: (const char*)str
{
	Class c;

	self = [super init];

	if (str != NULL) {
		length = strlen(str);

		switch (of_string_check_utf8(str, length)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:
			c = isa;
			[super dealloc];
			@throw [OFInvalidEncodingException newWithClass: c];
		}

		@try {
			string = [self allocMemoryWithSize: length + 1];
		} @catch (OFException *e) {
			/*
			 * We can't use [super dealloc] on OS X here.
			 * Compiler bug? Anyway, [self dealloc] will do here as
			 * we don't reimplement dealloc.
			 */
			[self dealloc];
			@throw e;
		}
		memcpy(string, str, length + 1);
	}

	return self;
}

- initWithCString: (const char*)str
	   length: (size_t)len
{
	Class c;

	self = [super init];

	if (len > strlen(str)) {
		c = isa;
		[super dealloc];
		@throw [OFOutOfRangeException newWithClass: c];
	}

	length = len;

	switch (of_string_check_utf8(str, length)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		c = isa;
		[super dealloc];
		@throw [OFInvalidEncodingException newWithClass: c];
	}

	@try {
		string = [self allocMemoryWithSize: length + 1];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here.
		 * Compiler bug? Anyway, [self dealloc] will do here as
		 * we don't reimplement dealloc.
		 */
		[self dealloc];
		@throw e;
	}
	memcpy(string, str, length);
	string[length] = 0;

	return self;
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
	Class c;

	self = [super init];

	if (fmt == NULL) {
		c = isa;
		[super dealloc];
		@throw [OFInvalidFormatException newWithClass: c];
	}

	if ((t = vasprintf(&string, [fmt cString], args)) == -1) {
		c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}
	length = t;

	switch (of_string_check_utf8(string, length)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:
			free(string);
			c = isa;
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

- initWithString: (OFString*)str
{
	self = [super init];

	string = strdup([str cString]);
	length = [str length];

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

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOfClass: [OFString class]])
		return NO;
	if (strcmp(string, [obj cString]))
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

- (int)compare: (id)obj
{
	if (![obj isKindOfClass: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	return strcmp(string, [obj cString]);
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

- (size_t)indexOfFirstOccurrenceOfString: (OFString*)str
{
	const char *str_c = [str cString];
	size_t str_len = [str length];
	size_t i;

	if (str_len == 0)
		return 0;

	if (str_len > length)
		return SIZE_MAX;

	for (i = 0; i <= length - str_len; i++)
		if (!memcmp(string + i, str_c, str_len))
			return i;

	return SIZE_MAX;
}

- (size_t)indexOfLastOccurrenceOfString: (OFString*)str
{
	const char *str_c = [str cString];
	size_t str_len = [str length];
	size_t i;

	if (str_len == 0)
		return length;

	if (str_len > length)
		return SIZE_MAX;

	for (i = length - str_len;; i--) {
		if (!memcmp(string + i, str_c, str_len))
			return i;

		/* Did not match and we're at the last char */
		if (i == 0)
			return SIZE_MAX;
	}
}

- (OFString*)substringFromIndex: (size_t)start
			toIndex: (size_t)end
{
	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	return [OFString stringWithCString: string + start
				    length: end - start];
}

- (OFString*)stringByAppendingString: (OFString*)str
{
	return [[OFMutableString stringWithString: self] appendString: str];
}

- (BOOL)hasPrefix: (OFString*)prefix
{
	size_t len = [prefix length];

	if (len > length)
		return NO;

	return (memcmp(string, [prefix cString], len) ? NO : YES);
}

- (BOOL)hasSuffix: (OFString*)suffix
{
	size_t len = [suffix length];

	if (len > length)
		return NO;

	return (memcmp(string + (length - len), [suffix cString], len)
	    ? NO : YES);
}

- (OFArray*)splitWithDelimiter: (OFString*)delimiter
{
	OFAutoreleasePool *pool;
	OFArray *array;
	const char *delim = [delimiter cString];
	size_t delim_len = [delimiter length];
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

- setToCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendCString: (const char*)str
     withLength: (size_t)len
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendCStringWithoutUTF8Checking: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendCStringWithoutUTF8Checking: (const char*)str
			    length: (size_t)len
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendString: (OFString*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendWithFormat: (OFString*)fmt, ...
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- appendWithFormat: (OFString*)fmt
	 arguments: (va_list)args
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- reverse
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- upper
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- lower
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- replaceOccurrencesOfString: (OFString*)str
		  withString: (OFString*)repl
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- removeLeadingWhitespaces
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- removeTrailingWhitespaces
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- removeLeadingAndTrailingWhitespaces
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
