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

#include <string.h>
#include <unistd.h>

#import "OFStream.h"
#import "OFExceptions.h"
#import "OFMacros.h"

extern int getpagesize(void);

@implementation OFStream
- init
{
	self = [super init];

	cache = NULL;
	cache_len = 0;

	return self;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- (char*)readLine
{
	size_t i, len;
	char *ret, *tmp, *tmp2;

	/* Look if there's a line or \0 in our cache */
	if (cache != NULL) {
		for (i = 0; i < cache_len; i++) {
			if (OF_UNLIKELY(cache[i] == '\n' ||
			    cache[i] == '\0')) {
				ret = [self allocWithSize: i + 1];
				memcpy(ret, cache, i);
				ret[i] = '\0';

				@try {
					tmp = [self allocWithSize: cache_len -
								   i - 1];
				} @catch (OFException *e) {
					[self freeMem: ret];
					@throw e;
				}
				memcpy(tmp, cache + i + 1, cache_len - i - 1);

				[self freeMem: cache];
				cache = tmp;
				cache_len = cache_len - i - 1;

				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	tmp = [self allocWithSize: getpagesize()];

	for (;;) {
		@try {
			len = [self readNBytes: getpagesize() - 1
				    intoBuffer: tmp];
		} @catch (OFException *e) {
			[self freeMem: tmp];
			@throw e;
		}

		/* Look if there's a newline or \0 */
		for (i = 0; i < len; i++) {
			if (OF_UNLIKELY(tmp[i] == '\n' || tmp[i] == '\0')) {
				@try {
					ret = [self
					    allocWithSize: cache_len + i + 1];
				} @catch (OFException *e) {
					[self freeMem: tmp];
					@throw e;
				}
				if (cache != NULL)
					memcpy(ret, cache, cache_len);
				memcpy(ret + cache_len, tmp, i);
				ret[i] = '\0';

				if (i < len) {
					@try {
						tmp2 = [self
						    allocWithSize: len - i - 1];
					} @catch (OFException *e) {
						[self freeMem: ret];
						[self freeMem: tmp];
						@throw e;
					}
					memcpy(tmp2, tmp + i + 1, len - i - 1);

					if (cache != NULL)
						[self freeMem: cache];
					cache = tmp2;
					cache_len = len - i - 1;
				} else {
					if (cache != NULL)
						[self freeMem: cache];
					cache = NULL;
					cache_len = 0;
				}

				[self freeMem: tmp];
				return ret;
			}
		}

		/* There was no newline or \0 */
		@try {
			cache = [self resizeMem: cache
					 toSize: cache_len + len];
		} @catch (OFException *e) {
			[self freeMem: tmp];
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

- (size_t)writeCString: (const char*)str
{
	return [self writeNBytes: strlen(str)
		      fromBuffer: str];
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
		[self freeMem: cache];

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
