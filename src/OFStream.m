/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#define __NO_EXT_QNX

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#ifdef OF_HAVE_SOCKETS
# import "socket_helpers.h"
#endif

#include "platform.h"

#if !defined(OF_WINDOWS) && !defined(OF_MORPHOS)
# include <signal.h>
#endif

#import "OFStream.h"
#import "OFStream+Private.h"
#import "OFData.h"
#import "OFKernelEventObserver.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFSetOptionFailedException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

#import "of_asprintf.h"

#define MIN_READ_SIZE 512

@implementation OFStream
@synthesize of_waitingForDelimiter = _waitingForDelimiter, delegate = _delegate;

#if defined(SIGPIPE) && defined(SIG_IGN)
+ (void)initialize
{
	if (self == [OFStream class])
		signal(SIGPIPE, SIG_IGN);
}
#endif

- (instancetype)init
{
	if ([self isMemberOfClass: [OFStream class]]) {
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

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)copy
{
	return [self retain];
}

- (bool)isAtEndOfStream
{
	if (_readBufferLength > 0)
		return false;

	return [self lowlevelIsAtEndOfStream];
}

- (size_t)readIntoBuffer: (void *)buffer
		  length: (size_t)length
{
	if (_readBufferLength == 0) {
		/*
		 * For small sizes, it is cheaper to read more and cache the
		 * remainder - even if that means more copying of data - than
		 * to do a syscall for every read.
		 */
		if (length < MIN_READ_SIZE) {
			char tmp[MIN_READ_SIZE], *readBuffer;
			size_t bytesRead;

			bytesRead = [self
			    lowlevelReadIntoBuffer: tmp
					    length: MIN_READ_SIZE];

			if (bytesRead > length) {
				memcpy(buffer, tmp, length);

				readBuffer = [self allocMemoryWithSize:
				    bytesRead - length];
				memcpy(readBuffer, tmp + length,
				    bytesRead - length);

				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bytesRead - length;

				return length;
			} else {
				memcpy(buffer, tmp, bytesRead);
				return bytesRead;
			}
		}

		return [self lowlevelReadIntoBuffer: buffer
					     length: length];
	}

	if (length >= _readBufferLength) {
		size_t ret = _readBufferLength;
		memcpy(buffer, _readBuffer, _readBufferLength);

		[self freeMemory: _readBufferMemory];
		_readBuffer = _readBufferMemory = NULL;
		_readBufferLength = 0;

		return ret;
	} else {
		memcpy(buffer, _readBuffer, length);

		_readBuffer += length;
		_readBufferLength -= length;

		return length;
	}
}

- (void)readIntoBuffer: (void *)buffer
	   exactLength: (size_t)length
{
	size_t readLength = 0;

	while (readLength < length) {
		if (self.atEndOfStream)
			@throw [OFTruncatedDataException exception];

		readLength += [self readIntoBuffer: (char *)buffer + readLength
					    length: length - readLength];
	}
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: of_run_loop_mode_default];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				      block: NULL
# endif
				   delegate: _delegate];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: of_run_loop_mode_default];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				      block: NULL
# endif
				   delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		      block: (of_stream_async_read_block_t)block
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: of_run_loop_mode_default
			    block: block];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		      block: (of_stream_async_read_block_t)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
				      block: block
				   delegate: nil];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		      block: (of_stream_async_read_block_t)block
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: of_run_loop_mode_default
			    block: block];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		      block: (of_stream_async_read_block_t)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
				      block: block
				   delegate: nil];
}
# endif
#endif

- (uint8_t)readInt8
{
	uint8_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 1];

	return ret;
}

- (uint16_t)readBigEndianInt16
{
	uint16_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 2];

	return OF_BSWAP16_IF_LE(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 4];

	return OF_BSWAP32_IF_LE(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 8];

	return OF_BSWAP64_IF_LE(ret);
}

- (float)readBigEndianFloat
{
	float ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 4];

	return OF_BSWAP_FLOAT_IF_LE(ret);
}

- (double)readBigEndianDouble
{
	double ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 8];

	return OF_BSWAP_DOUBLE_IF_LE(ret);
}

- (size_t)readBigEndianInt16sIntoBuffer: (uint16_t *)buffer
				  count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP16(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt32sIntoBuffer: (uint32_t *)buffer
				  count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP32(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianInt64sIntoBuffer: (uint64_t *)buffer
				  count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP64(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianFloatsIntoBuffer: (float *)buffer
				  count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_FLOAT(buffer[i]);
#endif

	return size;
}

- (size_t)readBigEndianDoublesIntoBuffer: (double *)buffer
				   count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifndef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_DOUBLE(buffer[i]);
#endif

	return size;
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 2];

	return OF_BSWAP16_IF_BE(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 4];

	return OF_BSWAP32_IF_BE(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 8];

	return OF_BSWAP64_IF_BE(ret);
}

- (float)readLittleEndianFloat
{
	float ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 4];

	return OF_BSWAP_FLOAT_IF_BE(ret);
}

- (double)readLittleEndianDouble
{
	double ret;

	[self readIntoBuffer: (char *)&ret
		 exactLength: 8];

	return OF_BSWAP_DOUBLE_IF_BE(ret);
}

- (size_t)readLittleEndianInt16sIntoBuffer: (uint16_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP16(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt32sIntoBuffer: (uint32_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP32(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianInt64sIntoBuffer: (uint64_t *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP64(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianFloatsIntoBuffer: (float *)buffer
				     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_FLOAT(buffer[i]);
#endif

	return size;
}

- (size_t)readLittleEndianDoublesIntoBuffer: (double *)buffer
				      count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

	[self readIntoBuffer: buffer
		 exactLength: size];

#ifdef OF_FLOAT_BIG_ENDIAN
	for (size_t i = 0; i < count; i++)
		buffer[i] = OF_BSWAP_DOUBLE(buffer[i]);
#endif

	return size;
}

- (OFData *)readDataWithCount: (size_t)count
{
	return [self readDataWithItemSize: 1
				    count: count];
}

- (OFData *)readDataWithItemSize: (size_t)itemSize
			   count: (size_t)count
{
	OFData *ret;
	char *buffer;

	if OF_UNLIKELY (count > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((buffer = malloc(count * itemSize)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: count * itemSize];

	@try {
		[self readIntoBuffer: buffer
			 exactLength: count * itemSize];

		ret = [OFData dataWithItemsNoCopy: buffer
					 itemSize: itemSize
					    count: count
				     freeWhenDone: true];
	} @catch (id e) {
		free(buffer);
		@throw e;
	}

	return ret;
}

- (OFData *)readDataUntilEndOfStream
{
	OFMutableData *data = [OFMutableData data];
	size_t pageSize = [OFSystemInfo pageSize];
	char *buffer = [self allocMemoryWithSize: pageSize];

	@try {
		while (!self.atEndOfStream) {
			size_t length;

			length = [self readIntoBuffer: buffer
					       length: pageSize];
			[data addItems: buffer
				 count: length];
		}
	} @finally {
		[self freeMemory: buffer];
	}

	[data makeImmutable];

	return data;
}

- (OFString *)readStringWithLength: (size_t)length
{
	return [self readStringWithLength: length
				 encoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString *)readStringWithLength: (size_t)length
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

- (OFString *)tryReadLineWithEncoding: (of_string_encoding_t)encoding
{
	size_t pageSize, bufferLength, retLength;
	char *retCString, *buffer, *readBuffer;
	OFString *ret;

	/* Look if there's a line or \0 in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if OF_UNLIKELY (_readBuffer[i] == '\n' ||
			    _readBuffer[i] == '\0') {
				retLength = i;

				if (i > 0 && _readBuffer[i - 1] == '\r')
					retLength--;

				ret = [OFString stringWithCString: _readBuffer
							 encoding: encoding
							   length: retLength];

				_readBuffer += i + 1;
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

			[self freeMemory: _readBufferMemory];
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a newline or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
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
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = [self
						    allocMemoryWithSize:
						    _readBufferLength +
						    bufferLength];

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						[self freeMemory:
						    _readBufferMemory];
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					[self freeMemory: retCString];
				}

				readBuffer = [self
				    allocMemoryWithSize: bufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				[self freeMemory: _readBufferMemory];
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* There was no newline or \0 */
		if (bufferLength > 0) {
			readBuffer = [self allocMemoryWithSize:
			    _readBufferLength + bufferLength];

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			[self freeMemory: _readBufferMemory];
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		[self freeMemory: buffer];
	}

	_waitingForDelimiter = true;
	return nil;
}

- (OFString *)readLine
{
	return [self readLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString *)readLineWithEncoding: (of_string_encoding_t)encoding
{
	OFString *line = nil;

	while ((line = [self tryReadLineWithEncoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return line;
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadLine
{
	[self asyncReadLineWithEncoding: OF_STRING_ENCODING_UTF_8
			    runLoopMode: of_run_loop_mode_default];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: of_run_loop_mode_default];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
		      runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					  block: NULL
# endif
				       delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadLineWithBlock: (of_stream_async_read_line_block_t)block
{
	[self asyncReadLineWithEncoding: OF_STRING_ENCODING_UTF_8
			    runLoopMode: of_run_loop_mode_default
				  block: block];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
			    block: (of_stream_async_read_line_block_t)block
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: of_run_loop_mode_default
				  block: block];
}

- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
		      runLoopMode: (of_run_loop_mode_t)runLoopMode
			    block: (of_stream_async_read_line_block_t)block
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
					  block: block
				       delegate: nil];
}
# endif
#endif

- (OFString *)tryReadLine
{
	return [self tryReadLineWithEncoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString *)tryReadTillDelimiter: (OFString *)delimiter
			  encoding: (of_string_encoding_t)encoding
{
	const char *delimiterCString;
	size_t j, delimiterLength, pageSize, bufferLength, retLength;
	char *retCString, *buffer, *readBuffer;
	OFString *ret;

	delimiterCString = [delimiter cStringWithEncoding: encoding];
	delimiterLength = [delimiter cStringLengthWithEncoding: encoding];
	j = 0;

	if (delimiterLength == 0)
		@throw [OFInvalidArgumentException exception];

	/* Look if there's something in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if (_readBuffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || _readBuffer[i] == '\0') {
				if (_readBuffer[i] == '\0')
					delimiterLength = 1;

				ret = [OFString
				    stringWithCString: _readBuffer
					     encoding: encoding
					      length: i + 1 - delimiterLength];

				_readBuffer += i + 1;
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

			[self freeMemory: _readBufferMemory];
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

		bufferLength = [self lowlevelReadIntoBuffer: buffer
						     length: pageSize];

		/* Look if there's a delimiter or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
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
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = [self
						    allocMemoryWithSize:
						    _readBufferLength +
						    bufferLength];

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						[self freeMemory:
						    _readBufferMemory];
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					[self freeMemory: retCString];
				}

				readBuffer = [self allocMemoryWithSize:
				    bufferLength - i - 1];
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				[self freeMemory: _readBufferMemory];
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* Neither the delimiter nor \0 was found */
		if (bufferLength > 0) {
			readBuffer = [self allocMemoryWithSize:
			    _readBufferLength + bufferLength];

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			[self freeMemory: _readBufferMemory];
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		[self freeMemory: buffer];
	}

	_waitingForDelimiter = true;
	return nil;
}


- (OFString *)readTillDelimiter: (OFString *)delimiter
{
	return [self readTillDelimiter: delimiter
			      encoding: OF_STRING_ENCODING_UTF_8];
}

- (OFString *)readTillDelimiter: (OFString *)delimiter
		       encoding: (of_string_encoding_t)encoding
{
	OFString *ret = nil;

	while ((ret = [self tryReadTillDelimiter: delimiter
					encoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return ret;
}

- (OFString *)tryReadTillDelimiter: (OFString *)delimiter
{
	return [self tryReadTillDelimiter: delimiter
				 encoding: OF_STRING_ENCODING_UTF_8];
}

- (bool)isWriteBuffered
{
	return _writeBuffered;
}

- (void)setWriteBuffered: (bool)enable
{
	_writeBuffered = enable;
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

- (size_t)writeBuffer: (const void *)buffer
	       length: (size_t)length
{
	if (!_writeBuffered) {
		size_t bytesWritten = [self lowlevelWriteBuffer: buffer
							 length: length];

		if (_blocking && bytesWritten < length)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: bytesWritten
					  errNo: 0];

		return bytesWritten;
	} else {
		_writeBuffer = [self resizeMemory: _writeBuffer
					     size: _writeBufferLength + length];
		memcpy(_writeBuffer + _writeBufferLength, buffer, length);
		_writeBufferLength += length;

		return length;
	}
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncWriteData: (OFData *)data
{
	[self asyncWriteData: data
		 runLoopMode: of_run_loop_mode_default];
}

- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				       block: NULL
# endif
				    delegate: _delegate];
}

- (void)asyncWriteString: (OFString *)string
{
	[self asyncWriteString: string
		      encoding: OF_STRING_ENCODING_UTF_8
		   runLoopMode: of_run_loop_mode_default];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (of_string_encoding_t)encoding
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: of_run_loop_mode_default];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (of_string_encoding_t)encoding
	     runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				       block: NULL
# endif
				    delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncWriteData: (OFData *)data
		 block: (of_stream_async_write_data_block_t)block
{
	[self asyncWriteData: data
		 runLoopMode: of_run_loop_mode_default
		       block: block];
}

- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (of_run_loop_mode_t)runLoopMode
		 block: (of_stream_async_write_data_block_t)block
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
				       block: block
				    delegate: nil];
}

- (void)asyncWriteString: (OFString *)string
		   block: (of_stream_async_write_string_block_t)block
{
	[self asyncWriteString: string
		      encoding: OF_STRING_ENCODING_UTF_8
		   runLoopMode: of_run_loop_mode_default
			 block: block];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (of_string_encoding_t)encoding
		   block: (of_stream_async_write_string_block_t)block
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: of_run_loop_mode_default
			 block: block];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (of_string_encoding_t)encoding
	     runLoopMode: (of_run_loop_mode_t)runLoopMode
		   block: (of_stream_async_write_string_block_t)block
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
				       block: block
				    delegate: nil];
}
# endif
#endif

- (void)writeInt8: (uint8_t)int8
{
	[self writeBuffer: (char *)&int8
		   length: 1];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = OF_BSWAP16_IF_LE(int16);

	[self writeBuffer: (char *)&int16
		   length: 2];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_LE(int32);

	[self writeBuffer: (char *)&int32
		   length: 4];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_LE(int64);

	[self writeBuffer: (char *)&int64
		   length: 8];
}

- (void)writeBigEndianFloat: (float)float_
{
	float_ = OF_BSWAP_FLOAT_IF_LE(float_);

	[self writeBuffer: (char *)&float_
		   length: 4];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = OF_BSWAP_DOUBLE_IF_LE(double_);

	[self writeBuffer: (char *)&double_
		   length: 8];
}

- (size_t)writeBigEndianInt16s: (const uint16_t *)buffer
			 count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp = [self allocMemoryWithSize: sizeof(uint16_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt32s: (const uint32_t *)buffer
			 count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp = [self allocMemoryWithSize: sizeof(uint32_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianInt64s: (const uint64_t *)buffer
			 count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

#ifdef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp = [self allocMemoryWithSize: sizeof(uint64_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianFloats: (const float *)buffer
			 count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp = [self allocMemoryWithSize: sizeof(float)
					 count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_FLOAT(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeBigEndianDoubles: (const double *)buffer
			  count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

#ifdef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp = [self allocMemoryWithSize: sizeof(double)
					  count: count];

	@try {
		for (size_t i = 0; i < count; i++)
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

	[self writeBuffer: (char *)&int16
		   length: 2];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = OF_BSWAP32_IF_BE(int32);

	[self writeBuffer: (char *)&int32
		   length: 4];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = OF_BSWAP64_IF_BE(int64);

	[self writeBuffer: (char *)&int64
		   length: 8];
}

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = OF_BSWAP_FLOAT_IF_BE(float_);

	[self writeBuffer: (char *)&float_
		   length: 4];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = OF_BSWAP_DOUBLE_IF_BE(double_);

	[self writeBuffer: (char *)&double_
		   length: 8];
}

- (size_t)writeLittleEndianInt16s: (const uint16_t *)buffer
			    count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint16_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint16_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint16_t *tmp = [self allocMemoryWithSize: sizeof(uint16_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP16(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt32s: (const uint32_t *)buffer
			    count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint32_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint32_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint32_t *tmp = [self allocMemoryWithSize: sizeof(uint32_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP32(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianInt64s: (const uint64_t *)buffer
			    count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(uint64_t))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(uint64_t);

#ifndef OF_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	uint64_t *tmp = [self allocMemoryWithSize: sizeof(uint64_t)
					    count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP64(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianFloats: (const float *)buffer
			    count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(float))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(float);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	float *tmp = [self allocMemoryWithSize: sizeof(float)
					 count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_FLOAT(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeLittleEndianDoubles: (const double *)buffer
			     count: (size_t)count
{
	size_t size;

	if OF_UNLIKELY (count > SIZE_MAX / sizeof(double))
		@throw [OFOutOfRangeException exception];

	size = count * sizeof(double);

#ifndef OF_FLOAT_BIG_ENDIAN
	[self writeBuffer: buffer
		   length: size];
#else
	double *tmp = [self allocMemoryWithSize: sizeof(double)
					  count: count];

	@try {
		for (size_t i = 0; i < count; i++)
			tmp[i] = OF_BSWAP_DOUBLE(buffer[i]);

		[self writeBuffer: tmp
			   length: size];
	} @finally {
		[self freeMemory: tmp];
	}
#endif

	return size;
}

- (size_t)writeData: (OFData *)data
{
	void *pool;
	size_t length;

	if (data == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	length = data.count * data.itemSize;

	[self writeBuffer: data.items
		   length: length];

	objc_autoreleasePoolPop(pool);

	return length;
}

- (size_t)writeString: (OFString *)string
{
	return [self writeString: string
			encoding: OF_STRING_ENCODING_UTF_8];
}

- (size_t)writeString: (OFString *)string
	     encoding: (of_string_encoding_t)encoding
{
	void *pool;
	size_t length;

	if (string == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	length = [string cStringLengthWithEncoding: encoding];

	[self writeBuffer: [string cStringWithEncoding: encoding]
		   length: length];

	objc_autoreleasePoolPop(pool);

	return length;
}

- (size_t)writeLine: (OFString *)string
{
	return [self writeLine: string
		      encoding: OF_STRING_ENCODING_UTF_8];
}

- (size_t)writeLine: (OFString *)string
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

- (size_t)writeFormat: (OFConstantString *)format, ...
{
	va_list arguments;
	size_t ret;

	va_start(arguments, format);
	ret = [self writeFormat: format
		      arguments: arguments];
	va_end(arguments);

	return ret;
}

- (size_t)writeFormat: (OFConstantString *)format
	    arguments: (va_list)arguments
{
	char *UTF8String;
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((length = of_vasprintf(&UTF8String, format.UTF8String,
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

- (bool)hasDataInReadBuffer
{
	return (_readBufferLength > 0);
}

- (bool)isBlocking
{
	return _blocking;
}

- (void)setBlocking: (bool)enable
{
#if defined(HAVE_FCNTL) && !defined(OF_AMIGAOS)
	bool readImplemented = false, writeImplemented = false;

	@try {
		int readFlags;

		readFlags = fcntl(((id <OFReadyForReadingObserving>)self)
		    .fileDescriptorForReading, F_GETFL, 0);

		readImplemented = true;

		if (readFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];

		if (enable)
			readFlags &= ~O_NONBLOCK;
		else
			readFlags |= O_NONBLOCK;

		if (fcntl(((id <OFReadyForReadingObserving>)self)
		    .fileDescriptorForReading, F_SETFL, readFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];
	} @catch (OFNotImplementedException *e) {
	}

	@try {
		int writeFlags;

		writeFlags = fcntl(((id <OFReadyForWritingObserving>)self)
		    .fileDescriptorForWriting, F_GETFL, 0);

		writeImplemented = true;

		if (writeFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];

		if (enable)
			writeFlags &= ~O_NONBLOCK;
		else
			writeFlags |= O_NONBLOCK;

		if (fcntl(((id <OFReadyForWritingObserving>)self)
		    .fileDescriptorForWriting, F_SETFL, writeFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: self
					  errNo: errno];
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
	[OFRunLoop of_cancelAsyncRequestsForObject: self
					      mode: of_run_loop_mode_default];
}
#endif

- (void)unreadFromBuffer: (const void *)buffer
		  length: (size_t)length
{
	char *readBuffer;

	if (length > SIZE_MAX - _readBufferLength)
		@throw [OFOutOfRangeException exception];

	readBuffer = [self allocMemoryWithSize: _readBufferLength + length];
	memcpy(readBuffer, buffer, length);
	memcpy(readBuffer + length, _readBuffer, _readBufferLength);

	[self freeMemory: _readBufferMemory];
	_readBuffer = _readBufferMemory = readBuffer;
	_readBufferLength += length;
}

- (void)close
{
	[self freeMemory: _readBufferMemory];
	_readBuffer = _readBufferMemory = NULL;
	_readBufferLength = 0;

	[self freeMemory: _writeBuffer];
	_writeBuffer = NULL;
	_writeBufferLength = 0;
	_writeBuffered = false;

	_waitingForDelimiter = false;
}
@end
