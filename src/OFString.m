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

#import "config.h"

#define _GNU_SOURCE
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_SYS_MMAN_H
#include <sys/mman.h>
#else
#define madvise(addr, len, advise)
#endif

#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "OFURLEncoding.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifndef HAVE_ASPRINTF
#import "asprintf.h"
#endif

/* Reference for static linking */
void _reference_to_OFURLEncoding_in_OFString()
{
	_OFURLEncoding_reference = 1;
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

@implementation OFString
+ string
{
	return [[[self alloc] init] autorelease];
}

+ stringWithCString: (const char*)str
{
	return [[[self alloc] initWithCString: str] autorelease];
}

+ stringWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [[[self alloc] initWithFormat: fmt
			       andArguments: args] autorelease];
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
				@throw [OFInvalidEncodingException
					newWithClass: c];
		}

		@try {
			string = [self allocWithSize: length + 1];
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

- initWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self initWithFormat: fmt
		      andArguments: args];
	va_end(args);

	return ret;
}

- initWithFormat: (OFString*)fmt
    andArguments: (va_list)args
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
		[self addItemToMemoryPool: string];
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
		[self addItemToMemoryPool: string];
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

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableString alloc] initWithString: self];
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFString class]])
		return NO;
	if (strcmp(string, [obj cString]))
		return NO;

	return YES;
}

- (int)compare: (id)obj
{
	if (![obj isKindOf: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

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

- setToCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- append: (OFString*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendWithFormat: (OFString*)fmt, ...
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendWithFormat: (OFString*)fmt
      andArguments: (va_list)args
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- reverse
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- upper
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- lower
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- replaceOccurrencesOfString: (OFString*)str
		  withString: (OFString*)repl
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- (OFArray*)splitWithDelimiter: (OFString*)delimiter
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *array = nil;
	OFString *str;
	const char *delim = [delimiter cString];
	size_t delim_len = [delimiter length];
	size_t i, last;

	array = [OFMutableArray array];

	if (delim_len > length) {
		str = [self copy];

		@try {
			[array addObject: str];
		} @finally {
			[str release];
		}

		[array retain];
		[pool release];

		return array;
	}

	for (i = 0, last = 0; i <= length - delim_len; i++) {
		char *tmp;

		if (memcmp(string + i, delim, delim_len))
			continue;

		/*
		 * We can't use [self allocWithSize:] here as self might be a
		 * @""-literal.
		 */
		if ((tmp = malloc(i - last + 1)) == NULL)
			@throw [OFNoMemException newWithClass: isa
						      andSize: i - last + 1];
		memcpy(tmp, string + last, i - last);
		tmp[i - last] = '\0';
		@try {
			str = [OFString stringWithCString: tmp];
		} @finally {
			free(tmp);
		}

		[array addObject: str];
		[array retain];
		[pool releaseObjects];

		i += delim_len - 1;
		last = i + 1;
	}
	[array addObject: [OFString stringWithCString: string + last]];

	[array retain];
	[pool release];

	return array;
}
@end
