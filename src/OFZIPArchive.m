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

#include <stdio.h>

#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFDictionary.h"
#import "OFFile.h"

#import "OFChecksumFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFReadFailedException.h"
#import "OFUnsupportedVersionException.h"

#import "autorelease.h"
#import "macros.h"

#define CRC32_MAGIC 0xEDB88320

/*
 * FIXME: Current limitations:
 *  - Compressed files cannot be read.
 *  - Encrypted files cannot be read.
 *  - Split archives are not supported.
 *  - Write support is missing.
 *  - The ZIP has to be a file on the local file system.
 *  - No support for ZIP64.
 *  - No support for data descriptors (useless without compression anyway).
 */

@interface OFZIPArchive_LocalFileHeader: OFObject
{
@public
	uint16_t _minVersion, _generalPurposeBitFlag, _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32, _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFDataArray *_extraField;
}

- initWithFile: (OFFile*)file;
- (bool)matchesEntry: (OFZIPArchiveEntry*)entry;
@end

@interface OFZIPArchive_FileStream: OFStream
{
	OFFile *_file;
	size_t _size;
	uint32_t _expectedCRC32, _CRC32;
	bool _atEndOfStream;
}

- initWithArchiveFile: (OFString*)path
	       offset: (off_t)offset
		 size: (size_t)size
		CRC32: (uint32_t)CRC32;
@end

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

	[super dealloc];
}

- (void)OF_readZIPInfo
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t commentLength;

	[_file seekToOffset: -22
		     whence: SEEK_END];

	if ([_file readLittleEndianInt32] != 0x06054B50)
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

	objc_autoreleasePoolPop(pool);
}

- (void)OF_readEntries
{
	void *pool = objc_autoreleasePoolPush();
	size_t i;

	[_file seekToOffset: _centralDirectoryOffset
		     whence: SEEK_SET];

	_entries = [[OFMutableDictionary alloc] init];

	for (i = 0; i < _centralDirectoryEntries; i++) {
		OFZIPArchiveEntry *entry = [[[OFZIPArchiveEntry alloc]
		    OF_initWithFile: _file] autorelease];

		if ([_entries objectForKey: [entry fileName]] != nil)
			@throw [OFInvalidFormatException exception];

		[_entries setObject: entry
			     forKey: [entry fileName]];
	}

	[_entries makeImmutable];

	objc_autoreleasePoolPop(pool);
}

- (OFDictionary*)entries
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
	OFZIPArchiveEntry *entry = [_entries objectForKey: path];
	OFZIPArchive_LocalFileHeader *localFileHeader;

	if (entry == nil) {
		errno = ENOENT;
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"rb"];
	}

	[_file seekToOffset: [entry OF_localFileHeaderOffset]
		     whence: SEEK_SET];
	localFileHeader = [[[OFZIPArchive_LocalFileHeader alloc]
	    initWithFile: _file] autorelease];

	if (![localFileHeader matchesEntry: entry])
		@throw [OFInvalidFormatException exception];

	if (localFileHeader->_minVersion > 10) {
		OFString *version = [OFString stringWithFormat: @"%u.%u",
		    localFileHeader->_minVersion / 10,
		    localFileHeader->_minVersion % 10];

		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: version];
	}

	if (localFileHeader->_compressionMethod != 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	ret = [[OFZIPArchive_FileStream alloc]
	    initWithArchiveFile: _path
			 offset: [_file seekToOffset: 0
					      whence: SEEK_CUR]
			   size: localFileHeader->_uncompressedSize
			  CRC32: localFileHeader->_CRC32];

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
	    _lastModifiedFileDate != [entry OF_lastModifiedFileDate] ||
	    _CRC32 != [entry CRC32] ||
	    _compressedSize != [entry compressedSize] ||
	    _uncompressedSize != [entry uncompressedSize] ||
	    ![_fileName isEqual: [entry fileName]])
		return false;

	return true;
}

@end

@implementation OFZIPArchive_FileStream
- initWithArchiveFile: (OFString*)path
	       offset: (off_t)offset
		 size: (size_t)size
		CRC32: (uint32_t)CRC32
{
	self = [super init];

	@try {
		_file = [[OFFile alloc] initWithPath: path
						mode: @"rb"];
		[_file seekToOffset: offset
			     whence: SEEK_SET];

		_size = size;
		_CRC32 = ~0;
		_expectedCRC32 = CRC32;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_file release];

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

	if (_size == 0) {
		_atEndOfStream = true;

		if (~_CRC32 != _expectedCRC32)
			@throw [OFChecksumFailedException exception];

		return 0;
	}

	if (length < _size)
		min = length;
	else
		min = _size;

	ret = [_file readIntoBuffer: buffer
			     length: min];
	_size -= ret;
	_CRC32 = crc32(_CRC32, buffer, ret);

	return ret;
}
@end
