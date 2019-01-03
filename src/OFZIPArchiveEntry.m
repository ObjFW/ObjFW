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

#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

extern uint32_t of_zip_archive_read_field32(const uint8_t **, uint16_t *);
extern uint64_t of_zip_archive_read_field64(const uint8_t **, uint16_t *);

OFString *
of_zip_archive_entry_version_to_string(uint16_t version)
{
	const char *attrCompat = NULL;

	switch (version >> 8) {
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MSDOS:
		attrCompat = "MS-DOS or OS/2";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_AMIGA:
		attrCompat = "Amiga";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OPENVMS:
		attrCompat = "OpenVMS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX:
		attrCompat = "UNIX";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VM_CMS:
		attrCompat = "VM/CMS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ATARI_ST:
		attrCompat = "Atari ST";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS2_HPFS:
		attrCompat = "OS/2 HPFS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MACINTOSH:
		attrCompat = "Macintosh";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_Z_SYSTEM:
		attrCompat = "Z-System";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_CP_M:
		attrCompat = "CP/M";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_WINDOWS_NTFS:
		attrCompat = "Windows NTFS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MVS:
		attrCompat = "MVS (OS/390 - Z/OS)";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VSE:
		attrCompat = "VSE";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ACORN_RISC_OS:
		attrCompat = "Acorn RISC OS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VFAT:
		attrCompat = "VFAT";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ALTERNATE_MVS:
		attrCompat = "Alternate MVS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_BEOS:
		attrCompat = "BeOS";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_TANDEM:
		attrCompat = "Tandem";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_400:
		attrCompat = "OS/400";
		break;
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_X:
		attrCompat = "OS X (Darwin)";
		break;
	}

	if (attrCompat != NULL)
		return [OFString stringWithFormat:
		    @"%u.%u, %s",
		    (version & 0xFF) / 10, (version & 0xFF) % 10, attrCompat];
	else
		return [OFString stringWithFormat:
		    @"%u.%u, unknown %02X",
		    (version % 0xFF) / 10, (version & 0xFF) % 10, version >> 8];
}

OFString *
of_zip_archive_entry_compression_method_to_string(uint16_t compressionMethod)
{
	switch (compressionMethod) {
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE:
		return @"none";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_SHRINK:
		return @"Shrink";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_REDUCE_FACTOR_1:
		return @"Reduce (factor 1)";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_REDUCE_FACTOR_2:
		return @"Reduce (factor 2)";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_REDUCE_FACTOR_3:
		return @"Reduce (factor 3)";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_REDUCE_FACTOR_4:
		return @"Reduce (factor 4)";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_IMPLODE:
		return @"Implode";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE:
		return @"Deflate";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64:
		return @"Deflate64";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_BZIP2:
		return @"BZip2";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_LZMA:
		return @"LZMA";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_WAVPACK:
		return @"WavPack";
	case OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_PPMD:
		return @"PPMd";
	default:
		return @"unknown";
	}
}

size_t
of_zip_archive_entry_extra_field_find(OFData *extraField, uint16_t tag,
    uint16_t *size)
{
	const uint8_t *bytes = [extraField items];
	size_t count = [extraField count];

	for (size_t i = 0; i < count;) {
		uint16_t currentTag, currentSize;

		if (i + 3 >= count)
			@throw [OFInvalidFormatException exception];

		currentTag = (bytes[i + 1] << 8) | bytes[i];
		currentSize = (bytes[i + 3] << 8) | bytes[i + 2];

		if (i + 3 + currentSize >= count)
			@throw [OFInvalidFormatException exception];

		if (currentTag == tag) {
			*size = currentSize;
			return i + 4;
		}

		i += 4 + currentSize;
	}

	*size = 0;
	return OF_NOT_FOUND;
}

@implementation OFZIPArchiveEntry
+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if ([fileName UTF8StringLength] > UINT16_MAX)
			@throw [OFOutOfRangeException exception];

		_fileName = [fileName copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithStream: (OFStream *)stream
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableData *extraField = nil;
		uint16_t fileNameLength, extraFieldLength, fileCommentLength;
		of_string_encoding_t encoding;
		size_t ZIP64Index;
		uint16_t ZIP64Size;

		if ([stream readLittleEndianInt32] != 0x02014B50)
			@throw [OFInvalidFormatException exception];

		_versionMadeBy = [stream readLittleEndianInt16];
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
		fileCommentLength = [stream readLittleEndianInt16];
		_startDiskNumber = [stream readLittleEndianInt16];
		_internalAttributes = [stream readLittleEndianInt16];
		_versionSpecificAttributes = [stream readLittleEndianInt32];
		_localFileHeaderOffset = [stream readLittleEndianInt32];

		encoding = (_generalPurposeBitFlag & (1 << 11)
		    ? OF_STRING_ENCODING_UTF_8
		    : OF_STRING_ENCODING_CODEPAGE_437);

		_fileName = [[stream readStringWithLength: fileNameLength
						 encoding: encoding] copy];
		if (extraFieldLength > 0)
			extraField = [[[stream readDataWithCount:
			    extraFieldLength] mutableCopy] autorelease];
		if (fileCommentLength > 0)
			_fileComment = [[stream
			    readStringWithLength: fileCommentLength
					encoding: encoding] copy];

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
			if (_localFileHeaderOffset == 0xFFFFFFFF)
				_localFileHeaderOffset =
				    of_zip_archive_read_field64(&ZIP64,
				    &ZIP64Size);
			if (_startDiskNumber == 0xFFFF)
				_startDiskNumber = of_zip_archive_read_field32(
				    &ZIP64, &ZIP64Size);

			if (ZIP64Size > 0 || _localFileHeaderOffset < 0)
				@throw [OFInvalidFormatException exception];

			[extraField removeItemsInRange: range];
		}

		if ([extraField count] > 0) {
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
	[_fileComment release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFZIPArchiveEntry *copy =
	    [[OFMutableZIPArchiveEntry alloc] initWithFileName: _fileName];

	@try {
		copy->_versionMadeBy = _versionMadeBy;
		copy->_minVersionNeeded = _minVersionNeeded;
		copy->_generalPurposeBitFlag = _generalPurposeBitFlag;
		copy->_compressionMethod = _compressionMethod;
		copy->_lastModifiedFileTime = _lastModifiedFileTime;
		copy->_lastModifiedFileDate = _lastModifiedFileDate;
		copy->_CRC32 = _CRC32;
		copy->_compressedSize = _compressedSize;
		copy->_uncompressedSize = _uncompressedSize;
		copy->_extraField = [_extraField copy];
		copy->_fileComment = [_extraField copy];
		copy->_startDiskNumber = _startDiskNumber;
		copy->_internalAttributes = _internalAttributes;
		copy->_versionSpecificAttributes = _versionSpecificAttributes;
		copy->_localFileHeaderOffset = _localFileHeaderOffset;
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)fileName
{
	return _fileName;
}

- (OFString *)fileComment
{
	return _fileComment;
}

- (OFData *)extraField
{
	return _extraField;
}

- (uint16_t)versionMadeBy
{
	return _versionMadeBy;
}

- (uint16_t)minVersionNeeded
{
	return _minVersionNeeded;
}

- (OFDate *)modificationDate
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t year = ((_lastModifiedFileDate & 0xFE00) >> 9) + 1980;
	uint8_t month = (_lastModifiedFileDate & 0x1E0) >> 5;
	uint8_t day = (_lastModifiedFileDate & 0x1F);
	uint8_t hour = (_lastModifiedFileTime & 0xF800) >> 11;
	uint8_t minute = (_lastModifiedFileTime & 0x7E0) >> 5;
	uint8_t second = (_lastModifiedFileTime & 0x1F) << 1;
	OFDate *date;
	OFString *dateString;

	dateString = [OFString
	    stringWithFormat: @"%04u-%02u-%02u %02u:%02u:%02u",
			      year, month, day, hour, minute, second];

	date = [[OFDate alloc] initWithLocalDateString: dateString
						format: @"%Y-%m-%d %H:%M:%S"];

	objc_autoreleasePoolPop(pool);

	return [date autorelease];
}

- (uint16_t)compressionMethod
{
	return _compressionMethod;
}

- (uint64_t)compressedSize
{
	return _compressedSize;
}

- (uint64_t)uncompressedSize
{
	return _uncompressedSize;
}

- (uint32_t)CRC32
{
	return _CRC32;
}

- (uint32_t)versionSpecificAttributes
{
	return _versionSpecificAttributes;
}

- (uint16_t)generalPurposeBitFlag
{
	return _generalPurposeBitFlag;
}

- (uint16_t)of_lastModifiedFileTime
{
	return _lastModifiedFileTime;
}

- (uint16_t)of_lastModifiedFileDate
{
	return _lastModifiedFileDate;
}

- (int64_t)of_localFileHeaderOffset
{
	return _localFileHeaderOffset;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *compressionMethod =
	    of_zip_archive_entry_compression_method_to_string(
	    _compressionMethod);
	OFString *ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tFile comment = %@\n"
	    @"\tGeneral purpose bit flag = %u\n"
	    @"\tCompressed size = %" @PRIu64 "\n"
	    @"\tUncompressed size = %" @PRIu64 "\n"
	    @"\tCompression method = %@\n"
	    @"\tModification date = %@\n"
	    @"\tCRC32 = %08" @PRIX32 @"\n"
	    @"\tExtra field = %@\n"
	    @">",
	    [self class], _fileName, _fileComment, _generalPurposeBitFlag,
	    _compressedSize, _uncompressedSize, compressionMethod,
	    [self modificationDate], _CRC32, _extraField];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (uint64_t)of_writeToStream: (OFStream *)stream
{
	void *pool = objc_autoreleasePoolPush();
	uint64_t size = 0;

	if (UINT16_MAX - [_extraField count] < 32)
		@throw [OFOutOfRangeException exception];

	[stream writeLittleEndianInt32: 0x02014B50];
	[stream writeLittleEndianInt16: _versionMadeBy];
	[stream writeLittleEndianInt16: _minVersionNeeded];
	[stream writeLittleEndianInt16: _generalPurposeBitFlag];
	[stream writeLittleEndianInt16: _compressionMethod];
	[stream writeLittleEndianInt16: _lastModifiedFileTime];
	[stream writeLittleEndianInt16: _lastModifiedFileDate];
	[stream writeLittleEndianInt32: _CRC32];
	[stream writeLittleEndianInt32: 0xFFFFFFFF];
	[stream writeLittleEndianInt32: 0xFFFFFFFF];
	[stream writeLittleEndianInt16: (uint16_t)[_fileName UTF8StringLength]];
	[stream writeLittleEndianInt16: (uint16_t)[_extraField count] + 32];
	[stream writeLittleEndianInt16:
	    (uint16_t)[_fileComment UTF8StringLength]];
	[stream writeLittleEndianInt16: 0xFFFF];
	[stream writeLittleEndianInt16: _internalAttributes];
	[stream writeLittleEndianInt32: _versionSpecificAttributes];
	[stream writeLittleEndianInt32: 0xFFFFFFFF];
	size += (4 + (6 * 2) + (3 * 4) + (5 * 2) + (2 * 4));

	[stream writeString: _fileName];
	size += (uint64_t)[_fileName UTF8StringLength];

	[stream writeLittleEndianInt16: OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64];
	[stream writeLittleEndianInt16: 28];
	[stream writeLittleEndianInt64: _uncompressedSize];
	[stream writeLittleEndianInt64: _compressedSize];
	[stream writeLittleEndianInt64: _localFileHeaderOffset];
	[stream writeLittleEndianInt32: _startDiskNumber];
	size += (2 * 2) + (3 * 8) + 4;

	if (_extraField != nil)
		[stream writeData: _extraField];
	size += (uint64_t)[_extraField count];

	if (_fileComment != nil)
		[stream writeString: _fileComment];
	size += (uint64_t)[_fileComment UTF8StringLength];

	objc_autoreleasePoolPop(pool);

	return size;
}
@end
