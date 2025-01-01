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

#define OF_ZOO_ARCHIVE_M

#include "config.h"

#include <errno.h>

#import "OFZooArchive.h"
#import "OFZooArchiveEntry.h"
#import "OFZooArchiveEntry+Private.h"
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
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

enum {
	modeRead,
	modeWrite
};

OF_DIRECT_MEMBERS
@interface OFZooArchive ()
- (void)of_readArchiveHeader;
@end

OF_DIRECT_MEMBERS
@interface OFZooArchiveFileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFZooArchive *_archive;
	OF_KINDOF(OFStream *) _stream;
	OFStream *_decompressedStream;
	OFZooArchiveEntry *_entry;
	unsigned long long _toRead;
	uint16_t _CRC16;
	bool _atEndOfStream;
}

- (instancetype)of_initWithArchive: (OFZooArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFZooArchiveEntry *)entry;
@end

OF_DIRECT_MEMBERS
@interface OFZooArchiveFileWriteStream: OFStream <OFReadyForWritingObserving>
{
	OFZooArchive *_archive;
	OFMutableZooArchiveEntry *_entry;
	OFStringEncoding _encoding;
	OFSeekableStream *_stream;
	OFStreamOffset *_lastHeaderOffset;
	size_t *_lastHeaderLength;
	uint32_t _bytesWritten;
	uint16_t _CRC16;
}

- (instancetype)of_initWithArchive: (OFZooArchive *)archive
			    stream: (OFSeekableStream *)stream
			     entry: (OFZooArchiveEntry *)entry
			  encoding: (OFStringEncoding)encoding
		  lastHeaderOffset: (OFStreamOffset *)lastHeaderOffset
		  lastHeaderLength: (size_t *)lastHeaderLength;
@end

@implementation OFZooArchive
@synthesize encoding = _encoding;

+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream mode: mode] autorelease];
}

+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	return [[[self alloc] initWithIRI: IRI mode: mode] autorelease];
}

+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI
{
	return _OFArchiveIRIHandlerIRIForFileInArchive(@"zoo", path, IRI);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream mode: (OFString *)mode
{
	self = [super init];

	@try {
		if ([mode isEqual: @"r"])
			_mode = modeRead;
		else if ([mode isEqual: @"w"])
			_mode = modeWrite;
		else if ([mode isEqual: @"a"])
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: nil];
		else
			@throw [OFInvalidArgumentException exception];

		if (![stream isKindOfClass: [OFSeekableStream class]])
			@throw [OFInvalidArgumentException exception];

		_stream = [stream retain];
		_encoding = OFStringEncodingUTF8;

		if (_mode == modeRead)
			[self of_readArchiveHeader];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *stream;

	@try {
		if ([mode isEqual: @"w"])
			stream = [OFIRIHandler openItemAtIRI: IRI mode: @"w+"];
		else
			stream = [OFIRIHandler openItemAtIRI: IRI mode: mode];
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

	[_archiveComment release];
	[_currentEntry release];

	[super dealloc];
}

- (void)of_readArchiveHeader
{
	char headerText[20];
	uint32_t firstFileOffset, commentOffset;
	uint16_t commentLength;

	[_stream readIntoBuffer: headerText exactLength: 20];

	if ([_stream readLittleEndianInt32] != 0xFDC4A7DC)
		@throw [OFInvalidFormatException exception];

	firstFileOffset = [_stream readLittleEndianInt32];

	if ([_stream readLittleEndianInt32] != ~(uint32_t)(firstFileOffset - 1))
		@throw [OFInvalidFormatException exception];

	if ((_minVersionNeeded = [_stream readBigEndianInt16]) > 0x201)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%" PRIu8 @".%" PRIu8,
						_minVersionNeeded >> 8,
						_minVersionNeeded & 0xFF]];

	if ((_headerType = [_stream readInt8]) > 1)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%" PRIu8, _headerType]];

	commentOffset = [_stream readLittleEndianInt32];
	commentLength = [_stream readLittleEndianInt16];

	if (commentOffset > 0) {
		[_stream seekToOffset: commentOffset whence: OFSeekSet];
		_archiveComment = [_stream readStringWithLength: commentLength
						       encoding: _encoding];
	}

	[_stream seekToOffset: firstFileOffset whence: OFSeekSet];
}

- (OFString *)archiveComment
{
	return _archiveComment;
}

- (void)setArchiveComment: (OFString *)comment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old;

	if ([comment cStringLengthWithEncoding: _encoding] > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	old = _archiveComment;
	_archiveComment = [comment copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (OFZooArchiveEntry *)nextEntry
{
	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_currentEntry != nil)
		[_stream seekToOffset: _currentEntry->_nextHeaderOffset
			       whence: OFSeekSet];

	[_currentEntry release];
	_currentEntry = nil;

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	_currentEntry = [[OFZooArchiveEntry alloc]
	    of_initWithStream: _stream
		     encoding: _encoding];

	return _currentEntry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if (_currentEntry == nil)
		@throw [OFInvalidArgumentException exception];

	_lastReturnedStream = [[[OFZooArchiveFileReadStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: _currentEntry] autorelease];

	return _lastReturnedStream;
}

- (void)of_fixUpLastHeader
{
	OFStreamOffset offset;
	unsigned char *buffer;

	if (_lastHeaderOffset == 0)
		return;

	offset = [_stream seekToOffset: 0 whence: OFSeekCurrent];

	if (offset < 0 || (unsigned long long)offset > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	OFEnsure(_lastHeaderLength >= 56);

	[_stream seekToOffset: _lastHeaderOffset whence: OFSeekSet];
	buffer = OFAllocMemory(1, _lastHeaderLength);
	@try {
		uint16_t tmp16;
		uint32_t tmp32;

		[_stream readIntoBuffer: buffer exactLength: _lastHeaderLength];

		tmp32 = OFToLittleEndian32((uint32_t)offset);
		memcpy(buffer + 6, &tmp32, 4);

		tmp16 = OFToLittleEndian16(
		    _OFCRC16(0, buffer, _lastHeaderLength));
		memcpy(buffer + 54, &tmp16, 2);

		[_stream seekToOffset: _lastHeaderOffset whence: OFSeekSet];
		[_stream writeBuffer: buffer length: _lastHeaderLength];

		[_stream seekToOffset: offset whence: OFSeekSet];
	} @finally {
		OFFreeMemory(buffer);
	}
}

- (OFStream *)streamForWritingEntry: (OFZooArchiveEntry *)entry
{
	if (_mode != modeWrite)
		@throw [OFInvalidArgumentException exception];

	if (entry.compressionMethod != 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (_lastHeaderOffset == 0) {
		uint16_t commentLength =
		    [_archiveComment cStringLengthWithEncoding: _encoding];

		/* First file - write header. */
		[_stream writeBuffer: "ObjFW Zoo Archive.\x1F" length: 20];
		[_stream writeLittleEndianInt32: 0xFDC4A7DC];
		[_stream writeLittleEndianInt32: 42 + commentLength];
		[_stream writeLittleEndianInt32: -(42 + commentLength)];
		/* TODO: Increase to 0x201 once we add compressed files. */
		[_stream writeBigEndianInt16: 0x200];
		/* Header type */
		[_stream writeInt8: 1];

		if (_archiveComment != nil) {
			[_stream writeLittleEndianInt32: 42];
			[_stream writeLittleEndianInt16: commentLength];
		} else {
			[_stream writeLittleEndianInt32: 0];
			[_stream writeLittleEndianInt16: 0];
		}

		/* Version flag */
		[_stream writeInt8: 0];

		if (_archiveComment != nil)
			[_stream writeString: _archiveComment
				    encoding: _encoding];
	} else
		[self of_fixUpLastHeader];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	_lastReturnedStream = [[[OFZooArchiveFileWriteStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: entry
		      encoding: _encoding
	      lastHeaderOffset: &_lastHeaderOffset
	      lastHeaderLength: &_lastHeaderLength] autorelease];

	return  _lastReturnedStream;
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
	_lastReturnedStream = nil;

	/*
	 * Zoo archives should be terminated with an entry that has a next
	 * header offset of 0.
	 */
	if (_mode == modeWrite) {
		static const unsigned char header[56] = {
			0xDC, 0xA7, 0xC4, 0xFD, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0xFC, 0x83
		};

		[self of_fixUpLastHeader];

		[_stream writeBuffer: header length: sizeof(header)];
	}

	[_stream release];
	_stream = nil;
}
@end

@implementation OFZooArchiveFileReadStream
- (instancetype)of_initWithArchive: (OFZooArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFZooArchiveEntry *)entry
{
	self = [super init];

	@try {
		_archive = [archive retain];
		_stream = [stream retain];

		switch (entry.compressionMethod) {
		case 0:
			_decompressedStream = [stream retain];
			break;
		case 2:
			_decompressedStream = [[OFLHADecompressingStream alloc]
			    of_initWithStream: stream
				 distanceBits: 4
			       dictionaryBits: 14];
			break;
		default:
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: [OFString
			    stringWithFormat: @"%u", entry.compressionMethod]];
		}

		_entry = [entry copy];
		_toRead = entry.uncompressedSize;

		[_stream seekToOffset: entry->_dataOffset whence: OFSeekSet];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil && _decompressedStream != nil)
		[self close];

	[_entry release];

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	[_archive release];

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

	if ([_stream isAtEndOfStream] &&
	    !_decompressedStream.hasDataInReadBuffer)
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

- (void)close
{
	if (_stream == nil || _decompressedStream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	[_stream release];
	_stream = nil;

	[_decompressedStream release];
	_decompressedStream = nil;

	[super close];
}
@end

@implementation OFZooArchiveFileWriteStream
- (instancetype)of_initWithArchive: (OFZooArchive *)archive
			    stream: (OFSeekableStream *)stream
			     entry: (OFZooArchiveEntry *)entry
			  encoding: (OFStringEncoding)encoding
		  lastHeaderOffset: (OFStreamOffset *)lastHeaderOffset
		  lastHeaderLength: (size_t *)lastHeaderLength
{
	self = [super init];

	@try {
		_archive = [archive retain];
		_entry = [entry mutableCopy];
		_encoding = encoding;
		_lastHeaderOffset = lastHeaderOffset;
		_lastHeaderLength = lastHeaderLength;

		*_lastHeaderOffset = [stream seekToOffset: 0
						   whence: OFSeekCurrent];
		*_lastHeaderLength = [_entry of_writeToStream: stream
						     encoding: _encoding];

		/*
		 * Retain stream last, so that -[close] called by -[dealloc]
		 * doesn't write in case of error.
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

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	[_archive release];

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
		_CRC16 = _OFCRC16(_CRC16, buffer, e.bytesWritten);

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	_bytesWritten += (uint32_t)length;
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

	if ((unsigned long long)offset > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	[_stream seekToOffset: *_lastHeaderOffset whence: OFSeekSet];
	_entry->_dataOffset = (uint32_t)offset;

	OFEnsure([_entry of_writeToStream: _stream
				 encoding: _encoding] == *_lastHeaderLength);
	[_stream seekToOffset: offset whence: OFSeekSet];

	[_stream release];
	_stream = nil;

	[super close];
}
@end
