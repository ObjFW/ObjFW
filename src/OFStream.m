/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#include "platform.h"

#if !defined(OF_WINDOWS) && !defined(OF_MORPHOS)
# include <signal.h>
#endif

#import "OFStream.h"
#import "OFStream+Private.h"
#import "OFASPrintF.h"
#import "OFData.h"
#import "OFKernelEventObserver.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#ifdef OF_HAVE_SOCKETS
# import "OFSocket+Private.h"
#endif
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

#define minReadSize 512

@implementation OFStream
@synthesize buffersWrites = _buffersWrites;
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
	self = [super init];

	@try {
		if (self.class == [OFStream class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		_canBlock = true;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_readBufferMemory);
	OFFreeMemory(_writeBuffer);

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)lowlevelIsAtEndOfStream
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)lowlevelHasDataInReadBuffer
{
	return false;
}

- (id)copy
{
	return objc_retain(self);
}

- (bool)isAtEndOfStream
{
	if (_readBufferLength > 0)
		return false;

	return [self lowlevelIsAtEndOfStream];
}

- (size_t)readIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_readBufferLength == 0) {
		/*
		 * For small sizes, it is cheaper to read more and cache the
		 * remainder - even if that means more copying of data - than
		 * to do a syscall for every read.
		 */
		if (length < minReadSize) {
			char tmp[minReadSize], *readBuffer;
			size_t bytesRead;

retry_1:
			@try {
				bytesRead = [self
				    lowlevelReadIntoBuffer: tmp
						    length: minReadSize];
			} @catch (OFReadFailedException *e) {
				if (e.errNo == EINTR)
					goto retry_1;

				@throw e;
			}

			if (bytesRead > length) {
				memcpy(buffer, tmp, length);

				readBuffer = OFAllocMemory(bytesRead - length,
				    1);
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

retry_2:
		@try {
			return [self lowlevelReadIntoBuffer: buffer
						     length: length];
		} @catch (OFReadFailedException *e) {
			if (e.errNo == EINTR)
				goto retry_2;

			@throw e;
		}
	}

	if (length >= _readBufferLength) {
		size_t ret = _readBufferLength;
		memcpy(buffer, _readBuffer, _readBufferLength);

		OFFreeMemory(_readBufferMemory);
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

- (void)readIntoBuffer: (void *)buffer exactLength: (size_t)length
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
- (void)asyncReadIntoBuffer: (void *)buffer length: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				    handler: NULL
# endif
				   delegate: _delegate];
}

- (void)asyncReadIntoBuffer: (void *)buffer exactLength: (size_t)length
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				    handler: NULL
# endif
				   delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		      block: (OFStreamAsyncReadBlock)block
{
	OFStreamReadHandler handler = ^ (OFStream *stream, void *buffer_,
	    size_t length_, id exception) {
		return block(length, exception);
	};

	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: OFDefaultRunLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		    handler: (OFStreamReadHandler)handler
{
	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: OFDefaultRunLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block
{
	OFStreamReadHandler handler = ^ (OFStream *stream, void *buffer_,
	    size_t length_, id exception) {
		return block(length, exception);
	};

	[self asyncReadIntoBuffer: buffer
			   length: length
		      runLoopMode: runLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		    handler: (OFStreamReadHandler)handler
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				     length: length
				       mode: runLoopMode
				    handler: handler
				   delegate: nil];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		      block: (OFStreamAsyncReadBlock)block
{
	OFStreamReadHandler handler = ^ (OFStream *stream, void *buffer_,
	    size_t length_, id exception) {
		return block(length, exception);
	};

	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: OFDefaultRunLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		    handler: (OFStreamReadHandler)handler
{
	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: OFDefaultRunLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block
{
	OFStreamReadHandler handler = ^ (OFStream *stream, void *buffer_,
	    size_t length_, id exception) {
		return block(length, exception);
	};

	[self asyncReadIntoBuffer: buffer
		      exactLength: length
		      runLoopMode: runLoopMode
			  handler: handler];
}

- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		    handler: (OFStreamReadHandler)handler
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadForStream: stream
				     buffer: buffer
				exactLength: length
				       mode: runLoopMode
				    handler: handler
				   delegate: nil];
}
# endif
#endif

- (uint8_t)readInt8
{
	uint8_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 1];
	return ret;
}

- (uint16_t)readBigEndianInt16
{
	uint16_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 2];
	return OFFromBigEndian16(ret);
}

- (uint32_t)readBigEndianInt32
{
	uint32_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromBigEndian32(ret);
}

- (uint64_t)readBigEndianInt64
{
	uint64_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromBigEndian64(ret);
}

- (float)readBigEndianFloat
{
	float ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromBigEndianFloat(ret);
}

- (double)readBigEndianDouble
{
	double ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromBigEndianDouble(ret);
}

- (uint16_t)readLittleEndianInt16
{
	uint16_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 2];
	return OFFromLittleEndian16(ret);
}

- (uint32_t)readLittleEndianInt32
{
	uint32_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromLittleEndian32(ret);
}

- (uint64_t)readLittleEndianInt64
{
	uint64_t ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromLittleEndian64(ret);
}

- (float)readLittleEndianFloat
{
	float ret;
	[self readIntoBuffer: (char *)&ret exactLength: 4];
	return OFFromLittleEndianFloat(ret);
}

- (double)readLittleEndianDouble
{
	double ret;
	[self readIntoBuffer: (char *)&ret exactLength: 8];
	return OFFromLittleEndianDouble(ret);
}

- (OFData *)readDataWithCount: (size_t)count
{
	return [self readDataWithItemSize: 1 count: count];
}

- (OFData *)readDataWithItemSize: (size_t)itemSize count: (size_t)count
{
	OFData *ret;
	char *buffer;

	if OF_UNLIKELY (count > SIZE_MAX / itemSize)
		@throw [OFOutOfRangeException exception];

	buffer = OFAllocMemory(count, itemSize);
	@try {
		[self readIntoBuffer: buffer exactLength: count * itemSize];
		ret = [OFData dataWithItemsNoCopy: buffer
					    count: count
					 itemSize: itemSize
				     freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
}

- (OFData *)readDataUntilEndOfStream
{
	OFMutableData *data = [OFMutableData data];
	const size_t bufferSize = 16384;
	char *buffer = OFAllocMemory(1, bufferSize);

	@try {
		while (!self.atEndOfStream) {
			size_t length =
			    [self readIntoBuffer: buffer length: bufferSize];
			[data addItems: buffer count: length];
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	[data makeImmutable];
	return data;
}

- (OFString *)readString
{
	return [self readStringWithEncoding: (OFStringEncoding)_encoding];
}

- (OFString *)readStringWithEncoding: (OFStringEncoding)encoding
{
	OFString *string = nil;

	while ((string = [self tryReadStringWithEncoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return string;
}

- (OFString *)readStringWithLength: (size_t)length
{
	return [self readStringWithLength: length
				 encoding: (OFStringEncoding)_encoding];
}

- (OFString *)readStringWithLength: (size_t)length
			  encoding: (OFStringEncoding)encoding
{
	OFString *ret;
	char *buffer = OFAllocMemory(length + 1, 1);
	buffer[length] = 0;

	@try {
		[self readIntoBuffer: buffer exactLength: length];
		ret = [OFString stringWithCString: buffer encoding: encoding];
	} @finally {
		OFFreeMemory(buffer);
	}

	return ret;
}

- (OFString *)tryReadLineWithEncoding: (OFStringEncoding)encoding
{
	size_t pageSize, bufferLength;
	char *buffer, *readBuffer;
	OFString *ret;

	/* Look if there's a line or \0 in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if OF_UNLIKELY (_readBuffer[i] == '\n' ||
			    _readBuffer[i] == '\0') {
				size_t retLength = i;

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
	buffer = OFAllocMemory(1, pageSize);

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			size_t retLength;

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

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

retry:
		@try {
			bufferLength = [self lowlevelReadIntoBuffer: buffer
							     length: pageSize];
		} @catch (OFReadFailedException *e) {
			if (e.errNo == EINTR)
				goto retry;

			@throw e;
		}

		/* Look if there's a newline or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
			if OF_UNLIKELY (buffer[i] == '\n' ||
			    buffer[i] == '\0') {
				size_t retLength = _readBufferLength + i;
				char *retCString = OFAllocMemory(retLength, 1);

				if (_readBuffer != NULL)
					memcpy(retCString, _readBuffer,
					    _readBufferLength);
				memcpy(retCString + _readBufferLength,
				    buffer, i);

				if (retLength > 0 &&
				    retCString[retLength - 1] == '\r')
					retLength--;

				@try {
					ret = [OFString
					    stringWithCString: retCString
						     encoding: encoding
						       length: retLength];
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = OFAllocMemory(
						    _readBufferLength +
						    bufferLength, 1);

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						OFFreeMemory(_readBufferMemory);
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					OFFreeMemory(retCString);
				}

				readBuffer = OFAllocMemory(bufferLength - i - 1,
				    1);
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				OFFreeMemory(_readBufferMemory);
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* There was no newline or \0 */
		if (bufferLength > 0) {
			readBuffer = OFAllocMemory(
			    _readBufferLength + bufferLength, 1);

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	_waitingForDelimiter = true;
	return nil;
}

- (OFString *)readLine
{
	return [self readLineWithEncoding: (OFStringEncoding)_encoding];
}

- (OFString *)readLineWithEncoding: (OFStringEncoding)encoding
{
	OFString *line = nil;

	while ((line = [self tryReadLineWithEncoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return line;
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncReadString
{
	[self asyncReadStringWithEncoding: (OFStringEncoding)_encoding
			      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
{
	[self asyncReadStringWithEncoding: encoding
			      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
			runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadStringForStream: stream
					 encoding: encoding
					     mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					  handler: NULL
# endif
					 delegate: _delegate];
}

- (void)asyncReadLine
{
	[self asyncReadLineWithEncoding: (OFStringEncoding)_encoding
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					handler: NULL
# endif
				       delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncReadStringWithHandler: (OFStreamStringReadHandler)handler
{
	[self asyncReadStringWithEncoding: (OFStringEncoding)_encoding
			      runLoopMode: OFDefaultRunLoopMode
				  handler: handler];
}

- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
			    handler: (OFStreamStringReadHandler)handler
{
	[self asyncReadStringWithEncoding: encoding
			      runLoopMode: OFDefaultRunLoopMode
				  handler: handler];
}

- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
			runLoopMode: (OFRunLoopMode)runLoopMode
			    handler: (OFStreamStringReadHandler)handler
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadStringForStream: stream
					 encoding: encoding
					     mode: runLoopMode
					  handler: handler
					 delegate: nil];
}

- (void)asyncReadLineWithBlock: (OFStreamAsyncReadLineBlock)block
{
	OFStreamStringReadHandler handler = ^ (OFStream *stream,
	    OFString *string, id exception) {
		return block(string, exception);
	};

	[self asyncReadLineWithEncoding: (OFStringEncoding)_encoding
			    runLoopMode: OFDefaultRunLoopMode
				handler: handler];
}

- (void)asyncReadLineWithHandler: (OFStreamStringReadHandler)handler
{
	[self asyncReadLineWithEncoding: (OFStringEncoding)_encoding
			    runLoopMode: OFDefaultRunLoopMode
				handler: handler];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
			    block: (OFStreamAsyncReadLineBlock)block
{
	OFStreamStringReadHandler handler = ^ (OFStream *stream,
	    OFString *string, id exception) {
		return block(string, exception);
	};

	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: OFDefaultRunLoopMode
				handler: handler];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
			  handler: (OFStreamStringReadHandler)handler
{
	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: OFDefaultRunLoopMode
				handler: handler];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
			    block: (OFStreamAsyncReadLineBlock)block
{
	OFStreamStringReadHandler handler = ^ (OFStream *stream,
	    OFString *string, id exception) {
		return block(string, exception);
	};

	[self asyncReadLineWithEncoding: encoding
			    runLoopMode: runLoopMode
				handler: handler];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
			  handler: (OFStreamStringReadHandler)handler
{
	OFStream <OFReadyForReadingObserving> *stream =
	    (OFStream <OFReadyForReadingObserving> *)self;

	[OFRunLoop of_addAsyncReadLineForStream: stream
				       encoding: encoding
					   mode: runLoopMode
					handler: handler
				       delegate: nil];
}
# endif
#endif

- (OFString *)tryReadString
{
	return [self tryReadStringWithEncoding: (OFStringEncoding)_encoding];
}

- (OFString *)tryReadStringWithEncoding: (OFStringEncoding)encoding
{
	size_t pageSize, bufferLength;
	char *buffer, *readBuffer;
	OFString *ret;

	/* Look if there's something in our buffer */
	if (!_waitingForDelimiter && _readBuffer != NULL) {
		for (size_t i = 0; i < _readBufferLength; i++) {
			if (_readBuffer[i] == '\0') {
				ret = [OFString
				    stringWithCString: _readBuffer
					     encoding: encoding
					       length: i];

				_readBuffer += i + 1;
				_readBufferLength -= i + 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}
	}

	/* Read and see if we got a \0 */
	pageSize = [OFSystemInfo pageSize];
	buffer = OFAllocMemory(1, pageSize);

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: _readBufferLength];

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

retry:
		@try {
			bufferLength = [self lowlevelReadIntoBuffer: buffer
							     length: pageSize];
		} @catch (OFReadFailedException *e) {
			if (e.errNo == EINTR)
				goto retry;

			@throw e;
		}

		/* Look if there's a \0 */
		for (size_t i = 0; i < bufferLength; i++) {
			if (buffer[i] == '\0') {
				size_t retLength;
				char *retCString;

				retLength = _readBufferLength + i;
				retCString = OFAllocMemory(retLength, 1);

				memcpy(retCString, _readBuffer,
				    _readBufferLength);
				memcpy(retCString + _readBufferLength,
				    buffer, i);

				@try {
					ret = [OFString
					    stringWithCString: retCString
						     encoding: encoding
						       length: retLength];
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = OFAllocMemory(
						    _readBufferLength +
						    bufferLength, 1);

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						OFFreeMemory(_readBufferMemory);
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					OFFreeMemory(retCString);
				}

				readBuffer = OFAllocMemory(bufferLength - i - 1,
				    1);
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				OFFreeMemory(_readBufferMemory);
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* No \0 was found */
		if (bufferLength > 0) {
			readBuffer = OFAllocMemory(
			    _readBufferLength + bufferLength, 1);

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	_waitingForDelimiter = true;
	return nil;
}

- (OFString *)tryReadLine
{
	return [self tryReadLineWithEncoding: (OFStringEncoding)_encoding];
}

- (OFString *)tryReadUntilDelimiter: (OFString *)delimiter
			   encoding: (OFStringEncoding)encoding
{
	const char *delimiterCString;
	size_t j, delimiterLength, pageSize, bufferLength;
	char *buffer, *readBuffer;
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
	buffer = OFAllocMemory(1, pageSize);

	@try {
		if ([self lowlevelIsAtEndOfStream]) {
			if (_readBuffer == NULL) {
				_waitingForDelimiter = false;
				return nil;
			}

			ret = [OFString stringWithCString: _readBuffer
						 encoding: encoding
						   length: _readBufferLength];

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = NULL;
			_readBufferLength = 0;

			_waitingForDelimiter = false;
			return ret;
		}

retry:
		@try {
			bufferLength = [self lowlevelReadIntoBuffer: buffer
							     length: pageSize];
		} @catch (OFReadFailedException *e) {
			if (e.errNo == EINTR)
				goto retry;

			@throw e;
		}

		/* Look if there's a delimiter or \0 */
		for (size_t i = 0; i < bufferLength; i++) {
			if (buffer[i] != delimiterCString[j++])
				j = 0;

			if (j == delimiterLength || buffer[i] == '\0') {
				size_t retLength;
				char *retCString;

				if (buffer[i] == '\0')
					delimiterLength = 1;

				retLength = _readBufferLength + i + 1 -
				    delimiterLength;
				retCString = OFAllocMemory(retLength, 1);

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
					ret = [OFString
					    stringWithCString: retCString
						     encoding: encoding
						       length: retLength];
				} @catch (id e) {
					if (bufferLength > 0) {
						/*
						 * Append data to _readBuffer
						 * to prevent loss of data.
						 */
						readBuffer = OFAllocMemory(
						    _readBufferLength +
						    bufferLength, 1);

						memcpy(readBuffer, _readBuffer,
						    _readBufferLength);
						memcpy(readBuffer +
						    _readBufferLength,
						    buffer, bufferLength);

						OFFreeMemory(_readBufferMemory);
						_readBuffer = readBuffer;
						_readBufferMemory = readBuffer;
						_readBufferLength +=
						    bufferLength;
					}

					@throw e;
				} @finally {
					OFFreeMemory(retCString);
				}

				readBuffer = OFAllocMemory(bufferLength - i - 1,
				    1);
				if (readBuffer != NULL)
					memcpy(readBuffer, buffer + i + 1,
					    bufferLength - i - 1);

				OFFreeMemory(_readBufferMemory);
				_readBuffer = _readBufferMemory = readBuffer;
				_readBufferLength = bufferLength - i - 1;

				_waitingForDelimiter = false;
				return ret;
			}
		}

		/* Neither the delimiter nor \0 was found */
		if (bufferLength > 0) {
			readBuffer = OFAllocMemory(
			    _readBufferLength + bufferLength, 1);

			memcpy(readBuffer, _readBuffer, _readBufferLength);
			memcpy(readBuffer + _readBufferLength,
			    buffer, bufferLength);

			OFFreeMemory(_readBufferMemory);
			_readBuffer = _readBufferMemory = readBuffer;
			_readBufferLength += bufferLength;
		}
	} @finally {
		OFFreeMemory(buffer);
	}

	_waitingForDelimiter = true;
	return nil;
}

- (OFString *)readUntilDelimiter: (OFString *)delimiter
{
	return [self readUntilDelimiter: delimiter
			       encoding: (OFStringEncoding)_encoding];
}

- (OFString *)readUntilDelimiter: (OFString *)delimiter
			encoding: (OFStringEncoding)encoding
{
	OFString *ret = nil;

	while ((ret = [self tryReadUntilDelimiter: delimiter
					 encoding: encoding]) == nil)
		if (self.atEndOfStream)
			return nil;

	return ret;
}

- (OFString *)tryReadUntilDelimiter: (OFString *)delimiter
{
	return [self tryReadUntilDelimiter: delimiter
				  encoding: (OFStringEncoding)_encoding];
}

- (bool)flushWriteBuffer
{
	size_t bytesWritten;

	if (_writeBuffer == NULL)
		return true;

retry:
	@try {
		bytesWritten = [self lowlevelWriteBuffer: _writeBuffer
						  length: _writeBufferLength];
	} @catch (OFWriteFailedException *e) {
		if (e.errNo == EINTR)
			goto retry;

		@throw e;
	}

	if (bytesWritten == 0)
		return false;

	if (bytesWritten == _writeBufferLength) {
		OFFreeMemory(_writeBuffer);
		_writeBuffer = NULL;
		_writeBufferLength = 0;

		return true;
	}

	OFEnsure(bytesWritten <= _writeBufferLength);

	memmove(_writeBuffer, _writeBuffer + bytesWritten,
	    _writeBufferLength - bytesWritten);
	_writeBufferLength -= bytesWritten;
	@try {
		_writeBuffer = OFResizeMemory(_writeBuffer,
		    _writeBufferLength, 1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller. */
	}

	return false;
}

- (void)writeBuffer: (const void *)buffer length: (size_t)length
{
	if (!_buffersWrites) {
		size_t bytesWritten;

retry:
		@try {
			bytesWritten = [self lowlevelWriteBuffer: buffer
							  length: length];
		} @catch (OFWriteFailedException *e) {
			if (e.errNo == EINTR)
				goto retry;

			@throw e;
		}

		if (bytesWritten < length)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: bytesWritten
					  errNo: 0];
	} else {
		if (SIZE_MAX - _writeBufferLength < length)
			@throw [OFOutOfRangeException exception];

		_writeBuffer = OFResizeMemory(_writeBuffer,
		    _writeBufferLength + length, 1);
		memcpy(_writeBuffer + _writeBufferLength, buffer, length);
		_writeBufferLength += length;
	}
}

#ifdef OF_HAVE_SOCKETS
- (void)asyncWriteData: (OFData *)data
{
	[self asyncWriteData: data runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteData: (OFData *)data runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				     handler: NULL
# endif
				    delegate: _delegate];
}

- (void)asyncWriteString: (OFString *)string
{
	[self asyncWriteString: string
		      encoding: (OFStringEncoding)_encoding
		   runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
				     handler: NULL
# endif
				    delegate: _delegate];
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncWriteData: (OFData *)data block: (OFStreamAsyncWriteDataBlock)block
{
	OFStreamDataWrittenHandler handler = ^ (OFStream *stream, OFData *data_,
	    size_t bytesWritten, id exception) {
		return block(bytesWritten, exception);
	};

	[self asyncWriteData: data
		 runLoopMode: OFDefaultRunLoopMode
		     handler: handler];
}

- (void)asyncWriteData: (OFData *)data
	       handler: (OFStreamDataWrittenHandler)handler
{
	[self asyncWriteData: data
		 runLoopMode: OFDefaultRunLoopMode
		     handler: handler];
}

- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (OFRunLoopMode)runLoopMode
		 block: (OFStreamAsyncWriteDataBlock)block
{
	OFStreamDataWrittenHandler handler = ^ (OFStream *stream, OFData *data_,
	    size_t bytesWritten, id exception) {
		return block(bytesWritten, exception);
	};

	[self asyncWriteData: data
		 runLoopMode: runLoopMode
		     handler: handler];
}

- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (OFRunLoopMode)runLoopMode
	       handler: (OFStreamDataWrittenHandler)handler
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
					data: data
					mode: runLoopMode
				     handler: handler
				    delegate: nil];
}

- (void)asyncWriteString: (OFString *)string
		   block: (OFStreamAsyncWriteStringBlock)block
{
	OFStreamStringWrittenHandler handler = ^ (OFStream *stream,
	    OFString *string_, OFStringEncoding encoding_, size_t bytesWritten,
	    id exception) {
		return block(bytesWritten, exception);
	};

	[self asyncWriteString: string
		      encoding: (OFStringEncoding)_encoding
		   runLoopMode: OFDefaultRunLoopMode
		       handler: handler];
}

- (void)asyncWriteString: (OFString *)string
		 handler: (OFStreamStringWrittenHandler)handler
{
	[self asyncWriteString: string
		      encoding: (OFStringEncoding)_encoding
		   runLoopMode: OFDefaultRunLoopMode
		       handler: handler];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
		   block: (OFStreamAsyncWriteStringBlock)block
{
	OFStreamStringWrittenHandler handler = ^ (OFStream *stream,
	    OFString *string_, OFStringEncoding encoding_, size_t bytesWritten,
	    id exception) {
		return block(bytesWritten, exception);
	};

	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: OFDefaultRunLoopMode
		       handler: handler];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
		 handler: (OFStreamStringWrittenHandler)handler
{
	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: OFDefaultRunLoopMode
		       handler: handler];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
		   block: (OFStreamAsyncWriteStringBlock)block
{
	OFStreamStringWrittenHandler handler = ^ (OFStream *stream,
	    OFString *string_, OFStringEncoding encoding_, size_t bytesWritten,
	    id exception) {
		return block(bytesWritten, exception);
	};

	[self asyncWriteString: string
		      encoding: encoding
		   runLoopMode: runLoopMode
		       handler: handler];
}

- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
		 handler: (OFStreamStringWrittenHandler)handler
{
	OFStream <OFReadyForWritingObserving> *stream =
	    (OFStream <OFReadyForWritingObserving> *)self;

	[OFRunLoop of_addAsyncWriteForStream: stream
				      string: string
				    encoding: encoding
					mode: runLoopMode
				     handler: handler
				    delegate: nil];
}
# endif
#endif

- (void)writeInt8: (uint8_t)int8
{
	[self writeBuffer: (char *)&int8 length: 1];
}

- (void)writeBigEndianInt16: (uint16_t)int16
{
	int16 = OFToBigEndian16(int16);
	[self writeBuffer: (char *)&int16 length: 2];
}

- (void)writeBigEndianInt32: (uint32_t)int32
{
	int32 = OFToBigEndian32(int32);
	[self writeBuffer: (char *)&int32 length: 4];
}

- (void)writeBigEndianInt64: (uint64_t)int64
{
	int64 = OFToBigEndian64(int64);
	[self writeBuffer: (char *)&int64 length: 8];
}

- (void)writeBigEndianFloat: (float)float_
{
	float_ = OFToBigEndianFloat(float_);
	[self writeBuffer: (char *)&float_ length: 4];
}

- (void)writeBigEndianDouble: (double)double_
{
	double_ = OFToBigEndianDouble(double_);
	[self writeBuffer: (char *)&double_ length: 8];
}

- (void)writeLittleEndianInt16: (uint16_t)int16
{
	int16 = OFToLittleEndian16(int16);
	[self writeBuffer: (char *)&int16 length: 2];
}

- (void)writeLittleEndianInt32: (uint32_t)int32
{
	int32 = OFToLittleEndian32(int32);
	[self writeBuffer: (char *)&int32 length: 4];
}

- (void)writeLittleEndianInt64: (uint64_t)int64
{
	int64 = OFToLittleEndian64(int64);
	[self writeBuffer: (char *)&int64 length: 8];
}

- (void)writeLittleEndianFloat: (float)float_
{
	float_ = OFToLittleEndianFloat(float_);
	[self writeBuffer: (char *)&float_ length: 4];
}

- (void)writeLittleEndianDouble: (double)double_
{
	double_ = OFToLittleEndianDouble(double_);
	[self writeBuffer: (char *)&double_ length: 8];
}

- (void)writeData: (OFData *)data
{
	void *pool;
	size_t length;

	if (data == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	length = data.count * data.itemSize;
	[self writeBuffer: data.items length: length];

	objc_autoreleasePoolPop(pool);
}

- (void)writeString: (OFString *)string
{
	[self writeString: string encoding: (OFStringEncoding)_encoding];
}

- (void)writeString: (OFString *)string encoding: (OFStringEncoding)encoding
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
}

- (void)writeLine: (OFString *)string
{
	[self writeLine: string encoding: (OFStringEncoding)_encoding];
}

- (void)writeLine: (OFString *)string encoding: (OFStringEncoding)encoding
{
	size_t stringLength = [string cStringLengthWithEncoding: encoding];
	char *buffer;

	buffer = OFAllocMemory(stringLength + 1, 1);

	@try {
		memcpy(buffer, [string cStringWithEncoding: encoding],
		    stringLength);
		buffer[stringLength] = '\n';

		[self writeBuffer: buffer length: stringLength + 1];
	} @finally {
		OFFreeMemory(buffer);
	}
}

- (void)writeFormat: (OFConstantString *)format, ...
{
	va_list arguments;

	va_start(arguments, format);
	[self writeFormat: format arguments: arguments];
	va_end(arguments);
}

- (void)writeFormat: (OFConstantString *)format arguments: (va_list)arguments
{
	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if (_encoding == OFStringEncodingUTF8) {
		char *UTF8String;
		int length;

		if ((length = _OFVASPrintF(&UTF8String, format.UTF8String,
		    arguments)) == -1)
			@throw [OFInvalidFormatException exception];

		@try {
			[self writeBuffer: UTF8String length: length];
		} @finally {
			free(UTF8String);
		}
	} else {
		OFString *string = [[OFString alloc] initWithFormat: format
							  arguments: arguments];

		@try {
			[self writeString: string];
		} @finally {
			objc_release(string);
		}
	}
}

- (bool)hasDataInReadBuffer
{
	return (_readBufferLength > 0 || [self lowlevelHasDataInReadBuffer]);
}

- (OFStringEncoding)encoding
{
	return (OFStringEncoding)_encoding;
}

- (void)setEncoding: (OFStringEncoding)encoding
{
	_encoding = encoding;
}

- (bool)canBlock
{
	return _canBlock;
}

- (void)setCanBlock: (bool)canBlock
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

		if (canBlock)
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

		if (canBlock)
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

	_canBlock = canBlock;
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
					      mode: OFDefaultRunLoopMode];
}
#endif

- (void)unreadFromBuffer: (const void *)buffer length: (size_t)length
{
	char *readBuffer;

	if (length > SIZE_MAX - _readBufferLength)
		@throw [OFOutOfRangeException exception];

	readBuffer = OFAllocMemory(_readBufferLength + length, 1);
	memcpy(readBuffer, buffer, length);
	memcpy(readBuffer + length, _readBuffer, _readBufferLength);

	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = readBuffer;
	_readBufferLength += length;
}

- (void)close
{
	OFFreeMemory(_readBufferMemory);
	_readBuffer = _readBufferMemory = NULL;
	_readBufferLength = 0;

	OFFreeMemory(_writeBuffer);
	_writeBuffer = NULL;
	_writeBufferLength = 0;
	_buffersWrites = false;

	_waitingForDelimiter = false;
}
@end
