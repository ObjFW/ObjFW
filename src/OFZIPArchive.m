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

#include <errno.h>

#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFData.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFSeekableStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFInflateStream.h"
#import "OFInflate64Stream.h"

#import "crc32.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFSeekFailedException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

/*
 * FIXME: Current limitations:
 *  - Split archives are not supported.
 *  - Encrypted files cannot be read.
 */

@interface OFZIPArchive ()
- (void)of_readZIPInfo;
- (void)of_readEntries;
- (void)of_closeLastReturnedStream;
- (void)of_writeCentralDirectory;
@end

@interface OFZIPArchiveLocalFileHeader: OFObject
{
@public
	uint16_t _minVersionNeeded, _generalPurposeBitFlag, _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	uint64_t _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFData *_extraField;
}

- (instancetype)initWithStream: (OFStream *)stream;
- (bool)matchesEntry: (OFZIPArchiveEntry *)entry;
@end

@interface OFZIPArchiveFileReadStream: OFStream
{
	OFStream *_stream, *_decompressedStream;
	OFZIPArchiveEntry *_entry;
	uint64_t _toRead;
	uint32_t _CRC32;
	bool _atEndOfStream;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFZIPArchiveEntry *)entry;
@end

@interface OFZIPArchiveFileWriteStream: OFStream
{
	OFStream *_stream;
	uint32_t _CRC32;
@public
	int64_t _bytesWritten;
	OFMutableZIPArchiveEntry *_entry;
}

- (instancetype)initWithStream: (OFStream *)stream
			 entry: (OFMutableZIPArchiveEntry *)entry;
@end

uint32_t
of_zip_archive_read_field32(const uint8_t **data, uint16_t *size)
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
of_zip_archive_read_field64(const uint8_t **data, uint16_t *size)
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
		if (e.errNo == EINVAL)
			@throw [OFInvalidFormatException exception];

		@throw e;
	}
}

@implementation OFZIPArchive
@synthesize archiveComment = _archiveComment;

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
		if ([mode isEqual: @"r"])
			_mode = OF_ZIP_ARCHIVE_MODE_READ;
		else if ([mode isEqual: @"w"])
			_mode = OF_ZIP_ARCHIVE_MODE_WRITE;
		else if ([mode isEqual: @"a"])
			_mode = OF_ZIP_ARCHIVE_MODE_APPEND;
		else
			@throw [OFInvalidArgumentException exception];

		_stream = [stream retain];
		_entries = [[OFMutableArray alloc] init];
		_pathToEntryMap = [[OFMutableDictionary alloc] init];

		if (_mode == OF_ZIP_ARCHIVE_MODE_READ ||
		    _mode == OF_ZIP_ARCHIVE_MODE_APPEND) {
			if (![stream isKindOfClass: [OFSeekableStream class]])
				@throw [OFInvalidArgumentException exception];

			[self of_readZIPInfo];
			[self of_readEntries];
		}

		if (_mode == OF_ZIP_ARCHIVE_MODE_APPEND) {
			_offset = _centralDirectoryOffset;
			seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
			    (of_offset_t)_offset, SEEK_SET);
		}
	} @catch (id e) {
		/*
		 * If we are in write or append mode, we do not want -[close]
		 * to write anything to it on error - after all, it might not
		 * be a ZIP file which we would destroy otherwise.
		 */
		[_stream release];
		_stream = nil;

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

	[_stream release];
	[_archiveComment release];
	[_entries release];
	[_pathToEntryMap release];
	[_lastReturnedStream release];

	[super dealloc];
}

- (void)of_readZIPInfo
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t commentLength;
	of_offset_t offset = -22;
	bool valid = false;

	do {
		seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
		    offset, SEEK_END);

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

		seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
		    offset - 20, SEEK_END);

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

		seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
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

- (void)of_readEntries
{
	void *pool = objc_autoreleasePoolPush();

	if (_centralDirectoryOffset < 0 ||
	    (of_offset_t)_centralDirectoryOffset != _centralDirectoryOffset)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
	    (of_offset_t)_centralDirectoryOffset, SEEK_SET);

	for (size_t i = 0; i < _centralDirectoryEntries; i++) {
		OFZIPArchiveEntry *entry = [[[OFZIPArchiveEntry alloc]
		    of_initWithStream: _stream] autorelease];

		if ([_pathToEntryMap objectForKey: entry.fileName] != nil)
			@throw [OFInvalidFormatException exception];

		[_entries addObject: entry];
		[_pathToEntryMap setObject: entry
				    forKey: entry.fileName];
	}

	objc_autoreleasePoolPop(pool);
}

- (OFArray *)entries
{
	return [[_entries copy] autorelease];
}

- (OFString *)archiveComment
{
	return _archiveComment;
}

- (void)setArchiveComment: (OFString *)comment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old;

	if (comment.UTF8StringLength > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	old = _archiveComment;
	_archiveComment = [comment copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)of_closeLastReturnedStream
{
	[_lastReturnedStream close];

	if ((_mode == OF_ZIP_ARCHIVE_MODE_WRITE ||
	    _mode == OF_ZIP_ARCHIVE_MODE_APPEND) &&
	    [_lastReturnedStream isKindOfClass:
	    [OFZIPArchiveFileWriteStream class]]) {
		OFZIPArchiveFileWriteStream *stream =
		    (OFZIPArchiveFileWriteStream *)_lastReturnedStream;

		if (INT64_MAX - _offset < stream->_bytesWritten)
			@throw [OFOutOfRangeException exception];

		_offset += stream->_bytesWritten;

		if (stream->_entry != nil) {
			[_entries addObject: stream->_entry];
			[_pathToEntryMap setObject: stream->_entry
					    forKey: [stream->_entry fileName]];
		}
	}

	[_lastReturnedStream release];
	_lastReturnedStream = nil;
}

- (OFStream *)streamForReadingFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFZIPArchiveEntry *entry;
	OFZIPArchiveLocalFileHeader *localFileHeader;
	int64_t offset64;

	if (_mode != OF_ZIP_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	if ((entry = [_pathToEntryMap objectForKey: path]) == nil)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							       mode: @"r"
							      errNo: ENOENT];

	[self of_closeLastReturnedStream];

	offset64 = entry.of_localFileHeaderOffset;
	if (offset64 < 0 || (of_offset_t)offset64 != offset64)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat((OFSeekableStream *)_stream,
	    (of_offset_t)offset64, SEEK_SET);
	localFileHeader = [[[OFZIPArchiveLocalFileHeader alloc]
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

	_lastReturnedStream = [[OFZIPArchiveFileReadStream alloc]
	     of_initWithStream: _stream
			 entry: entry];

	objc_autoreleasePoolPop(pool);

	return [[_lastReturnedStream retain] autorelease];
}

- (OFStream *)streamForWritingEntry: (OFZIPArchiveEntry *)entry_
{
	/* TODO: Avoid data descriptor when _stream is an OFSeekableStream */
	int64_t offsetAdd = 0;
	void *pool;
	OFMutableZIPArchiveEntry *entry;
	OFString *fileName;
	OFData *extraField;
	uint16_t fileNameLength, extraFieldLength;

	if (_mode != OF_ZIP_ARCHIVE_MODE_WRITE &&
	    _mode != OF_ZIP_ARCHIVE_MODE_APPEND)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	entry = [[entry_ mutableCopy] autorelease];

	if ([_pathToEntryMap objectForKey: entry.fileName] != nil)
		@throw [OFOpenItemFailedException
		    exceptionWithPath: entry.fileName
				 mode: @"w"
				errNo: EEXIST];

	if (entry.compressionMethod !=
	    OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[self of_closeLastReturnedStream];

	fileName = entry.fileName;
	fileNameLength = fileName.UTF8StringLength;
	extraField = entry.extraField;
	extraFieldLength = extraField.count;

	if (UINT16_MAX - extraFieldLength < 20)
		@throw [OFOutOfRangeException exception];

	entry.versionMadeBy = (entry.versionMadeBy & 0xFF00) | 45;
	entry.minVersionNeeded = (entry.minVersionNeeded & 0xFF00) | 45;
	entry.compressedSize = 0;
	entry.uncompressedSize = 0;
	entry.CRC32 = 0;
	entry.generalPurposeBitFlag |= (1 << 3) | (1 << 11);
	entry.of_localFileHeaderOffset = _offset;

	[_stream writeLittleEndianInt32: 0x04034B50];
	[_stream writeLittleEndianInt16: entry.minVersionNeeded];
	[_stream writeLittleEndianInt16: entry.generalPurposeBitFlag];
	[_stream writeLittleEndianInt16: entry.compressionMethod];
	[_stream writeLittleEndianInt16: entry.of_lastModifiedFileTime];
	[_stream writeLittleEndianInt16: entry.of_lastModifiedFileDate];
	/* We use the data descriptor */
	[_stream writeLittleEndianInt32: 0];
	/* We use ZIP64 */
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];
	[_stream writeLittleEndianInt16: fileNameLength];
	[_stream writeLittleEndianInt16: extraFieldLength + 20];
	offsetAdd += 4 + (5 * 2) + (3 * 4) + (2 * 2);

	[_stream writeString: fileName];
	offsetAdd += fileNameLength;

	[_stream writeLittleEndianInt16:
	    OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64];
	[_stream writeLittleEndianInt16: 16];
	/* We use the data descriptor */
	[_stream writeLittleEndianInt64: 0];
	[_stream writeLittleEndianInt64: 0];
	offsetAdd += (2 * 2) + (2 * 8);

	if (extraField != nil)
		[_stream writeData: extraField];
	offsetAdd += extraFieldLength;

	if (INT64_MAX - _offset < offsetAdd)
		@throw [OFOutOfRangeException exception];

	_offset += offsetAdd;

	_lastReturnedStream = [[OFZIPArchiveFileWriteStream alloc]
	     initWithStream: _stream
		      entry: entry];

	objc_autoreleasePoolPop(pool);

	return [[_lastReturnedStream retain] autorelease];
}

- (void)of_writeCentralDirectory
{
	void *pool = objc_autoreleasePoolPush();

	_centralDirectoryEntries = 0;
	_centralDirectoryEntriesInDisk = 0;
	_centralDirectorySize = 0;
	_centralDirectoryOffset = _offset;

	for (OFZIPArchiveEntry *entry in _entries) {
		_centralDirectorySize += [entry of_writeToStream: _stream];
		_centralDirectoryEntries++;
		_centralDirectoryEntriesInDisk++;
	}

	/* ZIP64 end of central directory */
	[_stream writeLittleEndianInt32: 0x06064B50];
	[_stream writeLittleEndianInt64: 44];	/* Remaining size */
	[_stream writeLittleEndianInt16: 45];	/* Version made by */
	[_stream writeLittleEndianInt16: 45];	/* Version required */
	[_stream writeLittleEndianInt32: _diskNumber];
	[_stream writeLittleEndianInt32: _centralDirectoryDisk];
	[_stream writeLittleEndianInt64: _centralDirectoryEntriesInDisk];
	[_stream writeLittleEndianInt64: _centralDirectoryEntries];
	[_stream writeLittleEndianInt64: _centralDirectorySize];
	[_stream writeLittleEndianInt64: _centralDirectoryOffset];

	/* ZIP64 end of central directory locator */
	[_stream writeLittleEndianInt32: 0x07064B50];
	[_stream writeLittleEndianInt32: _diskNumber];
	[_stream writeLittleEndianInt64:
	    _centralDirectoryOffset + _centralDirectorySize];
	[_stream writeLittleEndianInt32: 1];	/* Total number of disks */

	/* End of central directory */
	[_stream writeLittleEndianInt32: 0x06054B50];
	[_stream writeLittleEndianInt16: 0xFFFF];	/* Disk number */
	[_stream writeLittleEndianInt16: 0xFFFF];	/* CD disk */
	[_stream writeLittleEndianInt16: 0xFFFF];	/* CD entries in disk */
	[_stream writeLittleEndianInt16: 0xFFFF];	/* CD entries */
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];	/* CD size */
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];	/* CD offset */
	[_stream writeLittleEndianInt16: _archiveComment.UTF8StringLength];
	if (_archiveComment != nil)
		[_stream writeString: _archiveComment];

	objc_autoreleasePoolPop(pool);
}

- (void)close
{
	if (_stream == nil)
		return;

	[self of_closeLastReturnedStream];

	if (_mode == OF_ZIP_ARCHIVE_MODE_WRITE ||
	    _mode == OF_ZIP_ARCHIVE_MODE_APPEND)
		[self of_writeCentralDirectory];

	[_stream release];
	_stream = nil;
}
@end

@implementation OFZIPArchiveLocalFileHeader
- (instancetype)initWithStream: (OFStream *)stream
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableData *extraField = nil;
		uint16_t fileNameLength, extraFieldLength;
		of_string_encoding_t encoding;
		size_t ZIP64Index;
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
		if (extraFieldLength > 0)
			extraField = [[[stream readDataWithCount:
			    extraFieldLength] mutableCopy] autorelease];

		ZIP64Index = of_zip_archive_entry_extra_field_find(extraField,
		    OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64, &ZIP64Size);

		if (ZIP64Index != OF_NOT_FOUND) {
			const uint8_t *ZIP64 =
			    [extraField itemAtIndex: ZIP64Index];
			of_range_t range =
			    of_range(ZIP64Index - 4, ZIP64Size + 4);

			if (_uncompressedSize == 0xFFFFFFFF)
				_uncompressedSize = of_zip_archive_read_field64(
				    &ZIP64, &ZIP64Size);
			if (_compressedSize == 0xFFFFFFFF)
				_compressedSize = of_zip_archive_read_field64(
				    &ZIP64, &ZIP64Size);

			if (ZIP64Size > 0)
				@throw [OFInvalidFormatException exception];

			[extraField removeItemsInRange: range];
		}

		if (extraField.count > 0) {
			[extraField makeImmutable];
			_extraField = [extraField copy];
		}

		objc_autoreleasePoolPop(pool);
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
	if (_compressionMethod != entry.compressionMethod ||
	    _lastModifiedFileTime != entry.of_lastModifiedFileTime ||
	    _lastModifiedFileDate != entry.of_lastModifiedFileDate)
		return false;

	if (!(_generalPurposeBitFlag & (1 << 3)))
		if (_CRC32 != entry.CRC32 ||
		    _compressedSize != entry.compressedSize ||
		    _uncompressedSize != entry.uncompressedSize)
			return false;

	if (![_fileName isEqual: entry.fileName])
		return false;

	return true;
}
@end

@implementation OFZIPArchiveFileReadStream
- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFZIPArchiveEntry *)entry
{
	self = [super init];

	@try {
		_stream = [stream retain];

		switch (entry.compressionMethod) {
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE:
			_decompressedStream = [stream retain];
			break;
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE:
			_decompressedStream = [[OFInflateStream alloc]
			    initWithStream: stream];
			break;
		case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64:
			_decompressedStream = [[OFInflate64Stream alloc]
			    initWithStream: stream];
			break;
		default:
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
		}

		_entry = [entry copy];
		_toRead = entry.uncompressedSize;
		_CRC32 = ~0;
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

#if SIZE_MAX >= UINT64_MAX
	if (length > UINT64_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if ((uint64_t)length > _toRead)
		length = (size_t)_toRead;

	ret = [_decompressedStream readIntoBuffer: buffer
					   length: length];

	_toRead -= ret;
	_CRC32 = of_crc32(_CRC32, buffer, ret);

	if (_toRead == 0) {
		_atEndOfStream = true;

		if (~_CRC32 != _entry.CRC32) {
			OFString *actualChecksum = [OFString stringWithFormat:
			    @"%08" PRIX32, ~_CRC32];
			OFString *expectedChecksum = [OFString stringWithFormat:
			    @"%08" PRIX32, _entry.CRC32];

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
	[_stream release];
	_stream = nil;

	[_decompressedStream release];
	_decompressedStream = nil;

	[super close];
}
@end

@implementation OFZIPArchiveFileWriteStream
- (instancetype)initWithStream: (OFStream *)stream
			 entry: (OFMutableZIPArchiveEntry *)entry
{
	self = [super init];

	_stream = [stream retain];
	_entry = [entry retain];
	_CRC32 = ~0;

	return self;
}

- (void)dealloc
{
	[self close];

	[_stream release];
	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	size_t bytesWritten;

#if SIZE_MAX >= INT64_MAX
	if (length > INT64_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if (INT64_MAX - _bytesWritten < (int64_t)length)
		@throw [OFOutOfRangeException exception];

	bytesWritten = [_stream writeBuffer: buffer
				     length: length];

	_bytesWritten += (int64_t)bytesWritten;
	_CRC32 = of_crc32(_CRC32, buffer, length);

	return bytesWritten;
}

- (void)close
{
	if (_stream == nil)
		return;

	[_stream writeLittleEndianInt32: 0x08074B50];
	[_stream writeLittleEndianInt32: _CRC32];
	[_stream writeLittleEndianInt64: _bytesWritten];
	[_stream writeLittleEndianInt64: _bytesWritten];

	[_stream release];
	_stream = nil;

	_entry.CRC32 = ~_CRC32;
	_entry.compressedSize = _bytesWritten;
	_entry.uncompressedSize = _bytesWritten;
	[_entry makeImmutable];

	_bytesWritten += (2 * 4 + 2 * 8);
}
@end
