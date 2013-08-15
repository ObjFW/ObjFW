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

#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFString.h"
#import "OFDataArray.h"
#import "OFFile.h"
#import "OFDate.h"

#import "autorelease.h"
#import "macros.h"

#import "OFInvalidFormatException.h"

@implementation OFZIPArchiveEntry
- (instancetype)OF_initWithFile: (OFFile*)file
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		uint16_t fileNameLength, extraFieldLength, fileCommentLength;
		of_string_encoding_t encoding;

		if ([file readLittleEndianInt32] != 0x02014B50)
			@throw [OFInvalidFormatException exception];

		_madeWithVersion = [file readLittleEndianInt16];
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
		fileCommentLength = [file readLittleEndianInt16];
		_startDiskNumber = [file readLittleEndianInt16];
		_internalAttributes = [file readLittleEndianInt16];
		_externalAttributes = [file readLittleEndianInt32];
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

- (off_t)compressedSize
{
	return _compressedSize;
}

- (off_t)uncompressedSize
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

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *modificationDate = [self modificationDate];
	OFString *ret;

	ret = [[OFString alloc] initWithFormat: @"<%@: %p\n"
	    @"\tFile name = %@\n"
	    @"\tFile comment = %@\n"
	    @"\tCompressed size = %jd\n"
	    @"\tUncompressed size = %jd\n"
	    @"\tModification date = %@\n"
	    @"\tCRC32 = %" @PRIu32 @"\n"
	    @"}",
	    [self class], self, _fileName, _fileComment,
	    (intmax_t)_compressedSize, (intmax_t)_uncompressedSize,
	    modificationDate, _CRC32];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (uint16_t)OF_madeWithVersion
{
	return _madeWithVersion;
}

- (uint16_t)OF_minVersion
{
	return _minVersion;
}

- (uint16_t)OF_generalPurposeBitFlag
{
	return _generalPurposeBitFlag;
}

- (uint16_t)OF_compressionMethod
{
	return _compressionMethod;
}

- (uint16_t)OF_lastModifiedFileTime
{
	return _lastModifiedFileTime;
}

- (uint16_t)OF_lastModifiedFileDate
{
	return _lastModifiedFileDate;
}

- (OFDataArray*)OF_extraField
{
	OF_GETTER(_extraField, true)
}

- (uint16_t)OF_startDiskNumber
{
	return _startDiskNumber;
}

- (uint16_t)OF_internalAttributes
{
	return _internalAttributes;
}

- (uint32_t)OF_externalAttributes
{
	return _externalAttributes;
}

- (uint32_t)OF_localFileHeaderOffset
{
	return _localFileHeaderOffset;
}
@end
