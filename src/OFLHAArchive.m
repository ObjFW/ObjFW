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

#define OF_LHA_ARCHIVE_M

#include "config.h"

#include <errno.h>

#import "OFLHAArchive.h"
#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFArchiveIRIHandler.h"
#import "OFCRC16.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFKernelEventObserver.h"
#import "OFLHADecompressingStream.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

enum {
	modeRead,
	modeWrite,
	modeAppend
};

OF_DIRECT_MEMBERS
@interface OFLHAArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFLHAArchive *_archive;
	OFStream *_stream, *_decompressedStream;
	OFLHAArchiveEntry *_entry;
	unsigned long long _toRead;
	uint16_t _CRC16;
	bool _atEndOfStream, _skipped;
}

- (instancetype)of_initWithArchive: (OFLHAArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFLHAArchiveEntry *)entry;
- (void)of_skip;
@end

OF_DIRECT_MEMBERS
@interface OFLHAArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFLHAArchive *_archive;
	OFMutableLHAArchiveEntry *_entry;
	OFSeekableStream *_stream;
	OFStreamOffset _headerOffset;
	uint64_t _bytesWritten;
	uint16_t _CRC16;
}

- (instancetype)of_initWithArchive: (OFLHAArchive *)archive
			    stream: (OFSeekableStream *)stream
			     entry: (OFLHAArchiveEntry *)entry;
@end

@implementation OFLHAArchive
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
	return _OFArchiveIRIHandlerIRIForFileInArchive(@"lha", path, IRI);
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

		if ((_mode == modeWrite || _mode == modeAppend) &&
		    ![_stream isKindOfClass: [OFSeekableStream class]])
			@throw [OFInvalidArgumentException exception];

		if (_mode == modeAppend)
			/*
			 * Only works with properly zero-terminated files that
			 * have no trailing garbage. Unfortunately there is no
			 * good way to check for this other than reading the
			 * entire archive.
			 */
			[(OFSeekableStream *)_stream seekToOffset: -1
							   whence: OFSeekEnd];
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
	if (_stream != nil)
		[self close];

	objc_release(_currentEntry);

	[super dealloc];
}

- (OFLHAArchiveEntry *)nextEntry
{
	char header[21];
	size_t headerLen;

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

	[(OFLHAArchiveFileReadStream *)_lastReturnedStream of_skip];
	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
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

	/*
	 * Some archives have trailing garbage after the single byte 0
	 * termination. However, a level 2 header uses 2 bytes for the size, so
	 * could just have a header size that is a multiple of 256. Therefore,
	 * consider it only the end of the archive if what follows would not be
	 * a level 2 header.
	 */
	if (header[0] == 0 && header[20] != 2)
		return nil;

	_currentEntry = [[OFLHAArchiveEntry alloc]
	    of_initWithHeader: header
		       stream: _stream
		     encoding: _encoding];

	return _currentEntry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_currentEntry == nil)
		@throw [OFInvalidArgumentException exception];

	_lastReturnedStream = objc_autoreleaseReturnValue(
	    [[OFLHAArchiveFileReadStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: _currentEntry]);
	objc_release(_currentEntry);
	_currentEntry = nil;

	return _lastReturnedStream;
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
	_lastReturnedStream = nil;

	_lastReturnedStream = objc_autoreleaseReturnValue(
	    [[OFLHAArchiveFileWriteStream alloc]
	    of_initWithArchive: self
			stream: (OFSeekableStream *)_stream
			 entry: entry]);
	_hasWritten = true;

	return _lastReturnedStream;
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

	/* LHA archives should be terminated with a header of size 0 */
	if (_hasWritten)
		[_stream writeBuffer: "" length: 1];

	_lastReturnedStream = nil;

	objc_release(_stream);
	_stream = nil;
}
@end

@implementation OFLHAArchiveFileReadStream
- (instancetype)of_initWithArchive: (OFLHAArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFLHAArchiveEntry *)entry
{
	self = [super init];

	@try {
		OFString *compressionMethod;

		_archive = objc_retain(archive);
		_stream = objc_retain(stream);

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
		else if ([compressionMethod isEqual: @"-lhx-"])
			_decompressedStream = [[OFLHADecompressingStream alloc]
			    of_initWithStream: stream
				 distanceBits: 5
			       dictionaryBits: 20];
		else if ([compressionMethod isEqual: @"-lh0-"] ||
		    [compressionMethod isEqual: @"-lhd-"] ||
		    [compressionMethod isEqual: @"-lz4-"] ||
		    [compressionMethod isEqual: @"-pm0-"])
			_decompressedStream = objc_retain(stream);
		else
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: compressionMethod];

		_entry = [entry copy];
		_toRead = entry.uncompressedSize;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil && _decompressedStream != nil)
		[self close];

	objc_release(_entry);

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	objc_release(_archive);

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
		length = (size_t)_toRead;

	ret = [_decompressedStream readIntoBuffer: buffer length: length];

	_toRead -= ret;
	_CRC16 = _OFCRC16(_CRC16, buffer, ret);

	if (_toRead == 0) {
		_atEndOfStream = true;

		if (_CRC16 != _entry.CRC16) {
			OFString *actualChecksum = [OFString stringWithFormat:
			    @"%04" @PRIX16, _CRC16];
			OFString *expectedChecksum = [OFString stringWithFormat:
			    @"%04" @PRIX16, _entry.CRC16];

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
	unsigned long long toRead;

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
	    toRead < LLONG_MAX && (long long)toRead == (OFStreamOffset)toRead)
		[(OFSeekableStream *)stream seekToOffset: (OFStreamOffset)toRead
						  whence: OFSeekCurrent];
	else {
		while (toRead > 0) {
			char buffer[512];
			unsigned long long min = toRead;

			if (min > 512)
				min = 512;

			toRead -= [stream readIntoBuffer: buffer
						  length: (size_t)min];
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

	objc_release(_stream);
	_stream = nil;

	objc_release(_decompressedStream);
	_decompressedStream = nil;

	[super close];
}
@end

@implementation OFLHAArchiveFileWriteStream
- (instancetype)of_initWithArchive: (OFLHAArchive *)archive
			    stream: (OFSeekableStream *)stream
			     entry: (OFLHAArchiveEntry *)entry
{
	self = [super init];

	@try {
		_archive = objc_retain(archive);
		_entry = [entry mutableCopy];

		_headerOffset = [stream seekToOffset: 0 whence: OFSeekCurrent];
		[_entry of_writeToStream: stream encoding: _archive.encoding];

		/*
		 * Retain stream last, so that -[close] called by -[dealloc]
		 * doesn't write in case of an error.
		 */
		_stream = objc_retain(stream);
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

	if (UINT64_MAX - _bytesWritten < length)
		@throw [OFOutOfRangeException exception];

	@try {
		[_stream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		OFEnsure(e.bytesWritten <= length);

		_bytesWritten += (uint64_t)e.bytesWritten;
		_CRC16 = _OFCRC16(_CRC16, buffer, e.bytesWritten);

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	_bytesWritten += (uint64_t)length;
	_CRC16 = _OFCRC16(_CRC16, buffer, length);

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
	OFStreamOffset offset;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	_entry.uncompressedSize = _bytesWritten;
	_entry.compressedSize = _bytesWritten;
	_entry.CRC16 = _CRC16;

	offset = [_stream seekToOffset: 0 whence: OFSeekCurrent];
	[_stream seekToOffset: _headerOffset whence: OFSeekSet];
	[_entry of_writeToStream: _stream encoding: _archive.encoding];
	[_stream seekToOffset: offset whence: OFSeekSet];

	objc_release(_stream);
	_stream = nil;

	[super close];
}
@end
