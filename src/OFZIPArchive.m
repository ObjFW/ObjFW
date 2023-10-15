/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#define OF_ZIP_ARCHIVE_M

#include "config.h"

#include <errno.h>

#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFArchiveIRIHandler.h"
#import "OFArray.h"
#import "OFCRC32.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFInflate64Stream.h"
#import "OFInflateStream.h"
#import "OFSeekableStream.h"
#import "OFStream.h"

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
#import "OFWriteFailedException.h"

/*
 * TODO: Current limitations:
 *  - Encrypted files cannot be read.
 */

enum {
	modeRead,
	modeWrite,
	modeAppend
};

OF_DIRECT_MEMBERS
@interface OFZIPArchive ()
- (void)of_readZIPInfo;
- (void)of_readEntries;
- (void)of_writeCentralDirectory;
@end

OF_DIRECT_MEMBERS
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

OF_DIRECT_MEMBERS
@interface OFZIPArchiveFileReadStream: OFStream
{
	OFZIPArchive *_archive;
	OFZIPArchiveEntryCompressionMethod _compressionMethod;
	OF_KINDOF(OFStream *) _decompressedStream;
	OFZIPArchiveEntry *_entry;
	unsigned long long _toRead;
	uint32_t _CRC32;
	bool _atEndOfStream;
}

- (instancetype)of_initWithArchive: (OFZIPArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFZIPArchiveEntry *)entry;
@end

OF_DIRECT_MEMBERS
@interface OFZIPArchiveFileWriteStream: OFStream
{
	OFZIPArchive *_archive;
	OF_KINDOF(OFStream *) _stream;
	uint32_t _CRC32;
	OFStreamOffset _CRC32Offset, _size64Offset;
@public
	unsigned long long _bytesWritten;
	OFMutableZIPArchiveEntry *_entry;
}

- (instancetype)of_initWithArchive: (OFZIPArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFMutableZIPArchiveEntry *)entry
		       CRC32Offset: (OFStreamOffset)CRC32Offset
		      size64Offset: (OFStreamOffset)size64Offset;
@end

uint32_t
OFZIPArchiveReadField32(const uint8_t **data, uint16_t *size)
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
OFZIPArchiveReadField64(const uint8_t **data, uint16_t *size)
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

@implementation OFZIPArchive
@synthesize delegate = _delegate, archiveComment = _archiveComment;

static void
seekOrThrowInvalidFormat(OFZIPArchive *archive, const uint32_t *diskNumber,
    OFStreamOffset offset, OFSeekWhence whence)
{
	if (diskNumber != NULL && *diskNumber != archive->_diskNumber) {
		OFStream *oldStream = archive->_stream;
		OFSeekableStream *stream;

		if (archive->_mode != modeRead ||
		    *diskNumber > archive->_lastDiskNumber)
			@throw [OFInvalidFormatException exception];

		stream = [archive->_delegate archive: archive
				   wantsPartNumbered: *diskNumber
				      lastPartNumber: archive->_lastDiskNumber];

		if (stream == nil)
			@throw [OFInvalidFormatException exception];

		archive->_diskNumber = *diskNumber;
		archive->_stream = [stream retain];
		[oldStream release];
	}

	@try {
		[archive->_stream seekToOffset: offset whence: whence];
	} @catch (OFSeekFailedException *e) {
		if (e.errNo == EINVAL)
			@throw [OFInvalidFormatException exception];

		@throw e;
	}
}

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
	return OFArchiveIRIHandlerIRIForFileInArchive(@"zip", path, IRI);
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
			_mode = modeAppend;
		else
			@throw [OFInvalidArgumentException exception];

		_stream = [stream retain];
		_entries = [[OFMutableArray alloc] init];
		_pathToEntryMap = [[OFMutableDictionary alloc] init];

		if (_mode == modeRead || _mode == modeAppend) {
			if (![stream isKindOfClass: [OFSeekableStream class]])
				@throw [OFInvalidArgumentException exception];

			[self of_readZIPInfo];
			[self of_readEntries];
		}

		if (_mode == modeAppend) {
			_offset = _centralDirectoryOffset;
			seekOrThrowInvalidFormat(self, NULL,
			    (OFStreamOffset)_offset, OFSeekSet);
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

	[_stream release];
	[_archiveComment release];
	[_entries release];
	[_pathToEntryMap release];

	[super dealloc];
}

- (void)of_readZIPInfo
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t commentLength;
	OFStreamOffset offset = -22;
	bool valid = false;

	do {
		seekOrThrowInvalidFormat(self, NULL, offset, OFSeekEnd);

		if ([_stream readLittleEndianInt32] == 0x06054B50) {
			valid = true;
			break;
		}
	} while (--offset >= -65557);

	if (!valid)
		@throw [OFInvalidFormatException exception];

	_diskNumber = _lastDiskNumber = [_stream readLittleEndianInt16];
	_centralDirectoryDisk = [_stream readLittleEndianInt16];
	_centralDirectoryEntriesInDisk = [_stream readLittleEndianInt16];
	_centralDirectoryEntries = [_stream readLittleEndianInt16];
	_centralDirectorySize = [_stream readLittleEndianInt32];
	_centralDirectoryOffset = [_stream readLittleEndianInt32];

	commentLength = [_stream readLittleEndianInt16];
	_archiveComment = [[_stream
	    readStringWithLength: commentLength
			encoding: OFStringEncodingCodepage437] copy];

	if (_lastDiskNumber == 0xFFFF ||
	    _centralDirectoryDisk == 0xFFFF ||
	    _centralDirectoryEntriesInDisk == 0xFFFF ||
	    _centralDirectoryEntries == 0xFFFF ||
	    _centralDirectorySize == 0xFFFFFFFF ||
	    _centralDirectoryOffset == 0xFFFFFFFF) {
		uint32_t diskNumber;
		int64_t offset64;
		uint64_t size;

		seekOrThrowInvalidFormat(self, NULL, offset - 20, OFSeekEnd);

		if ([_stream readLittleEndianInt32] != 0x07064B50) {
			objc_autoreleasePoolPop(pool);
			return;
		}

		/*
		 * FIXME: Handle number of the disk containing ZIP64 end of
		 * central directory record.
		 */
		diskNumber = [_stream readLittleEndianInt32];
		offset64 = [_stream readLittleEndianInt64];
		_lastDiskNumber = [_stream readLittleEndianInt32];
		if (_lastDiskNumber == 0)
			@throw [OFInvalidFormatException exception];
		_lastDiskNumber--;

		if (offset64 < 0 || (OFStreamOffset)offset64 != offset64)
			@throw [OFOutOfRangeException exception];

		seekOrThrowInvalidFormat(self, &diskNumber,
		    (OFStreamOffset)offset64, OFSeekSet);

		if ([_stream readLittleEndianInt32] != 0x06064B50)
			@throw [OFInvalidFormatException exception];

		size = [_stream readLittleEndianInt64];
		if (size < 44)
			@throw [OFInvalidFormatException exception];

		/* version made by */
		[_stream readLittleEndianInt16];
		/* version needed to extract */
		[_stream readLittleEndianInt16];

		if ([_stream readLittleEndianInt32] != _diskNumber)
			@throw [OFInvalidFormatException exception];

		_centralDirectoryDisk = [_stream readLittleEndianInt32];
		_centralDirectoryEntriesInDisk =
		    [_stream readLittleEndianInt64];
		_centralDirectoryEntries = [_stream readLittleEndianInt64];
		_centralDirectorySize = [_stream readLittleEndianInt64];
		_centralDirectoryOffset = [_stream readLittleEndianInt64];

		if (_centralDirectoryOffset < 0 ||
		    (OFStreamOffset)_centralDirectoryOffset !=
		    _centralDirectoryOffset)
			@throw [OFOutOfRangeException exception];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)of_readEntries
{
	void *pool = objc_autoreleasePoolPush();

	if (_centralDirectoryOffset < 0 ||
	    (OFStreamOffset)_centralDirectoryOffset != _centralDirectoryOffset)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat(self, &_centralDirectoryDisk,
	    (OFStreamOffset)_centralDirectoryOffset, OFSeekSet);

	for (size_t i = 0; i < _centralDirectoryEntries; i++) {
		OFZIPArchiveEntry *entry;
		char buffer;

		/*
		 * The stream might have 0 bytes left to read, but might not
		 * realize that before a read is attempted, where it will then
		 * return a length of 0. But OFZIPArchiveEntry expects to be
		 * able to read the entire entry and will then throw an
		 * OFTruncatedDataException. Therefore, try to peek one byte to
		 * make sure the stream realizes that it's at the end.
		 */
		if ([_stream readIntoBuffer: &buffer length: 1] == 1)
			[_stream unreadFromBuffer: &buffer length: 1];

		if ([_stream isAtEndOfStream]) {
			OFStream *oldStream = _stream;
			OFSeekableStream *stream;

			if (_diskNumber >= _lastDiskNumber)
				@throw [OFTruncatedDataException exception];

			stream = [_delegate archive: self
				  wantsPartNumbered: _diskNumber + 1
				     lastPartNumber: _lastDiskNumber];

			if (stream == nil)
				@throw [OFInvalidFormatException exception];

			_diskNumber++;
			_stream = [stream retain];
			[oldStream release];
		}

		entry = [[[OFZIPArchiveEntry alloc]
		    of_initWithStream: _stream] autorelease];

		if ([_pathToEntryMap objectForKey: entry.fileName] != nil)
			@throw [OFInvalidFormatException exception];

		[_entries addObject: entry];
		[_pathToEntryMap setObject: entry forKey: entry.fileName];
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

- (OFStream *)streamForReadingFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFZIPArchiveEntry *entry;
	OFZIPArchiveLocalFileHeader *localFileHeader;
	uint32_t startDiskNumber;
	int64_t offset64;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_mode != modeRead)
		@throw [OFInvalidArgumentException exception];

	if ((entry = [_pathToEntryMap objectForKey: path]) == nil)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							       mode: @"r"
							      errNo: ENOENT];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	startDiskNumber = entry.of_startDiskNumber;
	offset64 = entry.of_localFileHeaderOffset;
	if (offset64 < 0 || (OFStreamOffset)offset64 != offset64)
		@throw [OFOutOfRangeException exception];

	seekOrThrowInvalidFormat(self, &startDiskNumber,
	    (OFStreamOffset)offset64, OFSeekSet);
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

	objc_autoreleasePoolPop(pool);

	_lastReturnedStream = [[[OFZIPArchiveFileReadStream alloc]
	    of_initWithArchive: self
			stream: _stream
			 entry: entry] autorelease];

	return _lastReturnedStream;
}

- (OFStream *)streamForWritingEntry: (OFZIPArchiveEntry *)entry_
{
	int64_t offsetAdd = 0;
	void *pool;
	OFMutableZIPArchiveEntry *entry;
	OFString *fileName;
	bool seekable;
	OFStreamOffset CRC32Offset = 0, size64Offset = 0;
	OFData *extraField;
	uint16_t fileNameLength, extraFieldLength;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_mode != modeWrite && _mode != modeAppend)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	entry = [[entry_ mutableCopy] autorelease];

	if ([_pathToEntryMap objectForKey: entry.fileName] != nil)
		@throw [OFOpenItemFailedException
		    exceptionWithPath: entry.fileName
				 mode: @"w"
				errNo: EEXIST];

	if (entry.compressionMethod != OFZIPArchiveEntryCompressionMethodNone)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	fileName = entry.fileName;
	fileNameLength = fileName.UTF8StringLength;
	extraField = entry.extraField;
	extraFieldLength = extraField.count;

	if (UINT16_MAX - extraFieldLength < 20)
		@throw [OFOutOfRangeException exception];

	seekable = [_stream isKindOfClass: [OFSeekableStream class]];

	entry.versionMadeBy = (entry.versionMadeBy & 0xFF00) | 45;
	entry.minVersionNeeded = (entry.minVersionNeeded & 0xFF00) | 45;
	entry.compressedSize = 0;
	entry.uncompressedSize = 0;
	entry.CRC32 = 0;
	entry.generalPurposeBitFlag |= (seekable ? 0 : (1u << 3)) | (1u << 11);
	entry.of_localFileHeaderOffset = _offset;

	[_stream writeLittleEndianInt32: 0x04034B50];
	[_stream writeLittleEndianInt16: entry.minVersionNeeded];
	[_stream writeLittleEndianInt16: entry.generalPurposeBitFlag];
	[_stream writeLittleEndianInt16: entry.compressionMethod];
	[_stream writeLittleEndianInt16: entry.of_lastModifiedFileTime];
	[_stream writeLittleEndianInt16: entry.of_lastModifiedFileDate];
	/* Written later or data descriptor used instead */
	if (seekable)
		CRC32Offset = [_stream seekToOffset: 0 whence: OFSeekCurrent];
	[_stream writeLittleEndianInt32: 0];
	/* We use ZIP64 */
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];
	[_stream writeLittleEndianInt32: 0xFFFFFFFF];
	[_stream writeLittleEndianInt16: fileNameLength];
	[_stream writeLittleEndianInt16: extraFieldLength + 20];
	offsetAdd += 4 + (5 * 2) + (3 * 4) + (2 * 2);

	[_stream writeString: fileName];
	offsetAdd += fileNameLength;

	[_stream writeLittleEndianInt16: OFZIPArchiveEntryExtraFieldTagZIP64];
	[_stream writeLittleEndianInt16: 16];
	/* Written later or data descriptor used instead */
	if (seekable)
		size64Offset = [_stream seekToOffset: 0 whence: OFSeekCurrent];
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
	    of_initWithArchive: self
			stream: _stream
			 entry: entry
		   CRC32Offset: CRC32Offset
		  size64Offset: size64Offset];

	objc_autoreleasePoolPop(pool);

	return [_lastReturnedStream autorelease];
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
		@throw [OFNotOpenException exceptionWithObject: self];

	@try {
		[_lastReturnedStream close];
	} @catch (OFNotOpenException *e) {
		/* Might have already been closed by the user - that's fine. */
	}
	_lastReturnedStream = nil;

	if (_mode == modeWrite || _mode == modeAppend)
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
		OFStringEncoding encoding;
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
		encoding = (_generalPurposeBitFlag & (1u << 11)
		    ? OFStringEncodingUTF8 : OFStringEncodingCodepage437);

		_fileName = [[stream readStringWithLength: fileNameLength
						 encoding: encoding] copy];
		if (extraFieldLength > 0)
			extraField = [[[stream readDataWithCount:
			    extraFieldLength] mutableCopy] autorelease];

		ZIP64Index = OFZIPArchiveEntryExtraFieldFind(extraField,
		    OFZIPArchiveEntryExtraFieldTagZIP64, &ZIP64Size);

		if (ZIP64Index != OFNotFound) {
			const uint8_t *ZIP64 =
			    [extraField itemAtIndex: ZIP64Index];
			OFRange range =
			    OFMakeRange(ZIP64Index - 4, ZIP64Size + 4);

			if (_uncompressedSize == 0xFFFFFFFF)
				_uncompressedSize = OFZIPArchiveReadField64(
				    &ZIP64, &ZIP64Size);
			if (_compressedSize == 0xFFFFFFFF)
				_compressedSize = OFZIPArchiveReadField64(
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

	if (!(_generalPurposeBitFlag & (1u << 3)))
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
- (instancetype)of_initWithArchive: (OFZIPArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFZIPArchiveEntry *)entry
{
	self = [super init];

	@try {
		_archive = [archive retain];
		_compressionMethod = entry.compressionMethod;

		switch (_compressionMethod) {
		case OFZIPArchiveEntryCompressionMethodNone:
			_decompressedStream = [_archive->_stream retain];
			break;
		case OFZIPArchiveEntryCompressionMethodDeflate:
			_decompressedStream = [[OFInflateStream alloc]
			    initWithStream: _archive->_stream];
			break;
		case OFZIPArchiveEntryCompressionMethodDeflate64:
			_decompressedStream = [[OFInflate64Stream alloc]
			    initWithStream: _archive->_stream];
			break;
		default:
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: nil];
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
	if (_decompressedStream != nil)
		[self close];

	[_entry release];

	if (_archive->_lastReturnedStream == self)
		_archive->_lastReturnedStream = nil;

	[_archive release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_decompressedStream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	size_t ret;

	if (_decompressedStream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if ([_archive->_stream isAtEndOfStream] &&
	    ![_decompressedStream hasDataInReadBuffer]) {
		OFStream *oldStream = _archive->_stream, *oldDecompressedStream;
		OFSeekableStream *stream;

		if (_archive->_diskNumber >= _archive->_lastDiskNumber)
			@throw [OFTruncatedDataException exception];

		stream = [_archive->_delegate
			      archive: _archive
		    wantsPartNumbered: _archive->_diskNumber + 1
		       lastPartNumber: _archive->_lastDiskNumber];

		if (stream == nil)
			@throw [OFInvalidFormatException exception];

		_archive->_diskNumber++;
		_archive->_stream = [stream retain];
		[oldStream release];

		switch (_compressionMethod) {
		case OFZIPArchiveEntryCompressionMethodNone:
			oldDecompressedStream = _decompressedStream;
			_decompressedStream = [_archive->_stream retain];
			[oldDecompressedStream release];
			break;
		case OFZIPArchiveEntryCompressionMethodDeflate:
		case OFZIPArchiveEntryCompressionMethodDeflate64:
			[_decompressedStream
			    setUnderlyingStream: _archive->_stream];
			break;
		default:
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: nil];
		}
	}

#if SIZE_MAX >= UINT64_MAX
	if (length > UINT64_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if (length > _toRead)
		length = (size_t)_toRead;

	ret = [_decompressedStream readIntoBuffer: buffer length: length];

	_toRead -= ret;
	_CRC32 = OFCRC32(_CRC32, buffer, ret);

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

- (bool)lowlevelHasDataInReadBuffer
{
	return _decompressedStream.hasDataInReadBuffer;
}

- (int)fileDescriptorForReading
{
	return ((id <OFReadyForReadingObserving>)_decompressedStream)
	    .fileDescriptorForReading;
}

- (void)close
{
	if (_decompressedStream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	[_decompressedStream release];
	_decompressedStream = nil;

	[super close];
}
@end

@implementation OFZIPArchiveFileWriteStream
- (instancetype)of_initWithArchive: (OFZIPArchive *)archive
			    stream: (OFStream *)stream
			     entry: (OFMutableZIPArchiveEntry *)entry
		       CRC32Offset: (OFStreamOffset)CRC32Offset
		      size64Offset: (OFStreamOffset)size64Offset
{
	self = [super init];

	_archive = [archive retain];
	_stream = [stream retain];
	_entry = [entry retain];
	_CRC32 = ~0;
	_CRC32Offset = CRC32Offset;
	_size64Offset = size64Offset;

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
#if SIZE_MAX >= INT64_MAX
	if (length > INT64_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	if (ULLONG_MAX - _bytesWritten < length)
		@throw [OFOutOfRangeException exception];

	@try {
		[_stream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		OFEnsure(e.bytesWritten <= length);

		_bytesWritten += (unsigned long long)e.bytesWritten;
		_CRC32 = OFCRC32(_CRC32, buffer, e.bytesWritten);

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	_bytesWritten += (unsigned long long)length;
	_CRC32 = OFCRC32(_CRC32, buffer, length);

	return length;
}

- (void)close
{
	bool seekable;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_bytesWritten > UINT64_MAX)
		@throw [OFOutOfRangeException exception];

	seekable = [_stream isKindOfClass: [OFSeekableStream class]];

	if (seekable) {
		OFStreamOffset offset = [_stream seekToOffset: 0
						       whence: OFSeekCurrent];

		[_stream seekToOffset: _CRC32Offset whence: OFSeekSet];
		[_stream writeLittleEndianInt32: ~_CRC32];
		[_stream seekToOffset: _size64Offset whence: OFSeekSet];
		[_stream writeLittleEndianInt64: (uint64_t)_bytesWritten];
		[_stream writeLittleEndianInt64: (uint64_t)_bytesWritten];

		[_stream seekToOffset: offset whence: OFSeekSet];
	} else {
		[_stream writeLittleEndianInt32: 0x08074B50];
		[_stream writeLittleEndianInt32: ~_CRC32];
		[_stream writeLittleEndianInt64: (uint64_t)_bytesWritten];
		[_stream writeLittleEndianInt64: (uint64_t)_bytesWritten];
	}

	[_stream release];
	_stream = nil;

	_entry.CRC32 = ~_CRC32;
	_entry.compressedSize = _bytesWritten;
	_entry.uncompressedSize = _bytesWritten;
	[_entry makeImmutable];

	if (!seekable)
		_bytesWritten += (2 * 4 + 2 * 8);

	[_archive->_entries addObject: _entry];
	[_archive->_pathToEntryMap setObject: _entry forKey: _entry.fileName];

	if (ULLONG_MAX - _archive->_offset < _bytesWritten)
		@throw [OFOutOfRangeException exception];

	_archive->_offset += _bytesWritten;

	[super close];
}
@end
