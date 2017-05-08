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

#include <errno.h>

#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFDataArray.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFSeekableStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFDeflateStream.h"
#import "OFDeflate64Stream.h"

#import "crc32.h"

#import "OFChecksumFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFUnsupportedVersionException.h"

/*
 * FIXME: Current limitations:
 *  - Split archives are not supported.
 *  - Write support is missing.
 *  - Encrypted files cannot be read.
 */

@interface OFZIPArchive ()
- (void)OF_readZIPInfo;
- (void)OF_readEntries;
@end

@interface OFZIPArchive_LocalFileHeader: OFObject
{
@public
	uint16_t _minVersionNeeded, _generalPurposeBitFlag, _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	uint64_t _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFDataArray *_extraField;
}

- initWithStream: (OFStream *)stream;
- (bool)matchesEntry: (OFZIPArchiveEntry *)entry;
@end

@interface OFZIPArchive_FileStream: OFStream
{
	OFStream *_stream, *_decompressedStream;
	OFZIPArchive_LocalFileHeader *_localFileHeader;
	bool _hasDataDescriptor;
	uint64_t _size;
	uint32_t _CRC32;
	bool _atEndOfStream, _closed;
}

-  initWithStream: (OFStream *)path
  localFileHeader: (OFZIPArchive_LocalFileHeader *)localFileHeader;
@end

uint32_t
of_zip_archive_read_field32(uint8_t **data, uint16_t *size)
{
	uint32_t field = 0;

	if (*size < 4)
		@throw [OFInvalidFormatException exception];

	for (uint8_t i = 0; i < 4; i++)
		field |= (uint32_t)(*data)[i] << (i * 8);

	*data += 4;
	*size -= 4;

	return field;
}

uint64_t
of_zip_archive_read_field64(uint8_t **data, uint16_t *size)
{
	uint64_t field = 0;

	if (*size < 8)
		@throw [OFInvalidFormatException exception];

	for (uint8_t i = 0; i < 8; i++)
		field |= (uint64_t)(*data)[i] << (i * 8);

	*data += 8;
	*size -= 8;

	return field;
}

static void
seekOrThrowInvalidFormat(OFSeekableStream *stream,
    of_offset_t offset, int whence)
{
	@try {
		[stream seekToOffset: offset
			      whence: whence];
	} @catch (OFSeekFailedException *e) {
		if ([e errNo] == EINVAL)
			@throw [OFInvalidFormatException exception];

		@throw e;
	}
}

@implementation OFZIPArchive
@synthesize archiveComment = _archiveComment;

+ (instancetype)archiveWithSeekableStream: (OFSeekableStream *)stream
{
	return [[[self alloc] initWithSeekableStream: stream] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)archiveWithPath: (OFString *)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}
#endif

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithSeekableStream: (OFSeekableStream *)stream
{
	self = [super init];

	@try {
		_stream = [stream retain];

		[self OF_readZIPInfo];
		[self OF_readEntries];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- initWithPath: (OFString *)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];
	@try {
		return [self initWithSeekableStream: file];
	} @finally {
		[file release];
	}
}
#endif

- (void)dealloc
{
	[_stream release];
	[_archiveComment release];
	[_entries release];
	[_pathToEntryMap release];
	[_lastReturnedStream release];

	[super dealloc];
}

- (void)OF_readZIPInfo
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t commentLength;
	of_offset_t offset = -22;
	bool valid = false;

	do {
		seekOrThrowInvalidFormat(_stream, offset, SEEK_END);

		if ([_stream readLittleEndianInt32] == 0x06054B50) {
			valid = true;
			break;
		}
	} while (--offset >= -65557);

	if (!valid)
		@throw [OFInvalidFormatException exception];

	_diskNumber = [_stream readLittleEndianInt16];
	_centralDirectoryDisk = [_stream readLittleEndianInt16];
	_centralDirectoryEntriesInDisk = [_stream readLittleEndianInt16];
	_centralDirectoryEntries = [_stream readLittleEndianInt16];
	_centralDirectorySize = [_stream readLittleEndianInt32];
	_centralDirectoryOffset = [_stream readLittleEndianInt32];

	commentLength = [_stream readLittleEndianInt16];
	_archiveComment = [[_stream
	    readStringWithLength: commentLength
			encoding: OF_STRING_ENCODING_CODEPAGE_437] copy];

	if (_diskNumber == 0xFFFF ||
	    _centralDirectoryDisk == 0xFFFF ||
	    _centralDirectoryEntriesInDisk == 0xFFFF ||
	    _centralDirectoryEntries == 0xFFFF ||
	    _centralDirectorySize == 0xFFFFFFFF ||
	    _centralDirectoryOffset == 0xFFFFFFFF) {
		int64_t offset64;
		uint64_t size;

		seekOrThrowInvalidFormat(_stream, offset - 20, SEEK_END);

		if ([_stream readLittleEndianInt32] != 0x07064B50) {
			objc_autoreleasePoolPop(pool);
			return;
		}

		/*
		 * FIXME: Handle number of the disk containing ZIP64 end of
		 * central directory record.
		 */
		[_stream readLittleEndianInt32];
		offset64 = [_stream readLittleEndianInt64];

		if (offset64 < 0 || (of_offset_t)offset64 != offset64)
			@throw [OFOutOfRangeException exception];

		seekOrThrowInvalidFormat(_stream,
		    (of_offset_t)offset64, SEEK_SET);

		if ([_stream readLittleEndianInt32] != 0x06064B50)
			@throw [OFInvalidFormatException exception];

		size = [_stream readLittleEndianInt64];
		if (size < 44)
			@throw [OFInvalidFormatException exception];

		/* version made by */
		[_stream readLittleEndianInt16];
		/* version needed to extract */
		[_stream readLittleEndianInt16];

		_diskNumber = [_stream readLittleEndianInt32];
		_centralDirectoryDisk = [_stream readLittleEndianInt32];
		_centralDirectoryEntriesInDisk =
		    [_stream readLittleEndianInt64];
		_centralDirectoryEntries = [_stream readLittleEndianInt64];
		_centralDirectorySize = [_stream readLittleEndianInt64];
		_centralDirectoryOffset = [_stream readLittleEndianInt64];

		if (_centralDirectoryOffset < 0 ||
		    (of_offset_t)_centralDirectoryOffset !=
		    _centralDirectoryOffset)
			@throw [OFOutOfRangeException exception];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)OF_readEntries
{
	void *pool = objc_autoreleasePoolPush();

	if (_centralDirectoryOffset < 0 ||
	    (of_offset_t)_centralDirectoryOffset != _centralDirectoryOffset)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat(_stream,
	    (of_offset_t)_centralDirectoryOffset, SEEK_SET);

	_entries = [[OFMutableArray alloc] init];
	_pathToEntryMap = [[OFMutableDictionary alloc] init];

	for (size_t i = 0; i < _centralDirectoryEntries; i++) {
		OFZIPArchiveEntry *entry = [[[OFZIPArchiveEntry alloc]
		    OF_initWithStream: _stream] autorelease];

		if ([_pathToEntryMap objectForKey: [entry fileName]] != nil)
			@throw [OFInvalidFormatException exception];

		[_entries addObject: entry];
		[_pathToEntryMap setObject: entry
				    forKey: [entry fileName]];
	}

	[_entries makeImmutable];
	[_pathToEntryMap makeImmutable];

	objc_autoreleasePoolPop(pool);
}

- (OFArray *)entries
{
	return [[_entries copy] autorelease];
}

- (OFStream *)streamForReadingFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFZIPArchiveEntry *entry = [_pathToEntryMap objectForKey: path];
	OFZIPArchive_LocalFileHeader *localFileHeader;
	int64_t offset64;

	if (entry == nil)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							       mode: @"rb"
							      errNo: ENOENT];

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	offset64 = [entry OF_localFileHeaderOffset];
	if (offset64 < 0 || (of_offset_t)offset64 != offset64)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat(_stream, (of_offset_t)offset64, SEEK_SET);
	localFileHeader = [[[OFZIPArchive_LocalFileHeader alloc]
	    initWithStream: _stream] autorelease];

	if (![localFileHeader matchesEntry: entry])
		@throw [OFInvalidFormatException exception];

	if ((localFileHeader->_minVersionNeeded & 0xFF) > 45) {
		OFString *version = [OFString stringWithFormat: @"%u.%u",
		    (localFileHeader->_minVersionNeeded & 0xFF) / 10,
		    (localFileHeader->_minVersionNeeded & 0xFF) % 10];

		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	_lastReturnedStream = [[OFZIPArchive_FileStream alloc]
	     initWithStream: _stream
	    localFileHeader: localFileHeader];

	objc_autoreleasePoolPop(pool);

	return [[_lastReturnedStream retain] autorelease];
}
@end

@implementation OFZIPArchive_LocalFileHeader
- initWithStream: (OFStream *)stream
{
	self = [super init];

	@try {
		uint16_t fileNameLength, extraFieldLength;
		of_string_encoding_t encoding;
		uint8_t *ZIP64;
		uint16_t ZIP64Size;

		if ([stream readLittleEndianInt32] != 0x04034B50)
			@throw [OFInvalidFormatException exception];

		_minVersionNeeded = [stream readLittleEndianInt16];
		_generalPurposeBitFlag = [stream readLittleEndianInt16];
		_compressionMethod = [stream readLittleEndianInt16];
		_lastModifiedFileTime = [stream readLittleEndianInt16];
		_lastModifiedFileDate = [stream readLittleEndianInt16];
		_CRC32 = [stream readLittleEndianInt32];
		_compressedSize = [stream readLittleEndianInt32];
		_uncompressedSize = [stream readLittleEndianInt32];
		fileNameLength = [stream readLittleEndianInt16];
		extraFieldLength = [stream readLittleEndianInt16];
		encoding = (_generalPurposeBitFlag & (1 << 11)
		    ? OF_STRING_ENCODING_UTF_8
		    : OF_STRING_ENCODING_CODEPAGE_437);

		_fileName = [[stream readStringWithLength: fileNameLength
						 encoding: encoding] copy];
		_extraField = [[stream
		    readDataArrayWithCount: extraFieldLength] retain];

		of_zip_archive_entry_extra_field_find(_extraField,
		    OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64, &ZIP64, &ZIP64Size);

		if (ZIP64 != NULL) {
			if (_uncompressedSize == 0xFFFFFFFF)
				_uncompressedSize = of_zip_archive_read_field64(
				    &ZIP64, &ZIP64Size);
			if (_compressedSize == 0xFFFFFFFF)
				_compressedSize = of_zip_archive_read_field64(
				    &ZIP64, &ZIP64Size);

			if (ZIP64Size > 0)
				@throw [OFInvalidFormatException exception];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_fileName release];
	[_extraField release];

	[super dealloc];
}

- (bool)matchesEntry: (OFZIPArchiveEntry *)entry
{
	if (_compressionMethod != [entry compressionMethod] ||
	    _lastModifiedFileTime != [entry OF_lastModifiedFileTime] ||
	    _lastModifiedFileDate != [entry OF_lastModifiedFileDate])
		return false;

	if (!(_generalPurposeBitFlag & (1 << 3)))
		if (_CRC32 != [entry CRC32] ||
		    _compressedSize != [entry compressedSize] ||
		    _uncompressedSize != [entry uncompressedSize])
			return false;

	if (![_fileName isEqual: [entry fileName]])
		return false;

	return true;
}
@end

@implementation OFZIPArchive_FileStream
-  initWithStream: (OFStream *)stream
  localFileHeader: (OFZIPArchive_LocalFileHeader *)localFileHeader
{
	self = [super init];

	@try {
		_stream = [stream retain];

		switch (localFileHeader->_compressionMethod) {
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE:
			_decompressedStream = [stream retain];
			break;
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE:
			_decompressedStream = [[OFDeflateStream alloc]
			    initWithStream: stream];
			break;
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64:
			_decompressedStream = [[OFDeflate64Stream alloc]
			    initWithStream: stream];
			break;
		default:
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
		}

		_localFileHeader = [localFileHeader retain];
		_hasDataDescriptor = (localFileHeader->_generalPurposeBitFlag &
		    (1 << 3));
		_size = localFileHeader->_uncompressedSize;
		_CRC32 = ~0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_stream release];
	[_decompressedStream release];
	[_localFileHeader release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t min, ret;

	if (_atEndOfStream || _closed)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

	if (_hasDataDescriptor) {
		if ([_decompressedStream isAtEndOfStream]) {
			uint32_t CRC32;

			_atEndOfStream = true;

			CRC32 = [_stream readLittleEndianInt32];
			if (CRC32 == 0x08074B50)
				CRC32 = [_stream readLittleEndianInt32];

			if (~_CRC32 != CRC32)
				@throw [OFChecksumFailedException exception];

			/*
			 * FIXME: Check (un)compressed length!
			 * (Note: Both are 64 bit if the entry uses ZIP64!)
			 */

			return 0;
		}

		ret = [_decompressedStream readIntoBuffer: buffer
						   length: length];
	} else {
		if (_size == 0) {
			_atEndOfStream = true;

			if (~_CRC32 != _localFileHeader->_CRC32)
				@throw [OFChecksumFailedException exception];

			return 0;
		}

		min = (length < _size ? length : (size_t)_size);
		ret = [_decompressedStream readIntoBuffer: buffer
						   length: min];
		_size -= ret;
	}

	_CRC32 = of_crc32(_CRC32, buffer, ret);

	return ret;
}

- (void)close
{
	_closed = true;

	[super close];
}
@end
