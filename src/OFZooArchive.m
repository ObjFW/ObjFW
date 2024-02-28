/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#define OF_ZOO_ARCHIVE_M

#include "config.h"

#import "OFZooArchive.h"
#import "OFZooArchiveEntry.h"
#import "OFZooArchiveEntry+Private.h"
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
#import "OFNotOpenException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

enum {
	modeRead
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
		else
			@throw [OFInvalidArgumentException exception];

		_stream = [stream retain];
		_encoding = OFStringEncodingUTF8;

		if (_mode == modeRead) {
			if (![stream isKindOfClass: [OFSeekableStream class]])
				@throw [OFInvalidArgumentException exception];

			[self of_readArchiveHeader];
		}
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
		if ([mode isEqual: @"a"])
			stream = [OFIRIHandler openItemAtIRI: IRI mode: @"r+"];
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

	[_currentEntry release];

	[super dealloc];
}

- (void)of_readArchiveHeader
{
	char headerText[20];
	uint32_t firstFileOffset;

	[_stream readIntoBuffer: headerText exactLength: 20];

	if ([_stream readLittleEndianInt32] != 0xFDC4A7DC)
		@throw [OFInvalidFormatException exception];

	firstFileOffset = [_stream readLittleEndianInt32];

	if ([_stream readLittleEndianInt32] != ~(uint32_t)(firstFileOffset - 1))
		@throw [OFInvalidFormatException exception];

	/* Version */
	[_stream readBigEndianInt16];

	[_stream seekToOffset: firstFileOffset whence: OFSeekSet];
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

	if (_currentEntry->_nextHeaderOffset == 0) {
		/*
		 * End of archive is marked by a header that has the next
		 * header's offset set to 0.
		 */
		[_currentEntry release];
		_currentEntry = nil;
	}

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
	_CRC16 = OFCRC16(_CRC16, buffer, ret);

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
