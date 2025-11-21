/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define OF_TAR_ARCHIVE_M

#include "config.h"

#include <errno.h>

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFArchiveIRIHandler.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFKernelEventObserver.h"
#import "OFSeekableStream.h"
#import "OFStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

enum {
	modeRead,
	modeWrite,
	modeAppend
};

OF_DIRECT_MEMBERS
@interface OFTarArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFTarArchive *_archive;
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	unsigned long long _toRead;
	bool _atEndOfStream, _skipped;
}

- (instancetype)of_initWithArchive: (OFTarArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFTarArchiveEntry *)entry;
- (void)of_skip;
@end

OF_DIRECT_MEMBERS
@interface OFTarArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFTarArchive *_archive;
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	unsigned long long _toWrite;
}

- (instancetype)of_initWithArchive: (OFTarArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFTarArchiveEntry *)entry;
@end

static void
parsePAXExtendedHeader(OFStream *stream, OFMutableDictionary *header)
{
	for (;;) {
		uint8_t byte;
		size_t size, consumed = 0;
		OFMutableData *name;
		OFData *value;

		if ([stream readIntoBuffer: &byte length: 1] == 0)
			break;

		if (byte < '0' || byte > '9')
			@throw [OFInvalidFormatException exception];

		size = byte - '0';
		consumed++;

		while ((byte = [stream readInt8]) != ' ') {
			if (byte < '0' || byte > '9')
				@throw [OFInvalidFormatException exception];

			if (size > SIZE_MAX / 10 ||
			    (uint8_t)(byte - '0') > SIZE_MAX - size * 10)
				@throw [OFOutOfRangeException exception];

			size *= 10;
			size += byte - '0';
			consumed++;
		}
		consumed++;

		name = [OFMutableData data];
		while ((byte = [stream readInt8]) != '=')
			[name addItem: &byte];
		consumed += name.count + 1;

		if (consumed + 1 > size)
			@throw [OFOutOfRangeException exception];

		value = [stream readDataWithCount: size - consumed - 1];

		[header setObject: value
			   forKey: [OFString stringWithUTF8String: name.items
							   length: name.count]];

		if ([stream readInt8] != '\n')
			@throw [OFInvalidFormatException exception];
	}
}

@implementation OFTarArchive
@synthesize encoding = _encoding;

+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode
{
	return objc_autoreleaseReturnValue([[self alloc] initWithStream: stream
								   mode: mode]);
}

+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIRI: IRI
								mode: mode]);
}

+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI
{
	return _OFArchiveIRIHandlerIRIForFileInArchive(@"tar", path, IRI);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream mode: (OFString *)mode
{
	self = [super init];

	@try {
		_stream = objc_retain(stream);

		if ([mode isEqual: @"r"])
			_mode = modeRead;
		else if ([mode isEqual: @"w"])
			_mode = modeWrite;
		else if ([mode isEqual: @"a"])
			_mode = modeAppend;
		else
			@throw [OFInvalidArgumentException exception];

		if (_mode == modeAppend) {
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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *stream;

	@try {
		if ([mode isEqual: @"a"])
			stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r+"];
		else
			stream = [OFIRIHandler openItemAtIRI: IRI mode: mode];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithStream: stream mode: mode];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (void)dealloc
{
	[self close];

	objc_release(_globalExtendedHeader);
	objc_release(_currentEntry);

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	uint32_t buffer[512 / sizeof(uint32_t)];
	bool empty = true;

	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_currentEntry != nil && _lastReturnedStream == nil) {
		/*
		 * No read stream was created since the last call to
		 * -[nextEntry]. Create it so that we can properly skip the
		 *  data.
		 */
		void *pool = objc_autoreleasePoolPush();

		[self streamForReadingCurrentEntry];

		objc_autoreleasePoolPop(pool);
	}

	objc_release(_currentEntry);
	_currentEntry = nil;

	[(OFTarArchiveFileReadStream *)_lastReturnedStream of_skip];
	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
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

	_currentEntry = [[OFTarArchiveEntry alloc]
	    of_initWithHeader: (unsigned char *)buffer
	       extendedHeader: _globalExtendedHeader
		     encoding: _encoding];

	while (_currentEntry.fileType ==
	    OFArchiveEntryFileTypePAXExtendedHeader ||
	    _currentEntry.fileType ==
	    OFArchiveEntryFileTypePAXGlobalExtendedHeader) {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *extendedHeader;

		if (_currentEntry.fileType ==
		    OFArchiveEntryFileTypePAXGlobalExtendedHeader) {
			if (_globalExtendedHeader == nil)
				_globalExtendedHeader =
				    [[OFMutableDictionary alloc] init];

			extendedHeader = _globalExtendedHeader;
		} else
			extendedHeader = objc_autorelease(
			    [_globalExtendedHeader mutableCopy]);

		parsePAXExtendedHeader(
		    [self streamForReadingCurrentEntry], extendedHeader);

		[(OFTarArchiveFileReadStream *)_lastReturnedStream of_skip];
		[_lastReturnedStream close];
		_lastReturnedStream = nil;

		[_stream readIntoBuffer: buffer exactLength: 512];

		empty = true;
		for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
			if (buffer[i] != 0)
				empty = false;

		if (empty)
			@throw [OFInvalidFormatException exception];

		_currentEntry = [[OFTarArchiveEntry alloc]
		    of_initWithHeader: (unsigned char *)buffer
		       extendedHeader: extendedHeader
			     encoding: _encoding];

		objc_autoreleasePoolPop(pool);
	}

	return _currentEntry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_currentEntry == nil)
		@throw [OFInvalidArgumentException exception];

	_lastReturnedStream = [[OFTarArchiveFileReadStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: _currentEntry];
	objc_release(_currentEntry);
	_currentEntry = nil;

	return objc_autoreleaseReturnValue(_lastReturnedStream);
}

- (OFStream *)streamForWritingEntry: (OFTarArchiveEntry *)entry
{
	if (_mode != modeWrite && _mode != modeAppend)
		@throw [OFInvalidArgumentException exception];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	[entry of_writeToStream: _stream encoding: _encoding];

	_lastReturnedStream = [[OFTarArchiveFileWriteStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: entry];

	return objc_autoreleaseReturnValue(_lastReturnedStream);
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
	_lastReturnedStream = nil;

	if (_mode == modeWrite || _mode == modeAppend) {
		char buffer[1024];
		memset(buffer, '\0', 1024);
		[_stream writeBuffer: buffer length: 1024];
	}

	objc_release(_stream);
	_stream = nil;
}
@end

@implementation OFTarArchiveFileReadStream
- (instancetype)of_initWithArchive: (OFTarArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFTarArchiveEntry *)entry
{
	self = [super init];

	@try {
		_archive = objc_retain(archive);
		_entry = [entry copy];
		_stream = objc_retain(stream);
		_toRead = entry.uncompressedSize;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	objc_release(_entry);

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	objc_release(_archive);

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
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

- (bool)lowlevelHasDataInReadBuffer
{
	return _stream.hasDataInReadBuffer;
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

	objc_release(_stream);
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
- (instancetype)of_initWithArchive: (OFTarArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFTarArchiveEntry *)entry
{
	self = [super init];

	@try {
		_archive = objc_retain(archive);
		_entry = [entry copy];
		_stream = objc_retain(stream);
		_toWrite = entry.uncompressedSize;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	objc_release(_entry);

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	objc_release(_archive);

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
	unsigned long long rest;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_toWrite > 0)
		@throw [OFTruncatedDataException exception];

	rest = 512 - _entry.uncompressedSize % 512;

	if (rest != 512) {
		bool didBufferWrites = _stream.buffersWrites;

		_stream.buffersWrites = true;

		while (rest--)
			[_stream writeInt8: 0];

		[_stream flushWriteBuffer];
		_stream.buffersWrites = didBufferWrites;
	}

	objc_release(_stream);
	_stream = nil;

	[super close];
}
@end
