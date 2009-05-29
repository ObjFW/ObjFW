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

#include <string.h>
#include <unistd.h>

#import "OFStream.h"
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

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- (OFString*)readLine
{
	size_t i, len;
	char *ret_c, *tmp, *tmp2;
	OFString *ret;

	/* Look if there's a line or \0 in our cache */
	if (cache != NULL) {
		for (i = 0; i < cache_len; i++) {
			if (OF_UNLIKELY(cache[i] == '\n' ||
			    cache[i] == '\0')) {
				ret_c = [self allocMemoryWithSize: i + 1];
				memcpy(ret_c, cache, i);
				ret_c[i] = '\0';

				@try {
					tmp = [self
					    allocMemoryWithSize: cache_len -
								 i - 1];
				} @catch (OFException *e) {
					[self freeMemory: ret_c];
					@throw e;
				}
				memcpy(tmp, cache + i + 1, cache_len - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cache_len = cache_len - i - 1;

				@try {
					ret = [OFString
					    stringWithCString: ret_c];
				} @finally {
					[self freeMemory: ret_c];
				}
				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	tmp = [self allocMemoryWithSize: pagesize];

	for (;;) {
		@try {
			len = [self readNBytes: pagesize - 1
				    intoBuffer: tmp];
		} @catch (OFException *e) {
			[self freeMemory: tmp];
			@throw e;
		}

		/* Look if there's a newline or \0 */
		for (i = 0; i < len; i++) {
			if (OF_UNLIKELY(tmp[i] == '\n' || tmp[i] == '\0')) {
				@try {
					ret_c = [self
					    allocMemoryWithSize: cache_len +
								 i + 1];
				} @catch (OFException *e) {
					[self freeMemory: tmp];
					@throw e;
				}
				if (cache != NULL)
					memcpy(ret_c, cache, cache_len);
				memcpy(ret_c + cache_len, tmp, i);
				ret_c[i] = '\0';

				if (i < len) {
					@try {
						tmp2 = [self
						    allocMemoryWithSize: len -
									 i - 1];
					} @catch (OFException *e) {
						[self freeMemory: ret_c];
						[self freeMemory: tmp];
						@throw e;
					}
					memcpy(tmp2, tmp + i + 1, len - i - 1);

					if (cache != NULL)
						[self freeMemory: cache];
					cache = tmp2;
					cache_len = len - i - 1;
				} else {
					if (cache != NULL)
						[self freeMemory: cache];
					cache = NULL;
					cache_len = 0;
				}

				[self freeMemory: tmp];
				@try {
					ret = [OFString
					    stringWithCString: ret_c];
				} @finally {
					[self freeMemory: ret_c];
				}
				return ret;
			}
		}

		/* There was no newline or \0 */
		@try {
			cache = [self resizeMemory: cache
					    toSize: cache_len + len];
		} @catch (OFException *e) {
			[self freeMemory: tmp];
			@throw e;
		}
		memcpy(cache + cache_len, tmp, len);
		cache_len += len;
	}
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- (size_t)writeString: (OFString*)str
{
	return [self writeNBytes: [str length]
		      fromBuffer: [str cString]];
}

- (size_t)getCache: (char**)ptr
{
	if (ptr != NULL)
		*ptr = cache;

	return cache_len;
}

- clearCache
{
	if (cache != NULL)
		[self freeMemory: cache];

	cache = NULL;
	cache_len = 0;

	return self;
}

- close
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}
@end
