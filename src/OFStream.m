/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#import "OFStream+Private.h"
#import "OFString.h"
#import "OFDataArray.h"
#import "OFSystemInfo.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
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
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	self = [super init];

	_blocking = true;

	return self;
}

- (bool)lowlevelIsAtEndOfStream
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- copy
{
	return [self retain];
}

- (bool)isAtEndOfStream
{
	if (_readBufferLength > 0)
		return false;

	return [self lowlevelIsAtEndOfStream];
}

- (size_t)readIntoBuffer: (void*)buffer
		  length: (size_t)length
{
	if (_readBufferLength == 0)
		return [self lowlevelReadIntoBuffer: buffer
					     length: length];

	if (length >= _readBufferLength) {
		size_t ret = _readBufferLength;
		memcpy(buffer, _readBuffer, _readBufferLength);

		[self freeMemory: _readBuffer];
		_readBuffer = NULL;
		_readBufferLength = 0;

		return ret;
	} else {
		char *tmp;

		tmp = [self allocMemoryWithSize: _readBufferLength - length];
		memcpy(tmp, _readBuffer + length, _readBufferLength - length);

		memcpy(buffer, _readBuffer, length);

		[self freeMemory: _readBuffer];
		_readBuffer = tmp;
		_readBufferLength -= length;

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

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadIntoBuffer: (void*)buffer
		     length: (size_t)length
		     target: (id)target
		   selector: (SEL)selector
{
	[OFRunLoop OF_addAsyncReadForStream: self
				     buffer: buffer
				     length: length
				     target: target
				   selector: selector];
}

- (void)asyncReadIntoBuffer: (void*)buffer
		exactLength: (size_t)length
		     target: (id)target
		   selector: (SEL)selector
{
	[OFRunLoop OF_addAsyncReadForStream: self
				     buffer: buffer
				exactLength: length
				     target: target
				   selector: selector];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadIntoBuffer: (void*)buffer
		     length: (size_t)length
		      block: (of_stream_async_read_block_t)block
{
	[OFRunLoop OF_addAsyncReadForStream: self
				     buffer: buffer
				     length: length
				      block: block];
}

- (void)asyncReadIntoBuffer: (void*)buffer
		exactLength: (size_t)length
		      block: (of_stream_async_read_block_t)block
{
	[OFRunLoop OF_addAsyncReadForStream: self
				     buffer: buffer
				exactLength: length
				      block: block];
}
# endif
#endif

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

	return OF_BSWAP16_IF_LE(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return OF_BSWAP32_IF_LE(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return OF_BSWAP64_IF_LE(ret);
}

- (float)readBigEndianFloat
{
	float ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return OF_BSWAP_FLOAT_IF_LE(ret);
}

- (double)readBigEndianDouble
{
	double ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return OF_BSWAP_DOUBLE_IF_LE(ret);
}

- (size_t)readBigEndianInt16sIntoBuffer: (uint16_t*)buffer
				  count: (size_t)count
{
	size_t size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP16(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt32sIntoBuffer: (uint32_t*)buffer
				  count: (size_t)count
{
	size_t size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP32(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt64sIntoBuffer: (uint64_t*)buffer
				  count: (size_t)count
{
	size_t size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP64(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianFloatsIntoBuffer: (float*)buffer
				  count: (size_t)count
{
	size_t size = count * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_FLOAT(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianDoublesIntoBuffer: (double*)buffer
				   count: (size_t)count
{
	size_t size = count * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_DOUBLE(buffer[i]);
#endif

	return size;
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 2];

	return OF_BSWAP16_IF_BE(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return OF_BSWAP32_IF_BE(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return OF_BSWAP64_IF_BE(ret);
}

- (float)readLittleEndianFloat
{
	float ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 4];

	return OF_BSWAP_FLOAT_IF_BE(ret);
}

- (double)readLittleEndianDouble
{
	double ret;

	[self readIntoBuffer: (char*)&ret
		 exactLength: 8];

	return OF_BSWAP_DOUBLE_IF_BE(ret);
}

- (size_t)readLittleEndianInt16sIntoBuffer: (uint16_t*)buffer
				     count: (size_t)count
{
	size_t size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP16(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt32sIntoBuffer: (uint32_t*)buffer
				     count: (size_t)count
{
	size_t size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP32(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt64sIntoBuffer: (uint64_t*)buffer
				     count: (size_t)count
{
	size_t size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP64(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianFloatsIntoBuffer: (float*)buffer
				     count: (size_t)count
{
	size_t size = count * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_FLOAT(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianDoublesIntoBuffer: (double*)buffer
				      count: (size_t)count
{
	size_t size = count * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	size_t i;

	for (i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_DOUBLE(buffer[i]);
#endif

	return size;
}

- (OFDataArray*)readDataArrayWithCount: (size_t)count
{
	return [self readDataArrayWithItemSize: 1
					 count: count];
}

- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemSize
				    count: (size_t)count
{
	OFDataArray *dataArray;
	char *tmp;

	dataArray = [OFDataArray dataArrayWithItemSize: itemSize];
	tmp = [self allocMemoryWithSize: itemSize
				  count: count];

	@try {
		[self readIntoBuffer: tmp
			 exactLength: count * itemSize];

		[dataArray addItems: tmp
			      count: count];
	} @finally {
		[self freeMemory: tmp];
	}

	return dataArray;
}

- (OFDataArray*)readDataArrayTillEndOfStream
{
	OFDataArray *dataArray;
	size_t pageSize;
	char *buffer;

	dataArray = [OFDataArray dataArray];
	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];

	@try {
		while (![self isAtEndOfStream]) {
			size_t length;

			length = [self readIntoBuffer: buffer
					       length: pageSize];
			[dataArray addItems: buffer
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
	size_t i, pageSize, bufferLength, retLength;
	char *retCString, *buffer, *readBuffer;
	OFString *ret;

	/* Look if there's a line or \0 in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (i = 0; i < _readBufferLength; i++) {
			if OF_UNLIKELY (_readBuffer[i] == '\n' ||
			    _readBuffer[i] == '\0') {
				retLength = i;

				if (i > 0 && _readBuffer[i - 1] == '\r')
					retLength--;

				ret = [OFString stringWithCString: _readBuffer
							 encoding: encoding
							   length: retLength];

				readBuffer = [self allocMemoryWithSize:
				    _readBufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, _readBuffer + i + 1,
					    _readBufferLength - i - 1);

				[self freeMemory: _readBuffer];
				_readBuffer = readBuffer;
				_readBufferLength -= i + 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}
	}

	/* Read and see if we got a newline or \0 */
	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			retLength = _readBufferLength;

			if (retLength > 0 && _readBuffer[retLength - 1] == '\r')
				retLength--;

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: retLength];

			[self freeMemory: _readBuffer];
			_readBuffer = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a newline or \0 */
		for (i = 0; i < bufferLength; i++) {
			if OF_UNLIKELY (buffer[i] == '\n' ||
			    buffer[i] == '\0') {
				retLength = _readBufferLength + i;
				retCString = [self
				    allocMemoryWithSize: retLength];

				if (_readBuffer != NULL)
					memcpy(retCString, _readBuffer,
					    _readBufferLength);
				memcpy(retCString + _readBufferLength,
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
					 * Append data to readBuffer to prevent
					 * loss of data due to wrong encoding.
					 */
					_readBuffer = [self
					    resizeMemory: _readBuffer
						    size: _readBufferLength +
							  bufferLength];

					if (_readBuffer != NULL)
						memcpy(_readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

					_readBufferLength += bufferLength;

					@throw e;
				} @finally {
					[self freeMemory: retCString];
				}

				readBuffer = [self
				    allocMemoryWithSize: bufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				[self freeMemory: _readBuffer];
				_readBuffer = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* There was no newline or \0 */
		_readBuffer = [self resizeMemory: _readBuffer
					    size: _readBufferLength +
						  bufferLength];

		/*
		 * It's possible that _readBufferLength + bufferLength is 0 and
		 * thus _readBuffer was set to NULL by resizeMemory:size:.
		 */
		if (_readBuffer != NULL)
			memcpy(_readBuffer + _readBufferLength,
			    buffer, bufferLength);

		_readBufferLength += bufferLength;
	} @finally {
		[self freeMemory: buffer];
	}

	_waitingForDelimiter = true;
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

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadLineWithTarget: (id)target
		       selector: (SEL)selector
{
	[self asyncReadLineWithEncoding: OF_STRING_ENCODING_UTF_8
				 target: target
			       selector: selector];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
			   target: (id)target
			 selector: (SEL)selector
{
	[OFRunLoop OF_addAsyncReadLineForStream: self
				       encoding: encoding
					 target: target
				       selector: selector];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadLineWithBlock: (of_stream_async_read_line_block_t)block
{
	[self asyncReadLineWithEncoding: OF_STRING_ENCODING_UTF_8
				  block: block];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
			    block: (of_stream_async_read_line_block_t)block
{
	[OFRunLoop OF_addAsyncReadLineForStream: self
				       encoding: encoding
					  block: block];
}
# endif
#endif

- (OFString*)tryReadLine
{
	return [self tryReadLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString*)tryReadTillDelimiter: (OFString*)delimiter
			 encoding: (of_string_encoding_t)encoding
{
	const char *delimiterCString;
	size_t i, j, delimiterLength, pageSize, bufferLength, retLength;
	char *retCString, *buffer, *readBuffer;
	OFString *ret;

	delimiterCString = [delimiter cStringWithEncoding: encoding];
	delimiterLength = [delimiter cStringLengthWithEncoding: encoding];
	j = 0;

	if (delimiterLength == 0)
		@throw [OFInvalidArgumentException exception];

	/* Look if there's something in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (i = 0; i < _readBufferLength; i++) {
			if (_readBuffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || _readBuffer[i] == '\0') {
				if (_readBuffer[i] == '\0')
					delimiterLength = 1;

				ret = [OFString
				    stringWithCString: _readBuffer
					     encoding: encoding
					      length: i + 1 - delimiterLength];

				readBuffer = [self allocMemoryWithSize:
				    _readBufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, _readBuffer + i + 1,
					    _readBufferLength - i - 1);

				[self freeMemory: _readBuffer];
				_readBuffer = readBuffer;
				_readBufferLength -= i + 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}
	}

	/* Read and see if we got a delimiter or \0 */
	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: _readBufferLength];

			[self freeMemory: _readBuffer];
			_readBuffer = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a delimiter or \0 */
		for (i = 0; i < bufferLength; i++) {
			if (buffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || buffer[i] == '\0') {
				if (buffer[i] == '\0')
					delimiterLength = 1;

				retLength = _readBufferLength + i + 1 -
				    delimiterLength;
				retCString = [self
				    allocMemoryWithSize: retLength];

				if (_readBuffer != NULL &&
				    _readBufferLength <= retLength)
					memcpy(retCString, _readBuffer,
					    _readBufferLength);
				else if (_readBuffer != NULL)
					memcpy(retCString, _readBuffer,
					    retLength);
				if (i >= delimiterLength)
					memcpy(retCString + _readBufferLength,
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

				readBuffer = [self allocMemoryWithSize:
				    bufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				[self freeMemory: _readBuffer];
				_readBuffer = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* Neither the delimiter nor \0 was found */
		_readBuffer = [self resizeMemory: _readBuffer
					    size: _readBufferLength +
						  bufferLength];

		/*
		 * It's possible that _readBufferLength + bufferLength is 0 and
		 * thus _readBuffer was set to NULL by resizeMemory:size:.
		 */
		if (_readBuffer != NULL)
			memcpy(_readBuffer + _readBufferLength,
			    buffer, bufferLength);

		_readBufferLength += bufferLength;
	} @finally {
		[self freeMemory: buffer];
	}

	_waitingForDelimiter = true;
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

- (bool)isWriteBufferEnabled
{
	return _writeBufferEnabled;
}

- (void)setWriteBufferEnabled: (bool)enable
{
	_writeBufferEnabled = enable;
}

- (void)flushWriteBuffer
{
	if (_writeBuffer == NULL)
		return;

	[self lowlevelWriteBuffer: _writeBuffer
			   length: _writeBufferLength];

	[self freeMemory: _writeBuffer];
	_writeBuffer = NULL;
	_writeBufferLength = 0;
}

- (void)writeBuffer: (const void*)buffer
	     length: (size_t)length
{
	if (!_writeBufferEnabled)
		[self lowlevelWriteBuffer: buffer
				   length: length];
	else {
		_writeBuffer = [self resizeMemory: _writeBuffer
					     size: _writeBufferLength + length];
		memcpy(_writeBuffer + _writeBufferLength, buffer, length);
		_writeBufferLength += length;
	}
}

- (void)writeInt8: (uint8_t)int8
{
	[self writeBuffer: (char*)&int8
		   length: 1];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = OF_BSWAP16_IF_LE(int16);

	[self writeBuffer: (char*)&int16
		   length: 2];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_LE(int32);

	[self writeBuffer: (char*)&int32
		   length: 4];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_LE(int64);

	[self writeBuffer: (char*)&int64
		   length: 8];
}

- (void)writeBigEndianFloat: (float)float_
{
	float_ = OF_BSWAP_FLOAT_IF_LE(float_);

	[self writeBuffer: (char*)&float_
		   length: 4];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = OF_BSWAP_DOUBLE_IF_LE(double_);

	[self writeBuffer: (char*)&double_
		   length: 8];
}

- (size_t)writeBigEndianInt16s: (const uint16_t*)buffer
			 count: (size_t)count
{
	size_t size = count * sizeof(uint16_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint16_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt32s: (const uint32_t*)buffer
			 count: (size_t)count
{
	size_t size = count * sizeof(uint32_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint32_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt64s: (const uint64_t*)buffer
			 count: (size_t)count
{
	size_t size = count * sizeof(uint64_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint64_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianFloats: (const float*)buffer
			 count: (size_t)count
{
	size_t size = count * sizeof(float);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp;

	tmp = [self allocMemoryWithSize: sizeof(float)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_FLOAT(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianDoubles: (const double*)buffer
			  count: (size_t)count
{
	size_t size = count * sizeof(double);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp;

	tmp = [self allocMemoryWithSize: sizeof(double)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_DOUBLE(buffer[i]);

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
	int16 = OF_BSWAP16_IF_BE(int16);

	[self writeBuffer: (char*)&int16
		   length: 2];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_BE(int32);

	[self writeBuffer: (char*)&int32
		   length: 4];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_BE(int64);

	[self writeBuffer: (char*)&int64
		   length: 8];
}

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = OF_BSWAP_FLOAT_IF_BE(float_);

	[self writeBuffer: (char*)&float_
		   length: 4];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = OF_BSWAP_DOUBLE_IF_BE(double_);

	[self writeBuffer: (char*)&double_
		   length: 8];
}

- (size_t)writeLittleEndianInt16s: (const uint16_t*)buffer
			    count: (size_t)count
{
	size_t size = count * sizeof(uint16_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint16_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt32s: (const uint32_t*)buffer
			    count: (size_t)count
{
	size_t size = count * sizeof(uint32_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint32_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt64s: (const uint64_t*)buffer
			    count: (size_t)count
{
	size_t size = count * sizeof(uint64_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp;

	tmp = [self allocMemoryWithSize: sizeof(uint64_t)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianFloats: (const float*)buffer
			    count: (size_t)count
{
	size_t size = count * sizeof(float);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp;

	tmp = [self allocMemoryWithSize: sizeof(float)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_FLOAT(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianDoubles: (const double*)buffer
			     count: (size_t)count
{
	size_t size = count * sizeof(double);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp;

	tmp = [self allocMemoryWithSize: sizeof(double)
				  count: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_DOUBLE(buffer[i]);

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

	[self writeBuffer: [dataArray items]
		   length: length];

	return length;
}

- (size_t)writeString: (OFString*)string
{
	return [self writeString: string
			encoding: OF_STRING_ENCODING_UTF_8];
}

- (size_t)writeString: (OFString*)string
	     encoding: (of_string_encoding_t)encoding
{
	size_t length = [string cStringLengthWithEncoding: encoding];

	[self writeBuffer: [string cStringWithEncoding: encoding]
		   length: length];

	return length;
}

- (size_t)writeLine: (OFString*)string
{
	return [self writeLine: string
		      encoding: OF_STRING_ENCODING_UTF_8];
}

- (size_t)writeLine: (OFString*)string
	   encoding: (of_string_encoding_t)encoding
{
	size_t stringLength = [string cStringLengthWithEncoding: encoding];
	char *buffer;

	buffer = [self allocMemoryWithSize: stringLength + 1];

	@try {
		memcpy(buffer, [string cStringWithEncoding: encoding],
		    stringLength);
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
		@throw [OFInvalidArgumentException exception];

	if ((length = of_vasprintf(&UTF8String, [format UTF8String],
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		[self writeBuffer: UTF8String
			   length: length];
	} @finally {
		free(UTF8String);
	}

	return length;
}

- (size_t)numberOfBytesInReadBuffer
{
	return _readBufferLength;
}

- (bool)isBlocking
{
	return _blocking;
}

- (void)setBlocking: (bool)enable
{
#ifndef _WIN32
	bool readImplemented = false, writeImplemented = false;

	@try {
		int readFlags;

		readFlags = fcntl([self fileDescriptorForReading], F_GETFL);

		readImplemented = true;

		if (readFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self];

		if (enable)
			readFlags &= ~O_NONBLOCK;
		else
			readFlags |= O_NONBLOCK;

		if (fcntl([self fileDescriptorForReading], F_SETFL,
		    readFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self];
	} @catch (OFNotImplementedException *e) {
	}

	@try {
		int writeFlags;

		writeFlags = fcntl([self fileDescriptorForWriting], F_GETFL);

		writeImplemented = true;

		if (writeFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self];

		if (enable)
			writeFlags &= ~O_NONBLOCK;
		else
			writeFlags |= O_NONBLOCK;

		if (fcntl([self fileDescriptorForWriting], F_SETFL,
		    writeFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self];
	} @catch (OFNotImplementedException *e) {
	}

	if (!readImplemented && !writeImplemented)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	_blocking = enable;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (int)fileDescriptorForReading
{
	OF_UNRECOGNIZED_SELECTOR
}

- (int)fileDescriptorForWriting
{
	OF_UNRECOGNIZED_SELECTOR
}

#ifdef OF_HAVE_SOCKETS
- (void)cancelAsyncRequests
{
	[OFRunLoop OF_cancelAsyncRequestsForStream: self];
}
#endif

- (void)unreadFromBuffer: (const void*)buffer
		  length: (size_t)length
{
	if (length > SIZE_MAX - _readBufferLength)
		@throw [OFOutOfRangeException exception];

	_readBuffer = [self resizeMemory: _readBuffer
				    size: _readBufferLength + length];

	memmove(_readBuffer + length, _readBuffer, _readBufferLength);
	memcpy(_readBuffer, buffer, length);

	_readBufferLength += length;
}

- (void)close
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)OF_isWaitingForDelimiter
{
	return _waitingForDelimiter;
}
@end
