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

#import "OFLHAArchive.h"
#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFLHADecompressingStream.h"
#import "OFStream.h"
#import "OFSeekableStream.h"
#import "OFString.h"

#import "crc16.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFWriteFailedException.h"

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

@interface OFLHAArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFMutableLHAArchiveEntry *_entry;
	of_string_encoding_t _encoding;
	OFSeekableStream *_stream;
	of_offset_t _headerOffset;
	uint32_t _bytesWritten;
	uint16_t _CRC16;
}

- (instancetype)of_initWithStream: (OFSeekableStream *)stream
			    entry: (OFLHAArchiveEntry *)entry
			 encoding: (of_string_encoding_t)encoding;
@end

@implementation OFLHAArchive
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
			_mode = OF_LHA_ARCHIVE_MODE_READ;
		else if ([mode isEqual: @"w"])
			_mode = OF_LHA_ARCHIVE_MODE_WRITE;
		else if ([mode isEqual: @"a"])
			_mode = OF_LHA_ARCHIVE_MODE_APPEND;
		else
			@throw [OFInvalidArgumentException exception];

		if ((_mode == OF_LHA_ARCHIVE_MODE_WRITE ||
		    _mode == OF_LHA_ARCHIVE_MODE_APPEND) &&
		    ![_stream isKindOfClass: [OFSeekableStream class]])
			@throw [OFInvalidArgumentException exception];

		if (_mode == OF_LHA_ARCHIVE_MODE_APPEND)
			[(OFSeekableStream *)_stream seekToOffset: 0
							   whence: SEEK_END];

		_encoding = OF_STRING_ENCODING_ISO_8859_1;
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

- (OFLHAArchiveEntry *)nextEntry
{
	OFLHAArchiveEntry *entry;
	char header[21];
	size_t headerLen;

	if (_mode != OF_LHA_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	[(OFLHAArchiveFileReadStream *)_lastReturnedStream of_skip];
	[_lastReturnedStream close];
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

- (OFStream <OFReadyForReadingObserving> *)streamForReadingCurrentEntry
{
	if (_mode != OF_LHA_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	if (_lastReturnedStream == nil)
		@throw [OFInvalidArgumentException exception];

	return [[(OFLHAArchiveFileReadStream *)_lastReturnedStream
	    retain] autorelease];
}

- (OFStream <OFReadyForWritingObserving> *)
    streamForWritingEntry: (OFLHAArchiveEntry *)entry
{
	OFString *compressionMethod;

	if (_mode != OF_LHA_ARCHIVE_MODE_WRITE &&
	    _mode != OF_LHA_ARCHIVE_MODE_APPEND)
		@throw [OFInvalidArgumentException exception];

	compressionMethod = entry.compressionMethod;

	if (![compressionMethod isEqual: @"-lh0-"] &&
	    ![compressionMethod isEqual: @"-lhd-"])
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[_lastReturnedStream close];
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
		return;

	[_lastReturnedStream close];
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
	[self close];

	[_stream release];
	[_decompressedStream release];
	[_entry release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
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

	ret = [_decompressedStream readIntoBuffer: buffer
					   length: length];

	_toRead -= ret;
	_CRC16 = of_crc16(_CRC16, buffer, ret);

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
		    _entry.compressedSize - decompressingStream->_bytesConsumed;

		stream = _stream;
	}

	if ([stream isKindOfClass: [OFSeekableStream class]] &&
	    (sizeof(of_offset_t) > 4 || toRead < INT32_MAX))
		[(OFSeekableStream *)stream seekToOffset: (of_offset_t)toRead
						  whence: SEEK_CUR];
	else {
		while (toRead > 0) {
			char buffer[512];
			size_t min = toRead;

			if (min > 512)
				min = 512;

			toRead -= [stream readIntoBuffer: buffer
						  length: min];
		}
	}

	_toRead = 0;
	_skipped = true;
}

- (void)close
{
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
			 encoding: (of_string_encoding_t)encoding
{
	self = [super init];

	@try {
		_entry = [entry mutableCopy];
		_encoding = encoding;

		_headerOffset = [stream seekToOffset: 0
					       whence: SEEK_CUR];
		[_entry of_writeToStream: stream
				encoding: _encoding];

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
	[self close];

	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	uint32_t bytesWritten;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (UINT32_MAX - _bytesWritten < length)
		@throw [OFOutOfRangeException exception];

	@try {
		bytesWritten = (uint32_t)[_stream writeBuffer: buffer
						       length: length];
	} @catch (OFWriteFailedException *e) {
		_bytesWritten += e.bytesWritten;
		_CRC16 = of_crc16(_CRC16, buffer, e.bytesWritten);

		@throw e;
	}

	_bytesWritten += (uint32_t)bytesWritten;
	_CRC16 = of_crc16(_CRC16, buffer, bytesWritten);

	return bytesWritten;
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
	of_offset_t offset;

	if (_stream == nil)
		return;

	_entry.uncompressedSize = _bytesWritten;
	_entry.compressedSize = _bytesWritten;
	_entry.CRC16 = _CRC16;

	offset = [_stream seekToOffset: 0
				whence:SEEK_CUR];
	[_stream seekToOffset: _headerOffset
		       whence: SEEK_SET];
	[_entry of_writeToStream: _stream
			encoding: _encoding];
	[_stream seekToOffset: offset
		       whence: SEEK_SET];

	[_stream release];
	_stream = nil;

	[super close];
}
@end
