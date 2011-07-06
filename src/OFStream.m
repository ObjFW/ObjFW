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
	writeBuffer = NULL;
	isBlocking = YES;

	return self;
}

- (BOOL)_isAtEndOfStream
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)_readNBytes: (size_t)length
	   intoBuffer: (void*)buffer
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)_writeNBytes: (size_t)length
	  fromBuffer: (const void*)buffer
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

- (size_t)readNBytes: (size_t)length
	  intoBuffer: (void*)buffer
{
	if (cache == NULL)
		return [self _readNBytes: length
			      intoBuffer: buffer];

	if (length >= cacheLength) {
		size_t ret = cacheLength;
		memcpy(buffer, cache, cacheLength);

		[self freeMemory: cache];
		cache = NULL;
		cacheLength = 0;

		return ret;
	} else {
		char *tmp = [self allocMemoryWithSize: cacheLength - length];
		memcpy(tmp, cache + length, cacheLength - length);

		memcpy(buffer, cache, length);

		[self freeMemory: cache];
		cache = tmp;
		cacheLength -= length;

		return length;
	}
}

- (void)readExactlyNBytes: (size_t)length
	       intoBuffer: (void*)buffer
{
	size_t readLength = 0;

	while (readLength < length)
		readLength += [self readNBytes: length - readLength
				    intoBuffer: (char*)buffer + readLength];
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

- (float)readBigEndianFloat
{
	float ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return of_bswap_float_if_le(ret);
}

- (double)readBigEndianDouble
{
	double ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return of_bswap_double_if_le(ret);
}

- (size_t)readNBigEndianInt16s: (size_t)nInt16s
		    intoBuffer: (uint16_t*)buffer
{
	size_t size = nInt16s * sizeof(uint16_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt16s; i++)
		buffer[i] = of_bswap16(buffer[i]);
#endif

	return size;
}

- (size_t)readNBigEndianInt32s: (size_t)nInt32s
		    intoBuffer: (uint32_t*)buffer
{
	size_t size = nInt32s * sizeof(uint32_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt32s; i++)
		buffer[i] = of_bswap32(buffer[i]);
#endif

	return size;
}

- (size_t)readNBigEndianInt64s: (size_t)nInt64s
		    intoBuffer: (uint64_t*)buffer
{
	size_t size = nInt64s * sizeof(uint64_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt64s; i++)
		buffer[i] = of_bswap64(buffer[i]);
#endif

	return size;
}

- (size_t)readNBigEndianFloats: (size_t)nFloats
		    intoBuffer: (float*)buffer
{
	size_t size = nFloats * sizeof(float);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifndef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nFloats; i++)
		buffer[i] = of_bswap_float(buffer[i]);
#endif

	return size;
}

- (size_t)readNBigEndianDoubles: (size_t)nDoubles
		     intoBuffer: (double*)buffer
{
	size_t size = nDoubles * sizeof(double);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifndef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nDoubles; i++)
		buffer[i] = of_bswap_double(buffer[i]);
#endif

	return size;
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

- (float)readLittleEndianFloat
{
	float ret;

	[self readExactlyNBytes: 4
		     intoBuffer: (char*)&ret];

	return of_bswap_float_if_be(ret);
}

- (double)readLittleEndianDouble
{
	double ret;

	[self readExactlyNBytes: 8
		     intoBuffer: (char*)&ret];

	return of_bswap_double_if_be(ret);
}

- (size_t)readNLittleEndianInt16s: (size_t)nInt16s
		       intoBuffer: (uint16_t*)buffer
{
	size_t size = nInt16s * sizeof(uint16_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt16s; i++)
		buffer[i] = of_bswap16(buffer[i]);
#endif

	return size;
}

- (size_t)readNLittleEndianInt32s: (size_t)nInt32s
		       intoBuffer: (uint32_t*)buffer
{
	size_t size = nInt32s * sizeof(uint32_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt32s; i++)
		buffer[i] = of_bswap32(buffer[i]);
#endif

	return size;
}

- (size_t)readNLittleEndianInt64s: (size_t)nInt64s
		       intoBuffer: (uint64_t*)buffer
{
	size_t size = nInt64s * sizeof(uint64_t);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt64s; i++)
		buffer[i] = of_bswap64(buffer[i]);
#endif

	return size;
}

- (size_t)readNLittleEndianFloats: (size_t)nFloats
		       intoBuffer: (float*)buffer
{
	size_t size = nFloats * sizeof(float);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nFloats; i++)
		buffer[i] = of_bswap_float(buffer[i]);
#endif

	return size;
}

- (size_t)readNLittleEndianDoubles: (size_t)nDoubles
			intoBuffer: (double*)buffer
{
	size_t size = nDoubles * sizeof(double);

	[self readExactlyNBytes: size
		     intoBuffer: buffer];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nDoubles; i++)
		buffer[i] = of_bswap_double(buffer[i]);
#endif

	return size;
}

- (OFDataArray*)readDataArrayWithNItems: (size_t)nItems
{
	return [self readDataArrayWithItemSize: 1
				     andNItems: nItems];
}

- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemSize
				andNItems: (size_t)nItems
{
	OFDataArray *da;
	char *tmp;

	da = [OFDataArray dataArrayWithItemSize: itemSize];
	tmp = [self allocMemoryForNItems: nItems
				withSize: itemSize];

	@try {
		[self readExactlyNBytes: nItems * itemSize
			     intoBuffer: tmp];

		[da addNItems: nItems
		   fromCArray: tmp];
	} @finally {
		[self freeMemory: tmp];
	}

	return da;
}

- (OFDataArray*)readDataArrayTillEndOfStream
{
	OFDataArray *dataArray;
	char *buffer;

	dataArray = [OFDataArray dataArray];
	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		while (![self isAtEndOfStream]) {
			size_t length;

			length = [self readNBytes: of_pagesize
				       intoBuffer: buffer];
			[dataArray addNItems: length
				  fromCArray: buffer];
		}
	} @finally {
		[self freeMemory: buffer];
	}

	return dataArray;
}

- (OFString*)readStringWithLength: (size_t)length
{
	return [self readStringWithEncoding: OF_STRING_ENCODING_UTF_8
				     length: length];
}

- (OFString*)readStringWithEncoding: (of_string_encoding_t)encoding
			     length: (size_t)length
{
	OFString *ret;
	char *buffer = [self allocMemoryWithSize: length + 1];
	buffer[length] = 0;

	@try {
		[self readExactlyNBytes: length
			     intoBuffer: buffer];

		ret = [OFString stringWithCString: buffer
					 encoding: encoding];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)readLine
{
	return [self readLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readLineWithEncoding: (of_string_encoding_t)encoding
{
	size_t i, bufferLength, retLength;
	char *retCString, *buffer, *newCache;
	OFString *ret;

	/* Look if there's a line or \0 in our cache */
	if (cache != NULL) {
		for (i = 0; i < cacheLength; i++) {
			if (OF_UNLIKELY(cache[i] == '\n' ||
			    cache[i] == '\0')) {
				retLength = i;

				if (i > 0 && cache[i - 1] == '\r')
					retLength--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: retLength];

				newCache = [self
				    allocMemoryWithSize: cacheLength - i - 1];
				if (newCache != NULL)
					memcpy(newCache, cache + i + 1,
					    cacheLength - i - 1);

				[self freeMemory: cache];
				cache = newCache;
				cacheLength -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get a newline or \0 */
	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _isAtEndOfStream]) {
				if (cache == NULL)
					return nil;

				retLength = cacheLength;

				if (retLength > 0 &&
				    cache[retLength - 1] == '\r')
					retLength--;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: retLength];

				[self freeMemory: cache];
				cache = NULL;
				cacheLength = 0;

				return ret;
			}

			bufferLength = [self _readNBytes: of_pagesize
					      intoBuffer: buffer];

			/* Look if there's a newline or \0 */
			for (i = 0; i < bufferLength; i++) {
				if (OF_UNLIKELY(buffer[i] == '\n' ||
				    buffer[i] == '\0')) {
					retLength = cacheLength + i;
					retCString = [self
					    allocMemoryWithSize: retLength];

					if (cache != NULL)
						memcpy(retCString, cache,
						    cacheLength);
					memcpy(retCString + cacheLength,
					    buffer, i);

					if (retLength > 0 &&
					    retCString[retLength - 1] == '\r')
						retLength--;

					@try {
						char *rcs = retCString;
						size_t rl = retLength;

						ret = [OFString
						    stringWithCString: rcs
							     encoding: encoding
							       length: rl];
					} @catch (id e) {
						/*
						 * Append data to cache to
						 * prevent loss of data due to
						 * wrong encoding.
						 */
						cache = [self
						    resizeMemory: cache
							  toSize: cacheLength +
								  bufferLength];

						if (cache != NULL)
							memcpy(cache +
							    cacheLength, buffer,
							    bufferLength);

						cacheLength += bufferLength;

						@throw e;
					} @finally {
						[self freeMemory: retCString];
					}

					newCache = [self allocMemoryWithSize:
					    bufferLength - i - 1];
					if (newCache != NULL)
						memcpy(newCache, buffer + i + 1,
						    bufferLength - i - 1);

					[self freeMemory: cache];
					cache = newCache;
					cacheLength = bufferLength - i - 1;

					return ret;
				}
			}

			/* There was no newline or \0 */
			cache = [self resizeMemory: cache
					    toSize: cacheLength + bufferLength];

			/*
			 * It's possible that cacheLen + len is 0 and thus
			 * cache was set to NULL by resizeMemory:toSize:.
			 */
			if (cache != NULL)
				memcpy(cache + cacheLength, buffer,
				    bufferLength);

			cacheLength += bufferLength;
		}
	} @finally {
		[self freeMemory: buffer];
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
	const char *delimiterCString;
	size_t i, j, delimiterLength, bufferLength, retLength;
	char *retCString, *buffer, *newCache;
	OFString *ret;

	/* FIXME: Convert delimiter to specified charset */
	delimiterCString = [delimiter cString];
	delimiterLength = [delimiter cStringLength];
	j = 0;

	if (delimiterLength == 0)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	/* Look if there's something in our cache */
	if (cache != NULL) {
		for (i = 0; i < cacheLength; i++) {
			if (cache[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || cache[i] == '\0') {
				if (cache[i] == '\0')
					delimiterLength = 1;

				ret = [OFString
				    stringWithCString: cache
					     encoding: encoding
					      length: i + 1 - delimiterLength];

				newCache = [self allocMemoryWithSize:
				    cacheLength - i - 1];
				if (newCache != NULL)
					memcpy(newCache, cache + i + 1,
					    cacheLength - i - 1);

				[self freeMemory: cache];
				cache = newCache;
				cacheLength -= i + 1;

				return ret;
			}
		}
	}

	/* Read until we get the delimiter or \0 */
	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		for (;;) {
			if ([self _isAtEndOfStream]) {
				if (cache == NULL)
					return nil;

				ret = [OFString stringWithCString: cache
							 encoding: encoding
							   length: cacheLength];

				[self freeMemory: cache];
				cache = NULL;
				cacheLength = 0;

				return ret;
			}

			bufferLength = [self _readNBytes: of_pagesize
					      intoBuffer: buffer];

			/* Look if there's the delimiter or \0 */
			for (i = 0; i < bufferLength; i++) {
				if (buffer[i] != delimiterCString[j++])
					j = 0;

				if (j == delimiterLength || buffer[i] == '\0') {
					if (buffer[i] == '\0')
						delimiterLength = 1;

					retLength = cacheLength + i + 1 -
					    delimiterLength;
					retCString = [self
					    allocMemoryWithSize: retLength];

					if (cache != NULL &&
					    cacheLength <= retLength)
						memcpy(retCString, cache,
						    cacheLength);
					else if (cache != NULL)
						memcpy(retCString, cache,
						    retLength);
					if (i >= delimiterLength)
						memcpy(retCString + cacheLength,
						    buffer, i + 1 -
						    delimiterLength);

					@try {
						char *rcs = retCString;
						size_t rl = retLength;

						ret = [OFString
						    stringWithCString: rcs
							     encoding: encoding
							       length: rl];
					} @finally {
						[self freeMemory: retCString];
					}

					newCache = [self allocMemoryWithSize:
					    bufferLength - i - 1];
					if (newCache != NULL)
						memcpy(newCache, buffer + i + 1,
						    bufferLength - i - 1);

					[self freeMemory: cache];
					cache = newCache;
					cacheLength = bufferLength - i - 1;

					return ret;
				}
			}

			/* Neither the delimiter nor \0 was found */
			cache = [self resizeMemory: cache
					    toSize: cacheLength + bufferLength];

			/*
			 * It's possible that cacheLen + len is 0 and thus
			 * cache was set to NULL by resizeMemory:toSize:.
			 */
			if (cache != NULL)
				memcpy(cache + cacheLength, buffer,
				    bufferLength);

			cacheLength += bufferLength;
		}
	} @finally {
		[self freeMemory: buffer];
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
	if (writeBuffer == NULL)
		return;

	[self _writeNBytes: writeBufferLength
		fromBuffer: writeBuffer];

	[self freeMemory: writeBuffer];
	writeBuffer = NULL;
	writeBufferLength = 0;
}

- (void)writeNBytes: (size_t)length
	 fromBuffer: (const void*)buffer
{
	if (!buffersWrites)
		[self _writeNBytes: length
			fromBuffer: buffer];
	else {
		writeBuffer = [self resizeMemory: writeBuffer
					  toSize: writeBufferLength + length];
		memcpy(writeBuffer + writeBufferLength, buffer, length);
		writeBufferLength += length;
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

- (void)writeBigEndianFloat: (float)float_
{
	float_ = of_bswap_float_if_le(float_);

	[self writeNBytes: 4
	       fromBuffer: (char*)&float_];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = of_bswap_double_if_le(double_);

	[self writeNBytes: 8
	       fromBuffer: (char*)&double_];
}

- (size_t)writeNBigEndianInt16s: (size_t)nInt16s
		     fromBuffer: (const uint16_t*)buffer
{
	size_t size = nInt16s * sizeof(uint16_t);

#ifdef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryForNItems: nInt16s
				withSize: sizeof(uint16_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt16s; i++)
			tmp[i] = of_bswap16(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNBigEndianInt32s: (size_t)nInt32s
		     fromBuffer: (const uint32_t*)buffer
{
	size_t size = nInt32s * sizeof(uint32_t);

#ifdef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryForNItems: nInt32s
				withSize: sizeof(uint32_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt32s; i++)
			tmp[i] = of_bswap32(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNBigEndianInt64s: (size_t)nInt64s
		     fromBuffer: (const uint64_t*)buffer
{
	size_t size = nInt64s * sizeof(uint64_t);

#ifdef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryForNItems: nInt64s
				withSize: sizeof(uint64_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt64s; i++)
			tmp[i] = of_bswap64(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNBigEndianFloats: (size_t)nFloats
		     fromBuffer: (const float*)buffer
{
	size_t size = nFloats * sizeof(float);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	float *tmp;

	tmp = [self allocMemoryForNItems: nFloats
				withSize: sizeof(float)];

	@try {
		size_t i;

		for (i = 0; i < nFloats; i++)
			tmp[i] = of_bswap_float(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNBigEndianDoubles: (size_t)nDoubles
		      fromBuffer: (const double*)buffer
{
	size_t size = nDoubles * sizeof(double);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	double *tmp;

	tmp = [self allocMemoryForNItems: nDoubles
				withSize: sizeof(double)];

	@try {
		size_t i;

		for (i = 0; i < nDoubles; i++)
			tmp[i] = of_bswap_double(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
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

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = of_bswap_float_if_be(float_);

	[self writeNBytes: 4
	       fromBuffer: (char*)&float_];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = of_bswap_double_if_be(double_);

	[self writeNBytes: 8
	       fromBuffer: (char*)&double_];
}

- (size_t)writeNLittleEndianInt16s: (size_t)nInt16s
			fromBuffer: (const uint16_t*)buffer
{
	size_t size = nInt16s * sizeof(uint16_t);

#ifndef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryForNItems: nInt16s
				withSize: sizeof(uint16_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt16s; i++)
			tmp[i] = of_bswap16(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNLittleEndianInt32s: (size_t)nInt32s
			fromBuffer: (const uint32_t*)buffer
{
	size_t size = nInt32s * sizeof(uint32_t);

#ifndef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryForNItems: nInt32s
				withSize: sizeof(uint32_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt32s; i++)
			tmp[i] = of_bswap32(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNLittleEndianInt64s: (size_t)nInt64s
			fromBuffer: (const uint64_t*)buffer
{
	size_t size = nInt64s * sizeof(uint64_t);

#ifndef OF_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryForNItems: nInt64s
				withSize: sizeof(uint64_t)];

	@try {
		size_t i;

		for (i = 0; i < nInt64s; i++)
			tmp[i] = of_bswap64(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNLittleEndianFloats: (size_t)nFloats
			fromBuffer: (const float*)buffer
{
	size_t size = nFloats * sizeof(float);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	float *tmp;

	tmp = [self allocMemoryForNItems: nFloats
				withSize: sizeof(float)];

	@try {
		size_t i;

		for (i = 0; i < nFloats; i++)
			tmp[i] = of_bswap_float(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeNLittleEndianDoubles: (size_t)nDoubles
			 fromBuffer: (const double*)buffer
{
	size_t size = nDoubles * sizeof(double);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeNBytes: size
	       fromBuffer: buffer];
#else
	double *tmp;

	tmp = [self allocMemoryForNItems: nDoubles
				withSize: sizeof(double)];

	@try {
		size_t i;

		for (i = 0; i < nDoubles; i++)
			tmp[i] = of_bswap_double(buffer[i]);

		[self writeNBytes: size
		       fromBuffer: tmp];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeDataArray: (OFDataArray*)dataArray
{
	size_t length = [dataArray count] * [dataArray itemSize];

	[self writeNBytes: length
	       fromBuffer: [dataArray cArray]];

	return [dataArray count] * [dataArray itemSize];
}

- (size_t)writeString: (OFString*)string
{
	size_t length = [string cStringLength];

	[self writeNBytes: length
	       fromBuffer: [string cString]];

	return length;
}

- (size_t)writeLine: (OFString*)string
{
	size_t stringLength = [string cStringLength];
	char *buffer;

	buffer = [self allocMemoryWithSize: stringLength + 1];

	@try {
		memcpy(buffer, [string cString], stringLength);
		buffer[stringLength] = '\n';

		[self writeNBytes: stringLength + 1
		       fromBuffer: buffer];
	} @finally {
		[self freeMemory: buffer];
	}

	return stringLength + 1;
}

- (size_t)writeFormat: (OFConstantString*)format, ...
{
	va_list arguments;
	size_t ret;

	va_start(arguments, format);
	ret = [self writeFormat: format
		  withArguments: arguments];
	va_end(arguments);

	return ret;
}

- (size_t)writeFormat: (OFConstantString*)format
	withArguments: (va_list)arguments
{
	char *cString;
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((length = of_vasprintf(&cString, [format cString],
	    arguments)) == -1)
		@throw [OFInvalidFormatException newWithClass: isa];

	@try {
		[self writeNBytes: length
		       fromBuffer: cString];
	} @finally {
		free(cString);
	}

	return length;
}

- (size_t)pendingBytes
{
	return cacheLength;
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
