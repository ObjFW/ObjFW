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

#include <assert.h>

#import "OFStream.h"
#import "OFString.h"
#import "OFDataArray.h"
#import "OFExceptions.h"
#import "macros.h"

#import "asprintf.h"

@implementation OFStream
- init
{
	self = [super init];

	if (isa == [OFStream class])
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	cache = NULL;
	wcache = NULL;

	return self;
}

- (BOOL)_atEndOfStream
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)_readNBytes: (size_t)size
	   intoBuffer: (char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)_writeNBytes: (size_t)size
	    fromBuffer: (const char*)buf
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (BOOL)atEndOfStream
{
	if (cache != NULL)
		return NO;

	return [self _atEndOfStream];
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	if (cache == NULL)
		return [self _readNBytes: size
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

- (void)readExactlyNBytes: (size_t)size
	       intoBuffer: (char*)buf
{
	size_t len = 0;

	while (len < size)
		len += [self readNBytes: size - len
			     intoBuffer: buf + len];
}

- (uint8_t)readInt8
{
	uint8_t ret;

	[self readExactlyNBytes: 1
		     intoBuffer: (char*)&ret];

	return ret;
}

- (uint16_t)readBigEndianInt16
{
	uint16_t ret;

	[self readExactlyNBytes: 2
		     intoBuffer: (char*)&ret];

	return OF_BSWAP16_IF_LE(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return OF_BSWAP32_IF_LE(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return OF_BSWAP64_IF_LE(ret);
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;

	[self readExactlyNBytes: 2
		     intoBuffer: (char*)&ret];

	return OF_BSWAP16_IF_BE(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return OF_BSWAP32_IF_BE(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return OF_BSWAP64_IF_BE(ret);
}

- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemsize
				andNItems: (size_t)nitems
{
	OFDataArray *da;
	char *tmp;

	da = [OFDataArray dataArrayWithItemSize: itemsize];
	tmp = [self allocMemoryForNItems: nitems
				withSize: itemsize];

	@try {
		[self readExactlyNBytes: nitems * itemsize
			     intoBuffer: tmp];

		[da addNItems: nitems
		   fromCArray: tmp];
	} @finally {
		[self freeMemory: tmp];
	}

	return da;
}

- (OFDataArray*)readDataArrayTillEndOfStream
{
	OFDataArray *a;
	char *buf;

	a = [OFDataArray dataArrayWithItemSize: 1];
	buf = [self allocMemoryWithSize: of_pagesize];

	@try {
		while (![self atEndOfStream]) {
			size_t size;

			size = [self readNBytes: of_pagesize
				     intoBuffer: buf];
			[a addNItems: size
			  fromCArray: buf];
		}
	} @finally {
		[self freeMemory: buf];
	}

	return a;
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
				ret_len = i;

				if (i > 0 && cache[i - 1] == '\r')
					ret_len--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: ret_len];

				tmp = [self allocMemoryWithSize: cache_len -
								 i - 1];
				if (tmp != NULL)
					memcpy(tmp, cache + i + 1,
					    cache_len - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cache_len -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	tmp = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _atEndOfStream]) {
				if (cache == NULL)
					return nil;

				ret_len = cache_len;

				if (ret_len > 0 && cache[ret_len - 1] == '\r')
					ret_len--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: ret_len];

				[self freeMemory: cache];
				cache = NULL;
				cache_len = 0;

				return ret;
			}

			len = [self _readNBytes: of_pagesize
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

					if (ret_len > 0 &&
					    ret_c[ret_len - 1] == '\r')
						ret_len--;

					@try {
						ret = [OFString
						    stringWithCString: ret_c
							     encoding: encoding
							       length: ret_len];
					} @finally {
						[self freeMemory: ret_c];
					}

					tmp2 = [self
					    allocMemoryWithSize: len - i - 1];
					if (tmp2 != NULL)
						memcpy(tmp2, tmp + i + 1,
						    len - i - 1);

					[self freeMemory: cache];
					cache = tmp2;
					cache_len = len - i - 1;

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

- (OFString*)readTillDelimiter: (OFString*)delimiter
{
	return [self readTillDelimiter: delimiter
			  withEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readTillDelimiter: (OFString*)delimiter
		  withEncoding: (enum of_string_encoding)encoding
{
	const char *delim;
	size_t i, j, delim_len, len, ret_len;
	char *ret_c, *tmp, *tmp2;
	OFString *ret;

	/* FIXME: Convert delimiter to specified charset */
	delim = [delimiter cString];
	delim_len = [delimiter cStringLength];
	j = 0;

	if (delim_len == 0)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	/* Look if there's something in our cache */
	if (cache != NULL) {
		for (i = 0; i < cache_len; i++) {
			if (cache[i] != delim[j++])
				j = 0;

			if (j == delim_len || cache[i] == '\0') {
				if (cache[i] == '\0')
					delim_len = 1;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: i + 1 -
								   delim_len];

				tmp = [self allocMemoryWithSize: cache_len - i -
								 1];
				if (tmp != NULL)
					memcpy(tmp, cache + i + 1,
					    cache_len - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cache_len -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get the delimiter or \0 */
	tmp = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _atEndOfStream]) {
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

			len = [self _readNBytes: of_pagesize
				     intoBuffer: tmp];

			/* Look if there's the delimiter or \0 */
			for (i = 0; i < len; i++) {
				if (tmp[i] != delim[j++])
					j = 0;

				if (j == delim_len || tmp[i] == '\0') {
					if (tmp[i] == '\0')
						delim_len = 1;

					ret_len = cache_len + i + 1 - delim_len;
					ret_c = [self
					    allocMemoryWithSize: ret_len];

					if (cache != NULL &&
					    cache_len <= ret_len)
						memcpy(ret_c, cache, cache_len);
					else if (cache != NULL)
						memcpy(ret_c, cache, ret_len);
					if (i >= delim_len)
						memcpy(ret_c + cache_len, tmp,
					    	    i + 1 - delim_len);

					@try {
						ret = [OFString
						    stringWithCString: ret_c
							     encoding: encoding
							       length: ret_len];
					} @finally {
						[self freeMemory: ret_c];
					}

					tmp2 = [self
					    allocMemoryWithSize: len - i - 1];
					if (tmp2 != NULL)
						memcpy(tmp2, tmp + i + 1,
						    len - i - 1);

					[self freeMemory: cache];
					cache = tmp2;
					cache_len = len - i - 1;

					return ret;
				}
			}

			/* Neither the delimiter nor \0 was found */
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

- cacheWrites
{
	use_wcache = YES;

	return self;
}

- flushWriteCache
{
	if (wcache == NULL)
		return self;

	[self _writeNBytes: wcache_len
		fromBuffer: wcache];

	[self freeMemory: wcache];
	wcache = NULL;
	wcache_len = 0;
	use_wcache = NO;

	return self;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	if (!use_wcache)
		return [self _writeNBytes: size
			       fromBuffer: buf];
	else {
		wcache = [self resizeMemory: wcache
				     toSize: wcache_len + size];
		memcpy(wcache + wcache_len, buf, size);
		wcache_len += size;

		return size;
	}
}

- (void)writeInt8: (uint8_t)int8
{
	[self writeNBytes: 1
	       fromBuffer: (char*)&int8];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = OF_BSWAP16_IF_LE(int16);

	[self writeNBytes: 2
	       fromBuffer: (char*)&int16];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_LE(int32);

	[self writeNBytes: 4
	       fromBuffer: (char*)&int32];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_LE(int64);

	[self writeNBytes: 8
	       fromBuffer: (char*)&int64];
}

- (void)writeLittleEndianInt16: (uint16_t)int16
{
	int16 = OF_BSWAP16_IF_BE(int16);

	[self writeNBytes: 2
	       fromBuffer: (char*)&int16];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_BE(int32);

	[self writeNBytes: 4
	       fromBuffer: (char*)&int32];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_BE(int64);

	[self writeNBytes: 8
	       fromBuffer: (char*)&int64];
}

- (size_t)writeDataArray: (OFDataArray*)dataarray
{
	return [self writeNBytes: [dataarray count] * [dataarray itemSize]
		      fromBuffer: [dataarray cArray]];
}

- (size_t)writeString: (OFString*)str
{
	return [self writeNBytes: [str cStringLength]
		      fromBuffer: [str cString]];
}

- (size_t)writeLine: (OFString*)str
{
	size_t ret = [self writeString: str];
	[self writeInt8: '\n'];

	return ret + 1;
}

- (size_t)writeFormat: (OFString*)fmt, ...
{
	va_list args;
	char *t;
	size_t len;

	if (fmt == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	va_start(args, fmt);
	if ((len = vasprintf(&t, [fmt cString], args)) == -1) {
		/*
		 * This is only the most likely error to happen. Unfortunately,
		 * there is no good way to check what really happened.
		 */
		@throw [OFOutOfMemoryException newWithClass: isa];
	}
	va_end(args);

	@try {
		return [self writeNBytes: len
			      fromBuffer: t];
	} @finally {
		free(t);
	}

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- close
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
