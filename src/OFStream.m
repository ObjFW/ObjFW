/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define __NO_EXT_QNX

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
	if (object_getClass(self) == [OFStream class]) {
		Class c = [self class];
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	self = [super init];

	cache = NULL;
	writeBuffer = NULL;
	blocking = YES;

	return self;
}

- (BOOL)_isAtEndOfStream
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (size_t)_readIntoBuffer: (void*)buffer
		   length: (size_t)length
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (void)_writeBuffer: (const void*)buffer
	      length: (size_t)length
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- copy
{
	return [self retain];
}

- (BOOL)isAtEndOfStream
{
	if (cache != NULL)
		return NO;

	return [self _isAtEndOfStream];
}

- (size_t)readIntoBuffer: (void*)buffer
		  length: (size_t)length
{
	if (cache == NULL)
		return [self _readIntoBuffer: buffer
				      length: length];

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

- (void)readIntoBuffer: (void*)buffer
	   exactLength: (size_t)length
{
	size_t readLength = 0;

	while (readLength < length)
		readLength += [self readIntoBuffer: (char*)buffer + readLength
					    length: length - readLength];
}

- (uint8_t)readInt8
{
	uint8_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 1];

	return ret;
}

- (uint16_t)readBigEndianInt16
{
	uint16_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 2];

	return of_bswap16_if_le(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return of_bswap32_if_le(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return of_bswap64_if_le(ret);
}

- (float)readBigEndianFloat
{
	float ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return of_bswap_float_if_le(ret);
}

- (double)readBigEndianDouble
{
	double ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return of_bswap_double_if_le(ret);
}

- (size_t)readBigEndianInt16sIntoBuffer: (uint16_t*)buffer
				  count: (size_t)nInt16s
{
	size_t size = nInt16s * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt16s; i++)
		buffer[i] = of_bswap16(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt32sIntoBuffer: (uint32_t*)buffer
				  count: (size_t)nInt32s
{
	size_t size = nInt32s * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt32s; i++)
		buffer[i] = of_bswap32(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt64sIntoBuffer: (uint64_t*)buffer
				  count: (size_t)nInt64s
{
	size_t size = nInt64s * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt64s; i++)
		buffer[i] = of_bswap64(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianFloatsIntoBuffer: (float*)buffer
				  count: (size_t)nFloats
{
	size_t size = nFloats * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nFloats; i++)
		buffer[i] = of_bswap_float(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianDoublesIntoBuffer: (double*)buffer
				   count: (size_t)nDoubles
{
	size_t size = nDoubles * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

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

	[self readIntoBuffer: (char*)&ret
		 exactLength: 2];

	return of_bswap16_if_be(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return of_bswap32_if_be(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return of_bswap64_if_be(ret);
}

- (float)readLittleEndianFloat
{
	float ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return of_bswap_float_if_be(ret);
}

- (double)readLittleEndianDouble
{
	double ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return of_bswap_double_if_be(ret);
}

- (size_t)readLittleEndianInt16sIntoBuffer: (uint16_t*)buffer
				     count: (size_t)nInt16s
{
	size_t size = nInt16s * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt16s; i++)
		buffer[i] = of_bswap16(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt32sIntoBuffer: (uint32_t*)buffer
				     count: (size_t)nInt32s
{
	size_t size = nInt32s * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt32s; i++)
		buffer[i] = of_bswap32(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt64sIntoBuffer: (uint64_t*)buffer
				     count: (size_t)nInt64s
{
	size_t size = nInt64s * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nInt64s; i++)
		buffer[i] = of_bswap64(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianFloatsIntoBuffer: (float*)buffer
				     count: (size_t)nFloats
{
	size_t size = nFloats * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nFloats; i++)
		buffer[i] = of_bswap_float(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianDoublesIntoBuffer: (double*)buffer
				      count: (size_t)nDoubles
{
	size_t size = nDoubles * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < nDoubles; i++)
		buffer[i] = of_bswap_double(buffer[i]);
#endif

	return size;
}

- (OFDataArray*)readDataArrayWithSize: (size_t)nItems
{
	return [self readDataArrayWithItemSize: 1
					 count: nItems];
}

- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemSize
				    count: (size_t)nItems
{
	OFDataArray *dataArray;
	char *tmp;

	dataArray = [OFDataArray dataArrayWithItemSize: itemSize];
	tmp = [self allocMemoryWithSize: itemSize
				  count: nItems];

	@try {
		[self readIntoBuffer: tmp
			 exactLength: nItems * itemSize];

		[dataArray addItemsFromCArray: tmp
					count: nItems];
	} @finally {
		[self freeMemory: tmp];
	}

	return dataArray;
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

			length = [self readIntoBuffer: buffer
					       length: of_pagesize];
			[dataArray addItemsFromCArray: buffer
						count: length];
		}
	} @finally {
		[self freeMemory: buffer];
	}

	return dataArray;
}

- (OFString*)readStringWithLength: (size_t)length
{
	return [self readStringWithLength: length
				 encoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readStringWithLength: (size_t)length
			 encoding: (of_string_encoding_t)encoding
{
	OFString *ret;
	char *buffer = [self allocMemoryWithSize: length + 1];
	buffer[length] = 0;

	@try {
		[self readIntoBuffer: buffer
			 exactLength: length];

		ret = [OFString stringWithCString: buffer
					 encoding: encoding];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)tryReadLineWithEncoding: (of_string_encoding_t)encoding
{
	size_t i, bufferLength, retLength;
	char *retCString, *buffer, *newCache;
	OFString *ret;

	/* Look if there's a line or \0 in our cache */
	if (!waitingForDelimiter && cache != NULL) {
		for (i = 0; i < cacheLength; i++) {
			if OF_UNLIKELY (cache[i] == '\n' || cache[i] == '\0') {
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

				waitingForDelimiter = NO;
				return ret;
			}
		}
	}

	/* Read and see if we get a newline or \0 */
	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if ([self _isAtEndOfStream]) {
			if (cache == NULL) {
				waitingForDelimiter = NO;
				return nil;
			}

			retLength = cacheLength;

			if (retLength > 0 && cache[retLength - 1] == '\r')
				retLength--;

			ret = [OFString stringWithCString: cache
						 encoding: encoding
						   length: retLength];

			[self freeMemory: cache];
			cache = NULL;
			cacheLength = 0;

			waitingForDelimiter = NO;
			return ret;
		}

		bufferLength = [self _readIntoBuffer: buffer
					      length: of_pagesize];

		/* Look if there's a newline or \0 */
		for (i = 0; i < bufferLength; i++) {
			if OF_UNLIKELY (buffer[i] == '\n' ||
			    buffer[i] == '\0') {
				retLength = cacheLength + i;
				retCString = [self
				    allocMemoryWithSize: retLength];

				if (cache != NULL)
					memcpy(retCString, cache, cacheLength);
				memcpy(retCString + cacheLength, buffer, i);

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
					 * Append data to cache to prevent loss
					 * of data due to wrong encoding.
					 */
					cache = [self
					    resizeMemory: cache
						    size: cacheLength +
							  bufferLength];

					if (cache != NULL)
						memcpy(cache + cacheLength,
						    buffer, bufferLength);

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

				waitingForDelimiter = NO;
				return ret;
			}
		}

		/* There was no newline or \0 */
		cache = [self resizeMemory: cache
				      size: cacheLength + bufferLength];

		/*
		 * It's possible that cacheLen + len is 0 and thus cache was
		 * set to NULL by resizeMemory:size:.
		 */
		if (cache != NULL)
			memcpy(cache + cacheLength, buffer, bufferLength);

		cacheLength += bufferLength;
	} @finally {
		[self freeMemory: buffer];
	}

	waitingForDelimiter = YES;
	return nil;
}

- (OFString*)readLine
{
	return [self readLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readLineWithEncoding: (of_string_encoding_t)encoding
{
	OFString *line = nil;

	while ((line = [self tryReadLineWithEncoding: encoding]) == nil)
		if ([self isAtEndOfStream])
			return nil;

	return line;
}

- (OFString*)tryReadLine
{
	return [self tryReadLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)tryReadTillDelimiter: (OFString*)delimiter
			 encoding: (of_string_encoding_t)encoding
{
	const char *delimiterUTF8String;
	size_t i, j, delimiterLength, bufferLength, retLength;
	char *retCString, *buffer, *newCache;
	OFString *ret;

	/* FIXME: Convert delimiter to specified charset */
	delimiterUTF8String = [delimiter UTF8String];
	delimiterLength = [delimiter UTF8StringLength];
	j = 0;

	if (delimiterLength == 0)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	/* Look if there's something in our cache */
	if (!waitingForDelimiter && cache != NULL) {
		for (i = 0; i < cacheLength; i++) {
			if (cache[i] != delimiterUTF8String[j++])
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

				waitingForDelimiter = NO;
				return ret;
			}
		}
	}

	/* Read and see if we get a delimiter or \0 */
	buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		if ([self _isAtEndOfStream]) {
			if (cache == NULL) {
				waitingForDelimiter = NO;
				return nil;
			}

			ret = [OFString stringWithCString: cache
						 encoding: encoding
						   length: cacheLength];

			[self freeMemory: cache];
			cache = NULL;
			cacheLength = 0;

			waitingForDelimiter = NO;
			return ret;
		}

		bufferLength = [self _readIntoBuffer: buffer
					      length: of_pagesize];

		/* Look if there's a delimiter or \0 */
		for (i = 0; i < bufferLength; i++) {
			if (buffer[i] != delimiterUTF8String[j++])
				j = 0;

			if (j == delimiterLength || buffer[i] == '\0') {
				if (buffer[i] == '\0')
					delimiterLength = 1;

				retLength = cacheLength + i + 1 -
				    delimiterLength;
				retCString = [self
				    allocMemoryWithSize: retLength];

				if (cache != NULL && cacheLength <= retLength)
					memcpy(retCString, cache, cacheLength);
				else if (cache != NULL)
					memcpy(retCString, cache, retLength);
				if (i >= delimiterLength)
					memcpy(retCString + cacheLength,
					    buffer, i + 1 - delimiterLength);

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

				waitingForDelimiter = NO;
				return ret;
			}
		}

		/* Neither the delimiter nor \0 was found */
		cache = [self resizeMemory: cache
				      size: cacheLength + bufferLength];

		/*
		 * It's possible that cacheLen + len is 0 and thus cache was
		 * set to NULL by resizeMemory:size:.
		 */
		if (cache != NULL)
			memcpy(cache + cacheLength, buffer,
			    bufferLength);

		cacheLength += bufferLength;
	} @finally {
		[self freeMemory: buffer];
	}

	waitingForDelimiter = YES;
	return nil;
}


- (OFString*)readTillDelimiter: (OFString*)delimiter
{
	return [self readTillDelimiter: delimiter
			      encoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)readTillDelimiter: (OFString*)delimiter
		      encoding: (of_string_encoding_t)encoding
{
	OFString *ret = nil;


	while ((ret = [self tryReadTillDelimiter: delimiter
					encoding: encoding]) == nil)
		if ([self isAtEndOfStream])
			return nil;

	return ret;
}

- (OFString*)tryReadTillDelimiter: (OFString*)delimiter
{
	return [self tryReadTillDelimiter: delimiter
				 encoding: OF_STRING_ENCODING_UTF_8];
}

- (BOOL)writeBufferEnabled
{
	return writeBufferEnabled;
}

- (void)setWriteBufferEnabled: (BOOL)enable
{
	writeBufferEnabled = enable;
}

- (void)flushWriteBuffer
{
	if (writeBuffer == NULL)
		return;

	[self _writeBuffer: writeBuffer
		    length: writeBufferLength];

	[self freeMemory: writeBuffer];
	writeBuffer = NULL;
	writeBufferLength = 0;
}

- (void)writeBuffer: (const void*)buffer
	     length: (size_t)length
{
	if (!writeBufferEnabled)
		[self _writeBuffer: buffer
			    length: length];
	else {
		writeBuffer = [self resizeMemory: writeBuffer
					    size: writeBufferLength + length];
		memcpy(writeBuffer + writeBufferLength, buffer, length);
		writeBufferLength += length;
	}
}

- (void)writeInt8: (uint8_t)int8
{
	[self writeBuffer: (char*)&int8
		   length: 1];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = of_bswap16_if_le(int16);

	[self writeBuffer: (char*)&int16
		   length: 2];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = of_bswap32_if_le(int32);

	[self writeBuffer: (char*)&int32
		   length: 4];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = of_bswap64_if_le(int64);

	[self writeBuffer: (char*)&int64
		   length: 8];
}

- (void)writeBigEndianFloat: (float)float_
{
	float_ = of_bswap_float_if_le(float_);

	[self writeBuffer: (char*)&float_
		   length: 4];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = of_bswap_double_if_le(double_);

	[self writeBuffer: (char*)&double_
		   length: 8];
}

- (size_t)writeBigEndianInt16s: (const uint16_t*)buffer
			 count: (size_t)nInt16s
{
	size_t size = nInt16s * sizeof(uint16_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint16_t)
				  count: nInt16s];

	@try {
		size_t i;

		for (i = 0; i < nInt16s; i++)
			tmp[i] = of_bswap16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt32s: (const uint32_t*)buffer
			 count: (size_t)nInt32s
{
	size_t size = nInt32s * sizeof(uint32_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint32_t)
				  count: nInt32s];

	@try {
		size_t i;

		for (i = 0; i < nInt32s; i++)
			tmp[i] = of_bswap32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt64s: (const uint64_t*)buffer
			 count: (size_t)nInt64s
{
	size_t size = nInt64s * sizeof(uint64_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint64_t)
				  count: nInt64s];

	@try {
		size_t i;

		for (i = 0; i < nInt64s; i++)
			tmp[i] = of_bswap64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianFloats: (const float*)buffer
			 count: (size_t)nFloats
{
	size_t size = nFloats * sizeof(float);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp;

	tmp = [self allocMemoryWithSize: sizeof(float)
				  count: nFloats];

	@try {
		size_t i;

		for (i = 0; i < nFloats; i++)
			tmp[i] = of_bswap_float(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianDoubles: (const double*)buffer
			  count: (size_t)nDoubles
{
	size_t size = nDoubles * sizeof(double);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp;

	tmp = [self allocMemoryWithSize: sizeof(double)
				  count: nDoubles];

	@try {
		size_t i;

		for (i = 0; i < nDoubles; i++)
			tmp[i] = of_bswap_double(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (void)writeLittleEndianInt16: (uint16_t)int16
{
	int16 = of_bswap16_if_be(int16);

	[self writeBuffer: (char*)&int16
		   length: 2];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = of_bswap32_if_be(int32);

	[self writeBuffer: (char*)&int32
		   length: 4];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = of_bswap64_if_be(int64);

	[self writeBuffer: (char*)&int64
		   length: 8];
}

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = of_bswap_float_if_be(float_);

	[self writeBuffer: (char*)&float_
		   length: 4];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = of_bswap_double_if_be(double_);

	[self writeBuffer: (char*)&double_
		   length: 8];
}

- (size_t)writeLittleEndianInt16s: (const uint16_t*)buffer
			    count: (size_t)nInt16s
{
	size_t size = nInt16s * sizeof(uint16_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint16_t)
				  count: nInt16s];

	@try {
		size_t i;

		for (i = 0; i < nInt16s; i++)
			tmp[i] = of_bswap16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt32s: (const uint32_t*)buffer
			    count: (size_t)nInt32s
{
	size_t size = nInt32s * sizeof(uint32_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint32_t)
				  count: nInt32s];

	@try {
		size_t i;

		for (i = 0; i < nInt32s; i++)
			tmp[i] = of_bswap32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt64s: (const uint64_t*)buffer
			    count: (size_t)nInt64s
{
	size_t size = nInt64s * sizeof(uint64_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint64_t)
				  count: nInt64s];

	@try {
		size_t i;

		for (i = 0; i < nInt64s; i++)
			tmp[i] = of_bswap64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianFloats: (const float*)buffer
			    count: (size_t)nFloats
{
	size_t size = nFloats * sizeof(float);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp;

	tmp = [self allocMemoryWithSize: sizeof(float)
				  count: nFloats];

	@try {
		size_t i;

		for (i = 0; i < nFloats; i++)
			tmp[i] = of_bswap_float(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianDoubles: (const double*)buffer
			     count: (size_t)nDoubles
{
	size_t size = nDoubles * sizeof(double);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp;

	tmp = [self allocMemoryWithSize: sizeof(double)
				  count: nDoubles];

	@try {
		size_t i;

		for (i = 0; i < nDoubles; i++)
			tmp[i] = of_bswap_double(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeDataArray: (OFDataArray*)dataArray
{
	size_t length = [dataArray count] * [dataArray itemSize];

	[self writeBuffer: [dataArray cArray]
		   length: length];

	return [dataArray count] * [dataArray itemSize];
}

- (size_t)writeString: (OFString*)string
{
	size_t length = [string UTF8StringLength];

	[self writeBuffer: [string UTF8String]
		   length: length];

	return length;
}

- (size_t)writeLine: (OFString*)string
{
	size_t stringLength = [string UTF8StringLength];
	char *buffer;

	buffer = [self allocMemoryWithSize: stringLength + 1];

	@try {
		memcpy(buffer, [string UTF8String], stringLength);
		buffer[stringLength] = '\n';

		[self writeBuffer: buffer
			   length: stringLength + 1];
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
		      arguments: arguments];
	va_end(arguments);

	return ret;
}

- (size_t)writeFormat: (OFConstantString*)format
	    arguments: (va_list)arguments
{
	char *UTF8String;
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	if ((length = of_vasprintf(&UTF8String, [format UTF8String],
	    arguments)) == -1)
		@throw [OFInvalidFormatException
		    exceptionWithClass: [self class]];

	@try {
		[self writeBuffer: UTF8String
			   length: length];
	} @finally {
		free(UTF8String);
	}

	return length;
}

- (size_t)pendingBytes
{
	return cacheLength;
}

- (BOOL)isBlocking
{
	return blocking;
}

- (void)setBlocking: (BOOL)enable
{
#ifndef _WIN32
	int readFlags, writeFlags;

	readFlags = fcntl([self fileDescriptorForReading], F_GETFL);
	writeFlags = fcntl([self fileDescriptorForWriting], F_GETFL);

	if (readFlags == -1 || writeFlags == -1)
		@throw [OFSetOptionFailedException
		    exceptionWithClass: [self class]
				stream: self];

	if (enable) {
		readFlags &= ~O_NONBLOCK;
		writeFlags &= ~O_NONBLOCK;
	} else {
		readFlags |= O_NONBLOCK;
		writeFlags |= O_NONBLOCK;
	}

	if (fcntl([self fileDescriptorForReading], F_SETFL, readFlags) == -1 ||
	    fcntl([self fileDescriptorForWriting], F_SETFL, writeFlags) == -1)
		@throw [OFSetOptionFailedException
		    exceptionWithClass: [self class]
				stream: self];
#else
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
#endif
}

- (int)fileDescriptorForReading
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (int)fileDescriptorForWriting
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (void)close
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (BOOL)_isWaitingForDelimiter
{
	return waitingForDelimiter;
}
@end
