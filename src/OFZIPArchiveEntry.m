/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
#import "OFString.h"
#import "OFDataArray.h"
#import "OFFile.h"
#import "OFDate.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

extern uint32_t of_zip_archive_read_field32(uint8_t**, uint16_t*);
extern uint64_t of_zip_archive_read_field64(uint8_t**, uint16_t*);

OFString*
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
	case OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ACORN_RISC:
		attrCompat = "Acorn Risc";
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
@synthesize fileName = _fileName, fileComment = _fileComment;
@synthesize versionMadeBy = _versionMadeBy;
@synthesize minVersionNeeded = _minVersionNeeded;
@synthesize compressionMethod = _compressionMethod;
@synthesize compressedSize = _compressedSize;
@synthesize uncompressedSize = _uncompressedSize;
@synthesize CRC32 = _CRC32;
@synthesize versionSpecificAttributes = _versionSpecificAttributes;
@synthesize OF_generalPurposeBitFlag = _generalPurposeBitFlag;
@synthesize OF_lastModifiedFileTime = _lastModifiedFileTime;
@synthesize OF_lastModifiedFileDate = _lastModifiedFileDate;
@synthesize OF_localFileHeaderOffset = _localFileHeaderOffset;

- (instancetype)OF_initWithStream: (OFStream*)stream
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		uint16_t fileNameLength, extraFieldLength, fileCommentLength;
		of_string_encoding_t encoding;
		uint8_t *ZIP64 = NULL;
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
		_extraField = [[stream
		    readDataArrayWithCount: extraFieldLength] retain];
		_fileComment = [[stream readStringWithLength: fileCommentLength
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

- (OFDate*)modificationDate
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
@end
