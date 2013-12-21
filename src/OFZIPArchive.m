/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFDataArray.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFDeflateStream.h"
#import "OFDeflate64Stream.h"

#import "OFChecksumFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFUnsupportedVersionException.h"

#import "autorelease.h"
#import "macros.h"

#define CRC32_MAGIC 0xEDB88320

/*
 * FIXME: Current limitations:
 *  - Split archives are not supported.
 *  - Write support is missing.
 *  - The ZIP has to be a file on the local file system.
 *  - Encrypted files cannot be read.
 */

@interface OFZIPArchive (OF_PRIVATE_CATEGORY)
- (void)OF_readZIPInfo;
- (void)OF_readEntries;
@end

@interface OFZIPArchive_LocalFileHeader: OFObject
{
@public
	uint16_t _minVersion, _generalPurposeBitFlag, _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	uint64_t _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFDataArray *_extraField;
}

- initWithFile: (OFFile*)file;
- (bool)matchesEntry: (OFZIPArchiveEntry*)entry;
@end

@interface OFZIPArchive_FileStream: OFStream
{
	OFStream *_stream;
	OFFile *_file;
	OFZIPArchive_LocalFileHeader *_localFileHeader;
	bool _hasDataDescriptor;
	uint64_t _size;
	uint32_t _CRC32;
	bool _atEndOfStream;
}

- initWithArchiveFile: (OFString*)path
	       offset: (off_t)offset
      localFileHeader: (OFZIPArchive_LocalFileHeader*)localFileHeader;
@end

void
of_zip_archive_find_extra_field(OFDataArray *extraField, uint16_t tag,
    uint8_t **data, uint16_t *size)
{
	uint8_t *bytes;
	size_t i, count;

	bytes = [extraField items];
	count = [extraField count];

	for (i = 0; i < count;) {
		uint16_t currentTag, currentSize;

		if (i + 3 >= count)
			@throw [OFInvalidFormatException exception];

		currentTag = (bytes[i + 1] << 8) | bytes[i];
		currentSize = (bytes[i + 3] << 8) | bytes[i + 2];

		if (i + 3 + currentSize >= count)
			@throw [OFInvalidFormatException exception];

		if (currentTag == tag) {
			*data = bytes + i + 4;
			*size = currentSize;
			return;
		}

		i += 4 + currentSize;
	}

	*data = NULL;
	*size = 0;
}

uint32_t
of_zip_archive_read_field32(uint8_t **data, uint16_t *size)
{
	uint32_t field = 0;
	uint_fast8_t i;

	if (*size < 4)
		@throw [OFInvalidFormatException exception];

	for (i = 0; i < 4; i++)
		field |= (uint32_t)(*data)[i] << (i * 8);

	*data += 4;
	*size -= 4;

	return field;
}

uint64_t
of_zip_archive_read_field64(uint8_t **data, uint16_t *size)
{
	uint64_t field = 0;
	uint_fast8_t i;

	if (*size < 8)
		@throw [OFInvalidFormatException exception];

	for (i = 0; i < 8; i++)
		field |= (uint64_t)(*data)[i] << (i * 8);

	*data += 8;
	*size -= 8;

	return field;
}

static uint32_t
crc32(uint32_t crc, uint8_t *bytes, size_t length)
{
	size_t i;

	for (i = 0; i < length; i++) {
		uint_fast8_t j;

		crc ^= bytes[i];

		for (j = 0; j < 8; j++)
			crc = (crc >> 1) ^ (CRC32_MAGIC & (~(crc & 1) + 1));
	}

	return crc;
}

@implementation OFZIPArchive
+ (instancetype)archiveWithPath: (OFString*)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
{
	self = [super init];

	@try {
		_file = [[OFFile alloc] initWithPath: path
						mode: @"rb"];
		_path = [path copy];

		[self OF_readZIPInfo];
		[self OF_readEntries];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_file release];
	[_path release];
	[_archiveComment release];
	[_entries release];
	[_pathToEntryMap release];

	[super dealloc];
}

- (void)OF_readZIPInfo
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t commentLength;
	off_t offset = -22;
	bool valid = false;

	do {
		@try {
			[_file seekToOffset: offset
				     whence: SEEK_END];
		} @catch (OFSeekFailedException *e) {
			if ([e errNo] == EINVAL)
				@throw [OFInvalidFormatException exception];

			@throw e;
		}

		if ([_file readLittleEndianInt32] == 0x06054B50) {
			valid = true;
			break;
		}
	} while (--offset >= -65557);

	if (!valid)
		@throw [OFInvalidFormatException exception];

	_diskNumber = [_file readLittleEndianInt16],
	_centralDirectoryDisk = [_file readLittleEndianInt16];
	_centralDirectoryEntriesInDisk = [_file readLittleEndianInt16];
	_centralDirectoryEntries = [_file readLittleEndianInt16];
	_centralDirectorySize = [_file readLittleEndianInt32];
	_centralDirectoryOffset = [_file readLittleEndianInt32];

	commentLength = [_file readLittleEndianInt16];
	_archiveComment = [[_file
	    readStringWithLength: commentLength
			encoding: OF_STRING_ENCODING_CODEPAGE_437] copy];

	if (_diskNumber == 0xFFFF ||
	    _centralDirectoryDisk == 0xFFFF ||
	    _centralDirectoryEntriesInDisk == 0xFFFF ||
	    _centralDirectoryEntries == 0xFFFF ||
	    _centralDirectorySize == 0xFFFFFFFF ||
	    _centralDirectoryOffset == 0xFFFFFFFF) {
		uint64_t offset64, size;

		[_file seekToOffset: offset - 20
			     whence: SEEK_END];

		if ([_file readLittleEndianInt32] != 0x07064B50) {
			objc_autoreleasePoolPop(pool);
			return;
		}

		/*
		 * FIXME: Handle number of the disk containing ZIP64 end of
		 * central directory record.
		 */
		[_file readLittleEndianInt32];
		offset64 = [_file readLittleEndianInt64];

		if ((off_t)offset64 != offset64)
			@throw [OFOutOfRangeException exception];

		[_file seekToOffset: (off_t)offset64
			     whence: SEEK_SET];

		if ([_file readLittleEndianInt32] != 0x06064B50)
			@throw [OFInvalidFormatException exception];

		size = [_file readLittleEndianInt64];
		if (size < 44)
			@throw [OFInvalidFormatException exception];

		/* version made by */
		[_file readLittleEndianInt16];
		/* version needed to extract */
		[_file readLittleEndianInt16];

		_diskNumber = [_file readLittleEndianInt32];
		_centralDirectoryDisk = [_file readLittleEndianInt32];
		_centralDirectoryEntriesInDisk = [_file readLittleEndianInt64];
		_centralDirectoryEntries = [_file readLittleEndianInt64];
		_centralDirectorySize = [_file readLittleEndianInt64];
		_centralDirectoryOffset = [_file readLittleEndianInt64];

		if ((off_t)_centralDirectoryOffset != _centralDirectoryOffset)
			@throw [OFOutOfRangeException exception];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)OF_readEntries
{
	void *pool = objc_autoreleasePoolPush();
	size_t i;

	if ((off_t)_centralDirectoryOffset != _centralDirectoryOffset)
		@throw [OFOutOfRangeException exception];

	[_file seekToOffset: (off_t)_centralDirectoryOffset
		     whence: SEEK_SET];

	_entries = [[OFMutableArray alloc] init];
	_pathToEntryMap = [[OFMutableDictionary alloc] init];

	for (i = 0; i < _centralDirectoryEntries; i++) {
		OFZIPArchiveEntry *entry = [[[OFZIPArchiveEntry alloc]
		    OF_initWithFile: _file] autorelease];

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

- (OFArray*)entries
{
	OF_GETTER(_entries, true)
}

- (OFString*)archiveComment
{
	OF_GETTER(_archiveComment, true)
}

- (OFStream*)streamForReadingFile: (OFString*)path
{
	OFStream *ret;
	void *pool = objc_autoreleasePoolPush();
	OFZIPArchiveEntry *entry = [_pathToEntryMap objectForKey: path];
	OFZIPArchive_LocalFileHeader *localFileHeader;
	uint64_t offset;

	if (entry == nil) {
		errno = ENOENT;
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"rb"];
	}

	offset = [entry OF_localFileHeaderOffset];
	if ((off_t)offset != offset)
		@throw [OFOutOfRangeException exception];

	[_file seekToOffset: (off_t)offset
		     whence: SEEK_SET];
	localFileHeader = [[[OFZIPArchive_LocalFileHeader alloc]
	    initWithFile: _file] autorelease];

	if (![localFileHeader matchesEntry: entry])
		@throw [OFInvalidFormatException exception];

	if ((localFileHeader->_minVersion & 0xFF) > 45) {
		OFString *version = [OFString stringWithFormat: @"%u.%u",
		    (localFileHeader->_minVersion & 0xFF) / 10,
		    (localFileHeader->_minVersion & 0xFF) % 10];

		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	ret = [[OFZIPArchive_FileStream alloc]
	    initWithArchiveFile: _path
			 offset: [_file seekToOffset: 0
					      whence: SEEK_CUR]
	        localFileHeader: localFileHeader];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end

@implementation OFZIPArchive_LocalFileHeader
- initWithFile: (OFFile*)file
{
	self = [super init];

	@try {
		uint16_t fileNameLength, extraFieldLength;
		of_string_encoding_t encoding;
		uint8_t *ZIP64;
		uint16_t ZIP64Size;

		if ([file readLittleEndianInt32] != 0x04034B50)
			@throw [OFInvalidFormatException exception];

		_minVersion = [file readLittleEndianInt16];
		_generalPurposeBitFlag = [file readLittleEndianInt16];
		_compressionMethod = [file readLittleEndianInt16];
		_lastModifiedFileTime = [file readLittleEndianInt16];
		_lastModifiedFileDate = [file readLittleEndianInt16];
		_CRC32 = [file readLittleEndianInt32];
		_compressedSize = [file readLittleEndianInt32];
		_uncompressedSize = [file readLittleEndianInt32];
		fileNameLength = [file readLittleEndianInt16];
		extraFieldLength = [file readLittleEndianInt16];
		encoding = (_generalPurposeBitFlag & (1 << 11)
		    ? OF_STRING_ENCODING_UTF_8
		    : OF_STRING_ENCODING_CODEPAGE_437);

		_fileName = [[file readStringWithLength: fileNameLength
					       encoding: encoding] copy];
		_extraField = [[file
		    readDataArrayWithCount: extraFieldLength] retain];

		of_zip_archive_find_extra_field(_extraField, 0x0001,
		    &ZIP64, &ZIP64Size);

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

- (bool)matchesEntry: (OFZIPArchiveEntry*)entry
{
	if (_minVersion != [entry OF_minVersion] ||
	    _generalPurposeBitFlag != [entry OF_generalPurposeBitFlag] ||
	    _compressionMethod != [entry OF_compressionMethod] ||
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
- initWithArchiveFile: (OFString*)path
	       offset: (off_t)offset
      localFileHeader: (OFZIPArchive_LocalFileHeader*)localFileHeader
{
	self = [super init];

	@try {
		_file = [[OFFile alloc] initWithPath: path
						mode: @"rb"];
		[_file seekToOffset: offset
			     whence: SEEK_SET];

		switch (localFileHeader->_compressionMethod) {
		case 0: /* No compression */
			_stream = [_file retain];
			break;
		case 8: /* Deflate */
			_stream = [[OFDeflateStream alloc]
			    initWithStream: _file];
			break;
		case 9: /* Deflate64 */
			_stream = [[OFDeflate64Stream alloc]
			    initWithStream: _file];
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
	[_file release];
	[_localFileHeader release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	size_t min, ret;

	if (_atEndOfStream)
		@throw [OFReadFailedException exceptionWithStream: self
						  requestedLength: length];

	if (_hasDataDescriptor) {
		if ([_stream isAtEndOfStream]) {
			uint32_t CRC32;

			_atEndOfStream = true;

			CRC32 = [_file readLittleEndianInt32];
			if (CRC32 == 0x08074B50)
				CRC32 = [_file readLittleEndianInt32];

			if (~_CRC32 != CRC32)
				@throw [OFChecksumFailedException exception];

			/*
			 * FIXME: Check (un)compressed length!
			 * (Note: Both are 64 bit if the entry uses ZIP64!)
			 */

			return 0;
		}

		ret = [_stream readIntoBuffer: buffer
				       length: length];
	} else {
		if (_size == 0) {
			_atEndOfStream = true;

			if (~_CRC32 != _localFileHeader->_CRC32)
				@throw [OFChecksumFailedException exception];

			return 0;
		}

		min = (length < _size ? length : (size_t)_size);
		ret = [_stream readIntoBuffer: buffer
				       length: min];
		_size -= ret;
	}

	_CRC32 = crc32(_CRC32, buffer, ret);

	return ret;
}
@end
