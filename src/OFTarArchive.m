/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <inttypes.h>

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFStream.h"
#import "OFDate.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

@interface OFTarArchive_FileReadStream: OFStream
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	uint64_t _toRead;
	bool _atEndOfStream;
}

- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream;
- (void)of_skip;
@end

@interface OFTarArchive_FileWriteStream: OFStream
{
	OFTarArchiveEntry *_entry;
	OFStream *_stream;
	uint64_t _toWrite;
}

- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream;
@end

static void
stringToBuffer(unsigned char *buffer, OFString *string, size_t length)
{
	size_t UTF8StringLength = [string UTF8StringLength];

	if (UTF8StringLength > length)
		@throw [OFOutOfRangeException exception];

	memcpy(buffer, [string UTF8String], UTF8StringLength);

	for (size_t i = UTF8StringLength; i < length; i++)
		buffer[i] = '\0';
}

@implementation OFTarArchive: OFObject
+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
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

- initWithStream: (OF_KINDOF(OFStream *))stream
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

			[stream seekToOffset: -1024
				      whence: SEEK_END];
			[stream readIntoBuffer: buffer.c
				   exactLength: 1024];

			for (size_t i = 0; i < 1024 / sizeof(uint32_t); i++)
				if (buffer.u32[i] != 0)
					empty = false;

			if (!empty)
				@throw [OFInvalidFormatException exception];

			[stream seekToOffset: -1024
				      whence: SEEK_END];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- initWithPath: (OFString *)path
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
		char c[512];
		uint32_t u32[512 / sizeof(uint32_t)];
	} buffer;
	bool empty = true;

	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	[_lastReturnedStream of_skip];
	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if ([_stream isAtEndOfStream])
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
	    of_initWithHeader: buffer.c] autorelease];

	_lastReturnedStream = [[OFTarArchive_FileReadStream alloc]
	    initWithEntry: entry
		   stream: _stream];

	return entry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	return [[_lastReturnedStream retain] autorelease];
}

- (OFStream *)streamForWritingEntry: (OFTarArchiveEntry *)entry
{
	void *pool;
	uint64_t modificationDate;
	unsigned char buffer[512];
	uint16_t checksum = 0;

	if (_mode != OF_TAR_ARCHIVE_MODE_WRITE &&
	    _mode != OF_TAR_ARCHIVE_MODE_APPEND)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	stringToBuffer(buffer, [entry fileName], 100);
	stringToBuffer(buffer + 100,
	    [OFString stringWithFormat: @"%06" PRIo32 " ", [entry mode]], 8);
	memcpy(buffer + 108, "000000 \0" "000000 \0", 16);
	stringToBuffer(buffer + 124,
	    [OFString stringWithFormat: @"%011" PRIo64 " ", [entry size]], 12);
	modificationDate = [[entry modificationDate] timeIntervalSince1970];
	stringToBuffer(buffer + 136,
	    [OFString stringWithFormat: @"%011" PRIo64 " ", modificationDate],
	    12);

	/*
	 * During checksumming, the checksum field is expected to be set to 8
	 * spaces.
	 */
	memset(buffer + 148, ' ', 8);

	buffer[156] = [entry type];
	stringToBuffer(buffer + 157, [entry targetFileName], 100);

	/* ustar */
	memcpy(buffer + 257, "ustar\0" "00", 8);
	stringToBuffer(buffer + 265, [entry owner], 32);
	stringToBuffer(buffer + 297, [entry group], 32);
	stringToBuffer(buffer + 329,
	    [OFString stringWithFormat: @"%06" PRIo32 " ", [entry deviceMajor]],
	    8);
	stringToBuffer(buffer + 337,
	    [OFString stringWithFormat: @"%06" PRIo32 " ", [entry deviceMinor]],
	    8);
	memset(buffer + 345, '\0', 155 + 12);

	/* Fill in the checksum */
	for (size_t i = 0; i < 500; i++)
		checksum += buffer[i];
	stringToBuffer(buffer + 148,
	    [OFString stringWithFormat: @"%06" PRIo16, checksum], 7);

	[_stream writeBuffer: buffer
		      length: sizeof(buffer)];

	_lastReturnedStream = [[OFTarArchive_FileWriteStream alloc]
	    initWithEntry: entry
		   stream: _stream];

	objc_autoreleasePoolPop(pool);

	return [[_lastReturnedStream retain] autorelease];
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

@implementation OFTarArchive_FileReadStream
- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream
{
	self = [super init];

	@try {
		_entry = [entry copy];
		_stream = [stream retain];
		_toRead = [entry size];
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
	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}

- (int)fileDescriptorForReading
{
	return [_stream fileDescriptorForReading];
}

- (void)close
{
	[_stream release];
	_stream = nil;

	[super close];
}

- (void)of_skip
{
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

	size = [_entry size];

	if (size % 512 != 0)
		[_stream readIntoBuffer: buffer
			    exactLength: 512 - ((size_t)size % 512)];
}
@end

@implementation OFTarArchive_FileWriteStream
- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream
{
	self = [super init];

	@try {
		_entry = [entry copy];
		_stream = [stream retain];
		_toWrite = [entry size];
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

- (void)lowlevelWriteBuffer: (const void *)buffer
		     length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((uint64_t)length > _toWrite)
		@throw [OFOutOfRangeException exception];

	@try {
		[_stream writeBuffer: buffer
			      length: length];
	} @catch (OFWriteFailedException *e) {
		_toWrite -= [e bytesWritten];
		@throw e;
	}

	_toWrite -= length;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return (_toWrite == 0);
}

- (int)fileDescriptorForWriting
{
	return [_stream fileDescriptorForWriting];
}

- (void)close
{
	if (_stream == nil)
		return;

	uint64_t remainder = 512 - [_entry size] % 512;

	if (_toWrite > 0)
		@throw [OFTruncatedDataException exception];

	if (remainder != 512) {
		bool wasWriteBuffered = [_stream isWriteBuffered];

		[_stream setWriteBuffered: true];

		while (remainder--)
			[_stream writeInt8: 0];

		[_stream flushWriteBuffer];
		[_stream setWriteBuffered: wasWriteBuffered];
	}

	[_stream release];
	_stream = nil;

	[super close];
}
@end
