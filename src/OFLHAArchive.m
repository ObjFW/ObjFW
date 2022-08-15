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

#import "OFLHAArchive.h"
#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFCRC16.h"
#import "OFLHADecompressingStream.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFURLHandler.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
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
@interface OFLHAArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFStream *_stream, *_decompressedStream;
	OFLHAArchiveEntry *_entry;
	uint32_t _toRead, _bytesConsumed;
	uint16_t _CRC16;
	bool _atEndOfStream, _skipped;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFLHAArchiveEntry *)entry;
- (void)of_skip;
@end

OF_DIRECT_MEMBERS
@interface OFLHAArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFMutableLHAArchiveEntry *_entry;
	OFStringEncoding _encoding;
	OFSeekableStream *_stream;
	OFFileOffset _headerOffset;
	uint32_t _bytesWritten;
	uint16_t _CRC16;
}

- (instancetype)of_initWithStream: (OFSeekableStream *)stream
			    entry: (OFLHAArchiveEntry *)entry
			 encoding: (OFStringEncoding)encoding;
@end

@implementation OFLHAArchive
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
			_mode = modeRead;
		else if ([mode isEqual: @"w"])
			_mode = modeWrite;
		else if ([mode isEqual: @"a"])
			_mode = modeAppend;
		else
			@throw [OFInvalidArgumentException exception];

		if ((_mode == modeWrite || _mode == modeAppend) &&
		    ![_stream isKindOfClass: [OFSeekableStream class]])
			@throw [OFInvalidArgumentException exception];

		if (_mode == modeAppend)
			[(OFSeekableStream *)_stream seekToOffset: 0
							   whence: SEEK_END];

		_encoding = OFStringEncodingISO8859_1;
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
	if (_stream != nil)
		[self close];

	[super dealloc];
}

- (OFLHAArchiveEntry *)nextEntry
{
	OFLHAArchiveEntry *entry;
	char header[21];
	size_t headerLen;

	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	[(OFLHAArchiveFileReadStream *)_lastReturnedStream of_skip];
	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	for (headerLen = 0; headerLen < 21;) {
		if (_stream.atEndOfStream) {
			if (headerLen == 0)
				return nil;

			if (headerLen == 1 && header[0] == 0)
				return nil;

			@throw [OFTruncatedDataException exception];
		}

		headerLen += [_stream readIntoBuffer: header + headerLen
					      length: 21 - headerLen];
	}

	entry = [[[OFLHAArchiveEntry alloc]
	    of_initWithHeader: header
		       stream: _stream
		     encoding: _encoding] autorelease];

	_lastReturnedStream = [[OFLHAArchiveFileReadStream alloc]
	    of_initWithStream: _stream
			entry: entry];

	return entry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_lastReturnedStream == nil)
		@throw [OFInvalidArgumentException exception];

	return [[(OFLHAArchiveFileReadStream *)_lastReturnedStream
	    retain] autorelease];
}

- (OFStream *)streamForWritingEntry: (OFLHAArchiveEntry *)entry
{
	OFString *compressionMethod;

	if (_mode != modeWrite && _mode != modeAppend)
		@throw [OFInvalidArgumentException exception];

	compressionMethod = entry.compressionMethod;

	if (![compressionMethod isEqual: @"-lh0-"] &&
	    ![compressionMethod isEqual: @"-lhd-"])
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	_lastReturnedStream = [[OFLHAArchiveFileWriteStream alloc]
	    of_initWithStream: (OFSeekableStream *)_stream
			entry: entry
		     encoding: _encoding];

	return [[(OFLHAArchiveFileWriteStream *)_lastReturnedStream
	    retain] autorelease];
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	[_stream release];
	_stream = nil;
}
@end

@implementation OFLHAArchiveFileReadStream
- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFLHAArchiveEntry *)entry
{
	self = [super init];

	@try {
		OFString *compressionMethod;

		_stream = [stream retain];

		compressionMethod = entry.compressionMethod;

		if ([compressionMethod isEqual: @"-lh4-"] ||
		    [compressionMethod isEqual: @"-lh5-"])
			_decompressedStream = [[OFLHADecompressingStream alloc]
			    of_initWithStream: stream
				 distanceBits: 4
			       dictionaryBits: 14];
		else if ([compressionMethod isEqual: @"-lh6-"])
			_decompressedStream = [[OFLHADecompressingStream alloc]
			    of_initWithStream: stream
				 distanceBits: 5
			       dictionaryBits: 16];
		else if ([compressionMethod isEqual: @"-lh7-"])
			_decompressedStream = [[OFLHADecompressingStream alloc]
			    of_initWithStream: stream
				 distanceBits: 5
			       dictionaryBits: 17];
		else
			_decompressedStream = [stream retain];

		_entry = [entry copy];
		_toRead = entry.uncompressedSize;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil || _decompressedStream != nil)
		[self close];

	[_entry release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	size_t ret;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if (_stream.atEndOfStream && !_decompressedStream.hasDataInReadBuffer)
		@throw [OFTruncatedDataException exception];

	if (length > _toRead)
		length = _toRead;

	ret = [_decompressedStream readIntoBuffer: buffer length: length];

	_toRead -= ret;
	_CRC16 = OFCRC16(_CRC16, buffer, ret);

	if (_toRead == 0) {
		_atEndOfStream = true;

		if (_CRC16 != _entry.CRC16) {
			OFString *actualChecksum = [OFString stringWithFormat:
			    @"%04" PRIX16, _CRC16];
			OFString *expectedChecksum = [OFString stringWithFormat:
			    @"%04" PRIX16, _entry.CRC16];

			@throw [OFChecksumMismatchException
			    exceptionWithActualChecksum: actualChecksum
				       expectedChecksum: expectedChecksum];
		}
	}

	return ret;
}

- (bool)hasDataInReadBuffer
{
	return (super.hasDataInReadBuffer ||
	    _decompressedStream.hasDataInReadBuffer);
}

- (int)fileDescriptorForReading
{
	return ((id <OFReadyForReadingObserving>)_decompressedStream)
	    .fileDescriptorForReading;
}

- (void)of_skip
{
	OFStream *stream;
	uint32_t toRead;

	if (_stream == nil || _skipped)
		return;

	stream = _stream;
	toRead = _toRead;

	/*
	 * Get the number of consumed bytes and directly read from the
	 * compressed stream, to make skipping much faster.
	 */
	if ([_decompressedStream isKindOfClass:
	    [OFLHADecompressingStream class]]) {
		OFLHADecompressingStream *decompressingStream =
		    (OFLHADecompressingStream *)_decompressedStream;

		[decompressingStream close];
		toRead =
		    _entry.compressedSize - decompressingStream.bytesConsumed;

		stream = _stream;
	}

	if ([stream isKindOfClass: [OFSeekableStream class]] &&
	    (sizeof(OFFileOffset) > 4 || toRead < INT32_MAX))
		[(OFSeekableStream *)stream seekToOffset: (OFFileOffset)toRead
						  whence: SEEK_CUR];
	else {
		while (toRead > 0) {
			char buffer[512];
			size_t min = toRead;

			if (min > 512)
				min = 512;

			toRead -= [stream readIntoBuffer: buffer length: min];
		}
	}

	_toRead = 0;
	_skipped = true;
}

- (void)close
{
	if (_stream == nil || _decompressedStream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	[self of_skip];

	[_stream release];
	_stream = nil;

	[_decompressedStream release];
	_decompressedStream = nil;

	[super close];
}
@end

@implementation OFLHAArchiveFileWriteStream
- (instancetype)of_initWithStream: (OFSeekableStream *)stream
			    entry: (OFLHAArchiveEntry *)entry
			 encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		_entry = [entry mutableCopy];
		_encoding = encoding;

		_headerOffset = [stream seekToOffset: 0 whence: SEEK_CUR];
		[_entry of_writeToStream: stream encoding: _encoding];

		/*
		 * Retain stream last, so that -[close] called by -[dealloc]
		 * doesn't write in case of an error.
		 */
		_stream = [stream retain];
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

	if (UINT32_MAX - _bytesWritten < length)
		@throw [OFOutOfRangeException exception];

	@try {
		[_stream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		OFEnsure(e.bytesWritten <= length);

		_bytesWritten += (uint32_t)e.bytesWritten;
		_CRC16 = OFCRC16(_CRC16, buffer, e.bytesWritten);

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	_bytesWritten += (uint32_t)length;
	_CRC16 = OFCRC16(_CRC16, buffer, length);

	return length;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _stream.atEndOfStream;
}

- (int)fileDescriptorForWriting
{
	return ((id <OFReadyForWritingObserving>)_stream)
	    .fileDescriptorForWriting;
}

- (void)close
{
	OFFileOffset offset;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	_entry.uncompressedSize = _bytesWritten;
	_entry.compressedSize = _bytesWritten;
	_entry.CRC16 = _CRC16;

	offset = [_stream seekToOffset: 0 whence: SEEK_CUR];
	[_stream seekToOffset: _headerOffset whence: SEEK_SET];
	[_entry of_writeToStream: _stream encoding: _encoding];
	[_stream seekToOffset: offset whence: SEEK_SET];

	[_stream release];
	_stream = nil;

	[super close];
}
@end
