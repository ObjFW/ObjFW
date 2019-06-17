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

#include "config.h"

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

@interface OFTarArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	uint64_t _toRead;
	bool _atEndOfStream, _skipped;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry;
- (void)of_skip;
@end

@interface OFTarArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	uint64_t _toWrite;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry;
@end

@implementation OFTarArchive: OFObject
@synthesize encoding = _encoding;

+ (instancetype)archiveWithStream: (OFStream *)stream
			     mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream
					mode: mode] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)archiveWithPath: (OFString *)path
			   mode: (OFString *)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode
{
	self = [super init];

	@try {
		_stream = [stream retain];

		if ([mode isEqual: @"r"])
			_mode = OF_TAR_ARCHIVE_MODE_READ;
		else if ([mode isEqual: @"w"])
			_mode = OF_TAR_ARCHIVE_MODE_WRITE;
		else if ([mode isEqual: @"a"])
			_mode = OF_TAR_ARCHIVE_MODE_APPEND;
		else
			@throw [OFInvalidArgumentException exception];

		if (_mode == OF_TAR_ARCHIVE_MODE_APPEND) {
			union {
				char c[1024];
				uint32_t u32[1024 / sizeof(uint32_t)];
			} buffer;
			bool empty = true;

			if (![_stream isKindOfClass: [OFSeekableStream class]])
				@throw [OFInvalidArgumentException exception];

			[(OFSeekableStream *)_stream seekToOffset: -1024
							   whence: SEEK_END];
			[_stream readIntoBuffer: buffer.c
				    exactLength: 1024];

			for (size_t i = 0; i < 1024 / sizeof(uint32_t); i++)
				if (buffer.u32[i] != 0)
					empty = false;

			if (!empty)
				@throw [OFInvalidFormatException exception];

			[(OFSeekableStream *)stream seekToOffset: -1024
							  whence: SEEK_END];
		}

		_encoding = OF_STRING_ENCODING_UTF_8;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode
{
	OFFile *file;

	if ([mode isEqual: @"a"])
		file = [[OFFile alloc] initWithPath: path
					       mode: @"r+"];
	else
		file = [[OFFile alloc] initWithPath: path
					       mode: mode];

	@try {
		self = [self initWithStream: file
				       mode: mode];
	} @finally {
		[file release];
	}

	return self;
}
#endif

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	OFTarArchiveEntry *entry;
	union {
		unsigned char c[512];
		uint32_t u32[512 / sizeof(uint32_t)];
	} buffer;
	bool empty = true;

	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	[(OFTarArchiveFileReadStream *)_lastReturnedStream of_skip];
	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if (_stream.atEndOfStream)
		return nil;

	[_stream readIntoBuffer: buffer.c
		    exactLength: 512];

	for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
		if (buffer.u32[i] != 0)
			empty = false;

	if (empty) {
		[_stream readIntoBuffer: buffer.c
			    exactLength: 512];

		for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
			if (buffer.u32[i] != 0)
				@throw [OFInvalidFormatException exception];

		return nil;
	}

	entry = [[[OFTarArchiveEntry alloc]
	    of_initWithHeader: buffer.c
		     encoding: _encoding] autorelease];

	_lastReturnedStream = [[OFTarArchiveFileReadStream alloc]
	    of_initWithStream: _stream
			entry: entry];

	return entry;
}

- (OFStream <OFReadyForReadingObserving> *)streamForReadingCurrentEntry
{
	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	if (_lastReturnedStream == nil)
		@throw [OFInvalidArgumentException exception];

	return [[(OFTarArchiveFileReadStream *)_lastReturnedStream
	    retain] autorelease];
}

- (OFStream <OFReadyForWritingObserving> *)
    streamForWritingEntry: (OFTarArchiveEntry *)entry
{
	void *pool;

	if (_mode != OF_TAR_ARCHIVE_MODE_WRITE &&
	    _mode != OF_TAR_ARCHIVE_MODE_APPEND)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	[entry of_writeToStream: _stream
		       encoding: _encoding];

	_lastReturnedStream = [[OFTarArchiveFileWriteStream alloc]
	    of_initWithStream: _stream
			entry: entry];

	objc_autoreleasePoolPop(pool);

	return [[(OFTarArchiveFileWriteStream *)_lastReturnedStream
	    retain] autorelease];
}

- (void)close
{
	if (_stream == nil)
		return;

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if (_mode == OF_TAR_ARCHIVE_MODE_WRITE ||
	    _mode == OF_TAR_ARCHIVE_MODE_APPEND) {
		char buffer[1024];
		memset(buffer, '\0', 1024);
		[_stream writeBuffer: buffer
			      length: 1024];
	}

	[_stream release];
	_stream = nil;
}
@end

@implementation OFTarArchiveFileReadStream
- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry
{
	self = [super init];

	@try {
		_entry = [entry copy];
		_stream = [stream retain];
		_toRead = entry.size;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t ret;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

#if SIZE_MAX >= UINT64_MAX
	if (length > UINT64_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if ((uint64_t)length > _toRead)
		length = (size_t)_toRead;

	ret = [_stream readIntoBuffer: buffer
			       length: length];

	if (ret == 0)
		_atEndOfStream = true;

	_toRead -= ret;

	return ret;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (bool)hasDataInReadBuffer
{
	return (super.hasDataInReadBuffer || _stream.hasDataInReadBuffer);
}

- (int)fileDescriptorForReading
{
	return ((id <OFReadyForReadingObserving>)_stream)
	    .fileDescriptorForReading;
}

- (void)close
{
	[self of_skip];

	[_stream release];
	_stream = nil;

	[super close];
}

- (void)of_skip
{
	if (_stream == nil || _skipped)
		return;

	if ([_stream isKindOfClass: [OFSeekableStream class]] &&
	    _toRead <= INT64_MAX && (of_offset_t)_toRead == (int64_t)_toRead) {
		uint64_t size;

		[(OFSeekableStream *)_stream seekToOffset: (of_offset_t)_toRead
						   whence: SEEK_CUR];

		_toRead = 0;

		size = _entry.size;

		if (size % 512 != 0)
			[(OFSeekableStream *)_stream
			    seekToOffset: 512 - (size % 512)
				  whence: SEEK_CUR];
	} else {
		char buffer[512];
		uint64_t size;

		while (_toRead >= 512) {
			[_stream readIntoBuffer: buffer
				    exactLength: 512];
			_toRead -= 512;
		}

		if (_toRead > 0) {
			[_stream readIntoBuffer: buffer
				    exactLength: (size_t)_toRead];
			_toRead = 0;
		}

		size = _entry.size;

		if (size % 512 != 0)
			[_stream readIntoBuffer: buffer
				    exactLength: (size_t)(512 - (size % 512))];
	}

	_skipped = true;
}
@end

@implementation OFTarArchiveFileWriteStream
- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry
{
	self = [super init];

	@try {
		_entry = [entry copy];
		_stream = [stream retain];
		_toWrite = entry.size;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	size_t bytesWritten;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((uint64_t)length > _toWrite)
		@throw [OFOutOfRangeException exception];

	@try {
		bytesWritten = [_stream writeBuffer: buffer
					     length: length];
	} @catch (OFWriteFailedException *e) {
		_toWrite -= e.bytesWritten;
		@throw e;
	}

	_toWrite -= bytesWritten;

	return bytesWritten;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return (_toWrite == 0);
}

- (int)fileDescriptorForWriting
{
	return ((id <OFReadyForWritingObserving>)_stream)
	    .fileDescriptorForWriting;
}

- (void)close
{
	if (_stream == nil)
		return;

	uint64_t remainder = 512 - _entry.size % 512;

	if (_toWrite > 0)
		@throw [OFTruncatedDataException exception];

	if (remainder != 512) {
		bool wasWriteBuffered = _stream.writeBuffered;

		[_stream setWriteBuffered: true];

		while (remainder--)
			[_stream writeInt8: 0];

		[_stream flushWriteBuffer];
		_stream.writeBuffered = wasWriteBuffered;
	}

	[_stream release];
	_stream = nil;

	[super close];
}
@end
