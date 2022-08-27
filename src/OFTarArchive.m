/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#import "OFURLHandler.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

OF_DIRECT_MEMBERS
@interface OFTarArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	unsigned long long _toRead;
	bool _atEndOfStream, _skipped;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry;
- (void)of_skip;
@end

OF_DIRECT_MEMBERS
@interface OFTarArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	unsigned long long _toWrite;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFTarArchiveEntry *)entry;
@end

@implementation OFTarArchive: OFObject
@synthesize encoding = _encoding;

+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream mode: mode] autorelease];
}

+ (instancetype)archiveWithURL: (OFURL *)URL mode: (OFString *)mode
{
	return [[[self alloc] initWithURL: URL mode: mode] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream mode: (OFString *)mode
{
	self = [super init];

	@try {
		_stream = [stream retain];

		if ([mode isEqual: @"r"])
			_mode = OFTarArchiveModeRead;
		else if ([mode isEqual: @"w"])
			_mode = OFTarArchiveModeWrite;
		else if ([mode isEqual: @"a"])
			_mode = OFTarArchiveModeAppend;
		else
			@throw [OFInvalidArgumentException exception];

		if (_mode == OFTarArchiveModeAppend) {
			uint32_t buffer[1024 / sizeof(uint32_t)];
			bool empty = true;

			if (![_stream isKindOfClass: [OFSeekableStream class]])
				@throw [OFInvalidArgumentException exception];

			[(OFSeekableStream *)_stream seekToOffset: -1024
							   whence: OFSeekEnd];
			[_stream readIntoBuffer: buffer exactLength: 1024];

			for (size_t i = 0; i < 1024 / sizeof(uint32_t); i++)
				if (buffer[i] != 0)
					empty = false;

			if (!empty)
				@throw [OFInvalidFormatException exception];

			[(OFSeekableStream *)stream seekToOffset: -1024
							  whence: OFSeekEnd];
		}

		_encoding = OFStringEncodingUTF8;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithURL: (OFURL *)URL mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *stream;

	@try {
		if ([mode isEqual: @"a"])
			stream = [OFURLHandler openItemAtURL: URL mode: @"r+"];
		else
			stream = [OFURLHandler openItemAtURL: URL mode: mode];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithStream: stream mode: mode];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	OFTarArchiveEntry *entry;
	uint32_t buffer[512 / sizeof(uint32_t)];
	bool empty = true;

	if (_mode != OFTarArchiveModeRead)
		@throw [OFInvalidArgumentException exception];

	[(OFTarArchiveFileReadStream *)_lastReturnedStream of_skip];
	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if (_stream.atEndOfStream)
		return nil;

	[_stream readIntoBuffer: buffer exactLength: 512];

	for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
		if (buffer[i] != 0)
			empty = false;

	if (empty) {
		[_stream readIntoBuffer: buffer exactLength: 512];

		for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
			if (buffer[i] != 0)
				@throw [OFInvalidFormatException exception];

		return nil;
	}

	entry = [[[OFTarArchiveEntry alloc]
	    of_initWithHeader: (unsigned char *)buffer
		     encoding: _encoding] autorelease];

	_lastReturnedStream = [[OFTarArchiveFileReadStream alloc]
	    of_initWithStream: _stream
			entry: entry];

	return entry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != OFTarArchiveModeRead)
		@throw [OFInvalidArgumentException exception];

	if (_lastReturnedStream == nil)
		@throw [OFInvalidArgumentException exception];

	return [[(OFTarArchiveFileReadStream *)_lastReturnedStream
	    retain] autorelease];
}

- (OFStream *)streamForWritingEntry: (OFTarArchiveEntry *)entry
{
	void *pool;

	if (_mode != OFTarArchiveModeWrite && _mode != OFTarArchiveModeAppend)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	[entry of_writeToStream: _stream encoding: _encoding];

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

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if (_mode == OFTarArchiveModeWrite || _mode == OFTarArchiveModeAppend) {
		char buffer[1024];
		memset(buffer, '\0', 1024);
		[_stream writeBuffer: buffer length: 1024];
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
		_toRead = entry.uncompressedSize;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
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

#if SIZE_MAX >= ULLONG_MAX
	if (length > ULLONG_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if ((unsigned long long)length > _toRead)
		length = (size_t)_toRead;

	ret = [_stream readIntoBuffer: buffer length: length];
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
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

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
	    _toRead <= LLONG_MAX &&
	    (OFStreamOffset)_toRead == (long long)_toRead) {
		unsigned long long size;

		[(OFSeekableStream *)_stream
		    seekToOffset: (OFStreamOffset)_toRead
			  whence: OFSeekCurrent];

		_toRead = 0;

		size = _entry.uncompressedSize;

		if (size % 512 != 0)
			[(OFSeekableStream *)_stream
			    seekToOffset: 512 - (size % 512)
				  whence: OFSeekCurrent];
	} else {
		char buffer[512];
		unsigned long long size;

		while (_toRead >= 512) {
			[_stream readIntoBuffer: buffer exactLength: 512];
			_toRead -= 512;
		}

		if (_toRead > 0) {
			[_stream readIntoBuffer: buffer
				    exactLength: (size_t)_toRead];
			_toRead = 0;
		}

		size = _entry.uncompressedSize;

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
		_toWrite = entry.uncompressedSize;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > _toWrite)
		@throw [OFOutOfRangeException exception];

	@try {
		[_stream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		OFEnsure(e.bytesWritten <= length);

		_toWrite -= e.bytesWritten;

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	_toWrite -= length;

	return length;
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
	unsigned long long remainder;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_toWrite > 0)
		@throw [OFTruncatedDataException exception];

	remainder = 512 - _entry.uncompressedSize % 512;

	if (remainder != 512) {
		bool didBufferWrites = _stream.buffersWrites;

		_stream.buffersWrites = true;

		while (remainder--)
			[_stream writeInt8: 0];

		[_stream flushWriteBuffer];
		_stream.buffersWrites = didBufferWrites;
	}

	[_stream release];
	_stream = nil;

	[super close];
}
@end
