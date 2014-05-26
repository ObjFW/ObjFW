/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFString.h"
#import "OFDataArray.h"
#import "OFFile.h"
#import "OFDate.h"

#import "autorelease.h"
#import "macros.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

extern uint32_t of_zip_archive_read_field32(uint8_t**, uint16_t*);
extern uint64_t of_zip_archive_read_field64(uint8_t**, uint16_t*);

void
of_zip_archive_entry_extra_field_find(OFDataArray *extraField, uint16_t tag,
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

@implementation OFZIPArchiveEntry
- (instancetype)OF_initWithFile: (OFFile*)file
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		uint16_t fileNameLength, extraFieldLength, fileCommentLength;
		of_string_encoding_t encoding;
		uint8_t *ZIP64 = NULL;
		uint16_t ZIP64Size;

		if ([file readLittleEndianInt32] != 0x02014B50)
			@throw [OFInvalidFormatException exception];

		_versionMadeBy = [file readLittleEndianInt16];
		_minVersionNeeded = [file readLittleEndianInt16];
		_generalPurposeBitFlag = [file readLittleEndianInt16];
		_compressionMethod = [file readLittleEndianInt16];
		_lastModifiedFileTime = [file readLittleEndianInt16];
		_lastModifiedFileDate = [file readLittleEndianInt16];
		_CRC32 = [file readLittleEndianInt32];
		_compressedSize = [file readLittleEndianInt32];
		_uncompressedSize = [file readLittleEndianInt32];
		fileNameLength = [file readLittleEndianInt16];
		extraFieldLength = [file readLittleEndianInt16];
		fileCommentLength = [file readLittleEndianInt16];
		_startDiskNumber = [file readLittleEndianInt16];
		_internalAttributes = [file readLittleEndianInt16];
		_versionSpecificAttributes = [file readLittleEndianInt32];
		_localFileHeaderOffset = [file readLittleEndianInt32];

		encoding = (_generalPurposeBitFlag & (1 << 11)
		    ? OF_STRING_ENCODING_UTF_8
		    : OF_STRING_ENCODING_CODEPAGE_437);

		_fileName = [[file readStringWithLength: fileNameLength
					       encoding: encoding] copy];
		_extraField = [[file
		    readDataArrayWithCount: extraFieldLength] retain];
		_fileComment = [[file readStringWithLength: fileCommentLength
						  encoding: encoding] copy];

		of_zip_archive_entry_extra_field_find(_extraField,
		    OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64, &ZIP64, &ZIP64Size);

		if (ZIP64 != NULL) {
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

			if (ZIP64Size > 0)
				@throw [OFInvalidFormatException exception];
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

- (OFString*)fileName
{
	OF_GETTER(_fileName, true)
}

- (OFString*)fileComment
{
	OF_GETTER(_fileComment, true)
}

- (uint16_t)versionMadeBy
{
	return _versionMadeBy;
}

- (uint16_t)minVersionNeeded
{
	return _minVersionNeeded;
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

- (OFDate*)modificationDate
{
	void *pool = objc_autoreleasePoolPush();
	uint_fast16_t year = ((_lastModifiedFileDate & 0xFE00) >> 9) + 1980;
	uint_fast8_t month = (_lastModifiedFileDate & 0x1E0) >> 5;
	uint_fast8_t day = (_lastModifiedFileDate & 0x1F);
	uint_fast8_t hour = (_lastModifiedFileTime & 0xF800) >> 11;
	uint_fast8_t minute = (_lastModifiedFileTime & 0x7E0) >> 5;
	uint_fast8_t second = (_lastModifiedFileTime & 0x1F) << 1;
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

- (uint32_t)CRC32
{
	return _CRC32;
}

- (uint32_t)versionSpecificAttributes
{
	return _versionSpecificAttributes;
}

- (OFDataArray*)extraField
{
	return [[_extraField copy] autorelease];
}

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *modificationDate = [self modificationDate];
	OFString *ret;

	ret = [[OFString alloc] initWithFormat: @"<%@: %p\n"
	    @"\tFile name = %@\n"
	    @"\tFile comment = %@\n"
	    @"\tGeneral purpose bit flag = %u\n"
	    @"\tCompression method = %u\n"
	    @"\tCompressed size = %ju\n"
	    @"\tUncompressed size = %ju\n"
	    @"\tModification date = %@\n"
	    @"\tCRC32 = %" @PRIu32 @"\n"
	    @"\tExtra field = %@\n"
	    @"}",
	    [self class], self, _fileName, _fileComment, _generalPurposeBitFlag,
	    _compressionMethod, (intmax_t)_compressedSize,
	    (intmax_t)_uncompressedSize, modificationDate, _CRC32, _extraField];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (uint16_t)OF_generalPurposeBitFlag
{
	return _generalPurposeBitFlag;
}

- (uint16_t)OF_lastModifiedFileTime
{
	return _lastModifiedFileTime;
}

- (uint16_t)OF_lastModifiedFileDate
{
	return _lastModifiedFileDate;
}

- (uint64_t)OF_localFileHeaderOffset
{
	return _localFileHeaderOffset;
}
@end
