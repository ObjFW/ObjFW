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

#define _GNU_SOURCE
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>
#include <fcntl.h>

#ifndef _WIN32
# include <signal.h>
#endif

#import "OFStream.h"
#import "OFString.h"
#import "OFDataArray.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFSetOptionFailedException.h"

#import "macros.h"
#import "of_asprintf.h"

@implementation OFStream
#ifndef _WIN32
+ (void)initialize
{
	if (self == [OFStream class])
		signal(SIGPIPE, SIG_IGN);
}
#endif

- init
{
	if (isa == [OFStream class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException newWithClass: c
						      selector: _cmd];
	}

	self = [super init];

	cache = NULL;
	wBuffer = NULL;
	isBlocking = YES;

	return self;
}

- (BOOL)_isAtEndOfStream
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

- (BOOL)isAtEndOfStream
{
	if (cache != NULL)
		return NO;

	return [self _isAtEndOfStream];
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	if (cache == NULL)
		return [self _readNBytes: size
			      intoBuffer: buf];

	if (size >= cacheLen) {
		size_t ret = cacheLen;
		memcpy(buf, cache, cacheLen);

		[self freeMemory: cache];
		cache = NULL;
		cacheLen = 0;

		return ret;
	} else {
		char *tmp = [self allocMemoryWithSize: cacheLen - size];
		memcpy(tmp, cache + size, cacheLen - size);

		memcpy(buf, cache, size);

		[self freeMemory: cache];
		cache = tmp;
		cacheLen -= size;

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

	return of_bswap16_if_le(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return of_bswap32_if_le(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return of_bswap64_if_le(ret);
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;

	[self readExactlyNBytes: 2
		     intoBuffer: (char*)&ret];

	return of_bswap16_if_be(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return of_bswap32_if_be(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return of_bswap64_if_be(ret);
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
		while (![self isAtEndOfStream]) {
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

- (OFString*)readLineWithEncoding: (of_string_encoding_t)encoding
{
	size_t i, len, ret_len;
	char *ret_c, *tmp, *tmp2;
	OFString *ret;

	/* Look if there's a line or \0 in our cache */
	if (cache != NULL) {
		for (i = 0; i < cacheLen; i++) {
			if (OF_UNLIKELY(cache[i] == '\n' ||
			    cache[i] == '\0')) {
				ret_len = i;

				if (i > 0 && cache[i - 1] == '\r')
					ret_len--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: ret_len];

				tmp = [self allocMemoryWithSize: cacheLen -
								 i - 1];
				if (tmp != NULL)
					memcpy(tmp, cache + i + 1,
					    cacheLen - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cacheLen -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	tmp = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _isAtEndOfStream]) {
				if (cache == NULL)
					return nil;

				ret_len = cacheLen;

				if (ret_len > 0 && cache[ret_len - 1] == '\r')
					ret_len--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: ret_len];

				[self freeMemory: cache];
				cache = NULL;
				cacheLen = 0;

				return ret;
			}

			len = [self _readNBytes: of_pagesize
				     intoBuffer: tmp];

			/* Look if there's a newline or \0 */
			for (i = 0; i < len; i++) {
				if (OF_UNLIKELY(tmp[i] == '\n' ||
				    tmp[i] == '\0')) {
					ret_len = cacheLen + i;
					ret_c = [self
					    allocMemoryWithSize: ret_len];

					if (cache != NULL)
						memcpy(ret_c, cache, cacheLen);
					memcpy(ret_c + cacheLen, tmp, i);

					if (ret_len > 0 &&
					    ret_c[ret_len - 1] == '\r')
						ret_len--;

					@try {
						ret = [OFString
						    stringWithCString: ret_c
							     encoding: encoding
							       length: ret_len];
					} @catch (id e) {
						/*
						 * Append data to cache to
						 * prevent loss of data due to
						 * wrong encoding.
						 */
						cache = [self
						    resizeMemory: cache
							  toSize: cacheLen +
								  len];

						if (cache != NULL)
							memcpy(cache + cacheLen,
							    tmp, len);

						cacheLen += len;

						@throw e;
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
					cacheLen = len - i - 1;

					return ret;
				}
			}

			/* There was no newline or \0 */
			cache = [self resizeMemory: cache
					    toSize: cacheLen + len];

			/*
			 * It's possible that cacheLen + len is 0 and thus
			 * cache was set to NULL by resizeMemory:toSize:.
			 */
			if (cache != NULL)
				memcpy(cache + cacheLen, tmp, len);

			cacheLen += len;
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
		  withEncoding: (of_string_encoding_t)encoding
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
		for (i = 0; i < cacheLen; i++) {
			if (cache[i] != delim[j++])
				j = 0;

			if (j == delim_len || cache[i] == '\0') {
				if (cache[i] == '\0')
					delim_len = 1;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: i + 1 -
								   delim_len];

				tmp = [self allocMemoryWithSize: cacheLen - i -
								 1];
				if (tmp != NULL)
					memcpy(tmp, cache + i + 1,
					    cacheLen - i - 1);

				[self freeMemory: cache];
				cache = tmp;
				cacheLen -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get the delimiter or \0 */
	tmp = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _isAtEndOfStream]) {
				if (cache == NULL)
					return nil;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: cacheLen];

				[self freeMemory: cache];
				cache = NULL;
				cacheLen = 0;

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

					ret_len = cacheLen + i + 1 - delim_len;
					ret_c = [self
					    allocMemoryWithSize: ret_len];

					if (cache != NULL &&
					    cacheLen <= ret_len)
						memcpy(ret_c, cache, cacheLen);
					else if (cache != NULL)
						memcpy(ret_c, cache, ret_len);
					if (i >= delim_len)
						memcpy(ret_c + cacheLen, tmp,
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
					cacheLen = len - i - 1;

					return ret;
				}
			}

			/* Neither the delimiter nor \0 was found */
			cache = [self resizeMemory: cache
					    toSize: cacheLen + len];

			/*
			 * It's possible that cacheLen + len is 0 and thus
			 * cache was set to NULL by resizeMemory:toSize:.
			 */
			if (cache != NULL)
				memcpy(cache + cacheLen, tmp, len);

			cacheLen += len;
		}
	} @finally {
		[self freeMemory: tmp];
	}

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- (BOOL)buffersWrites
{
	return buffersWrites;
}

- (void)setBuffersWrites: (BOOL)enable
{
	buffersWrites = enable;
}

- (void)flushWriteBuffer
{
	if (wBuffer == NULL)
		return;

	[self _writeNBytes: wBufferLen
		fromBuffer: wBuffer];

	[self freeMemory: wBuffer];
	wBuffer = NULL;
	wBufferLen = 0;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	if (!buffersWrites)
		return [self _writeNBytes: size
			       fromBuffer: buf];
	else {
		wBuffer = [self resizeMemory: wBuffer
				      toSize: wBufferLen + size];
		memcpy(wBuffer + wBufferLen, buf, size);
		wBufferLen += size;

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
	int16 = of_bswap16_if_le(int16);

	[self writeNBytes: 2
	       fromBuffer: (char*)&int16];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = of_bswap32_if_le(int32);

	[self writeNBytes: 4
	       fromBuffer: (char*)&int32];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = of_bswap64_if_le(int64);

	[self writeNBytes: 8
	       fromBuffer: (char*)&int64];
}

- (void)writeLittleEndianInt16: (uint16_t)int16
{
	int16 = of_bswap16_if_be(int16);

	[self writeNBytes: 2
	       fromBuffer: (char*)&int16];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = of_bswap32_if_be(int32);

	[self writeNBytes: 4
	       fromBuffer: (char*)&int32];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = of_bswap64_if_be(int64);

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
	size_t ret, len = [str cStringLength];
	char *buf;

	buf = [self allocMemoryWithSize: len + 1];

	@try {
		memcpy(buf, [str cString], len);
		buf[len] = '\n';

		ret = [self writeNBytes: len + 1
			     fromBuffer: buf];
	} @finally {
		[self freeMemory: buf];
	}

	return ret;
}

- (size_t)writeFormat: (OFString*)fmt, ...
{
	va_list args;
	size_t ret;

	va_start(args, fmt);
	ret = [self writeFormat: fmt
		  withArguments: args];
	va_end(args);

	return ret;
}

- (size_t)writeFormat: (OFString*)fmt
	withArguments: (va_list)args
{
	char *t;
	int len;

	if (fmt == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((len = of_vasprintf(&t, [fmt cString], args)) == -1)
		@throw [OFInvalidFormatException newWithClass: isa];

	@try {
		return [self writeNBytes: len
			      fromBuffer: t];
	} @finally {
		free(t);
	}

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- (BOOL)isBlocking
{
	return isBlocking;
}

- (void)setBlocking: (BOOL)enable
{
#ifndef _WIN32
	int flags;

	isBlocking = enable;

	if ((flags = fcntl([self fileDescriptor], F_GETFL)) == -1)
		@throw [OFSetOptionFailedException newWithClass: isa
							 stream: self];

	if (enable)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl([self fileDescriptor], F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException newWithClass: isa
							 stream: self];
#else
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
#endif
}

- (int)fileDescriptor
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)close
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
