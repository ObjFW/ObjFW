/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>
#include <unistd.h>
#include <assert.h>

#import "OFStream.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifdef _WIN32
#include <windows.h>
#endif

static int pagesize = 0;

@implementation OFStream
- init
{
	self = [super init];

	if (isa == [OFStream class])
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	cache = NULL;

#ifndef _WIN32
	if (pagesize == 0)
		if ((pagesize = sysconf(_SC_PAGESIZE)) == -1)
			pagesize = 4096;
#else
	if (pagesize == 0) {
		SYSTEM_INFO si;
		GetSystemInfo(&si);
		pagesize = si.dwPageSize - 1;
	}
#endif

	return self;
}

- (BOOL)atEndOfStream
{
	if (cache != NULL)
		return NO;

	return [self atEndOfStreamWithoutCache];
}

- (BOOL)atEndOfStreamWithoutCache
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	if (cache == NULL)
		return [self readNBytesWithoutCache: size
					 intoBuffer: buf];

	if (size >= cache_len) {
		size_t ret = cache_len;
		memcpy(buf, cache, cache_len);

		[self freeMemory: cache];
		cache = NULL;
		cache_len = 0;

		return ret;
	} else {
		char *tmp = [self allocMemoryWithSize: cache_len - size];
		memcpy(tmp, cache + size, cache_len - size);

		memcpy(buf, cache, size);

		[self freeMemory: cache];
		cache = tmp;
		cache_len -= size;

		return size;
	}
}

- (size_t)readNBytesWithoutCache: (size_t)size
		      intoBuffer: (char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (OFString*)readLine
{
	return [self readLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readLineWithEncoding: (enum of_string_encoding)encoding
{
	size_t i, len, ret_len;
	char *ret_c, *tmp, *tmp2;
	OFString *ret;

	/* Look if there's a line or \0 in our cache */
	if (cache != NULL) {
		for (i = 0; i < cache_len; i++) {
			if (OF_UNLIKELY(cache[i] == '\n' ||
			    cache[i] == '\0')) {
				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: i];

				tmp = [self allocMemoryWithSize: cache_len -
								 i - 1];
				memcpy(tmp, cache + i + 1, cache_len - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cache_len -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	tmp = [self allocMemoryWithSize: pagesize];

	@try {
		for (;;) {
			if ([self atEndOfStreamWithoutCache]) {
				if (cache == NULL)
					return nil;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: cache_len];

				[self freeMemory: cache];
				cache = NULL;
				cache_len = 0;

				return ret;
			}

			len = [self readNBytesWithoutCache: pagesize
						intoBuffer: tmp];

			/* Look if there's a newline or \0 */
			for (i = 0; i < len; i++) {
				if (OF_UNLIKELY(tmp[i] == '\n' ||
				    tmp[i] == '\0')) {
					ret_len = cache_len + i;
					ret_c = [self
					    allocMemoryWithSize: ret_len];

					if (cache != NULL)
						memcpy(ret_c, cache, cache_len);
					memcpy(ret_c + cache_len, tmp, i);

					@try {
						ret = [OFString
						    stringWithCString: ret_c
							     encoding: encoding
							       length: ret_len];
					} @finally {
						[self freeMemory: ret_c];
					}

					if (i < len) {
						tmp2 = [self
						    allocMemoryWithSize: len -
									 i - 1];
						memcpy(tmp2, tmp + i + 1,
						    len - i - 1);

						[self freeMemory: cache];
						cache = tmp2;
						cache_len = len - i - 1;
					} else {
						[self freeMemory: cache];
						cache = NULL;
						cache_len = 0;
					}

					return ret;
				}
			}

			/* There was no newline or \0 */
			cache = [self resizeMemory: cache
					    toSize: cache_len + len];

			/*
			 * It's possible that cache_len + len is 0 and thus
			 * cache was set to NULL by resizeMemory:toSize:.
			 */
			if (cache != NULL)
				memcpy(cache + cache_len, tmp, len);

			cache_len += len;
		}
	} @finally {
		[self freeMemory: tmp];
	}

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)writeString: (OFString*)str
{
	return [self writeNBytes: [str cStringLength]
		      fromBuffer: [str cString]];
}

- close
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
