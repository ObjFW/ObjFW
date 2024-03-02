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

#include "config.h"

#import "OFZooArchiveEntry.h"
#import "OFZooArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFZooArchiveEntry
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	self = [super init];

	@try {
		_headerType = 2;
		_minVersionNeeded = 0x100;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithStream: (OF_KINDOF(OFStream *))stream
			 encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char fileNameBuffer[13];
		uint32_t commentOffset;
		uint16_t commentLength;

		if ([stream readLittleEndianInt32] != 0xFDC4A7DC)
			@throw [OFInvalidFormatException exception];

		if ((_headerType = [stream readInt8]) > 2)
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: [OFString
			    stringWithFormat: @"%u", _headerType]];

		_compressionMethod = [stream readInt8];
		_nextHeaderOffset = [stream readLittleEndianInt32];

		if (_nextHeaderOffset == 0) {
			[self release];
			return nil;
		}

		_dataOffset = [stream readLittleEndianInt32];
		_lastModifiedFileDate = [stream readLittleEndianInt16];
		_lastModifiedFileTime = [stream readLittleEndianInt16];
		_CRC16 = [stream readLittleEndianInt16];
		_uncompressedSize = [stream readLittleEndianInt32];
		_compressedSize = [stream readLittleEndianInt32];
		_minVersionNeeded = [stream readBigEndianInt16];
		_deleted = [stream readInt8];
		/*
		 * File structure, whatever that is meant to be. Seems to
		 * always be 0.
		 */
		[stream readInt8];
		commentOffset = [stream readLittleEndianInt32];
		commentLength = [stream readLittleEndianInt16];

		[stream readIntoBuffer: fileNameBuffer exactLength: 13];
		if (fileNameBuffer[12] != '\0')
			fileNameBuffer[12] = '\0';

		if (_headerType >= 2) {
			uint16_t extraLength = [stream readLittleEndianInt16];
			uint8_t fileNameLength, directoryNameLength;

			if (extraLength < 10)
				@throw [OFInvalidFormatException exception];

			_timeZone = [stream readInt8];
			/* CRC16 of the header */
			[stream readLittleEndianInt16];

			fileNameLength = [stream readInt8];
			directoryNameLength = [stream readInt8];
			extraLength -= 2;

			if (fileNameLength > 0) {
				if (extraLength < fileNameLength)
					@throw [OFInvalidFormatException
					    exception];

				_fileName = [[stream
				    readStringWithLength: fileNameLength
						encoding: encoding] copy];
				extraLength -= fileNameLength;
			} else
				_fileName = [[OFString alloc]
				    initWithCString: fileNameBuffer
					   encoding: encoding];

			if (directoryNameLength > 0) {
				if (extraLength < directoryNameLength)
					@throw [OFInvalidFormatException
					    exception];

				_directoryName = [[stream
				    readStringWithLength: directoryNameLength
						encoding: encoding] copy];
				extraLength -= directoryNameLength;
			}

			if (extraLength >= 2) {
				_operatingSystemIdentifier =
				    [stream readLittleEndianInt16];
				extraLength -= 2;
			}

			if (extraLength >= 3) {
				uint8_t attributes[3];

				[stream readIntoBuffer: attributes
					   exactLength: 3];

				if (attributes[2] & (1 << 6)) {
					uint16_t mode = (attributes[0] |
					    (attributes[1] << 8)) & 0777;

					_POSIXPermissions = [[OFNumber alloc]
					    initWithUnsignedShort: mode];
				}

				extraLength -= 3;
			}
		} else {
			_fileName = [[OFString alloc]
			    initWithCString: fileNameBuffer
				   encoding: encoding];
			_timeZone = 0x7F;
		}

		if (commentOffset != 0) {
			[stream seekToOffset: commentOffset whence: OFSeekSet];
			_fileComment = [[stream
			    readStringWithLength: commentLength
					encoding: encoding] retain];
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
	[_fileComment release];
	[_fileName release];
	[_directoryName release];
	[_POSIXPermissions release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFZooArchiveEntry *copy = [[OFMutableZooArchiveEntry alloc]
	    initWithFileName: _fileName];

	@try {
		copy->_headerType = _headerType;
		copy->_compressionMethod = _compressionMethod;
		copy->_nextHeaderOffset = _nextHeaderOffset;
		copy->_dataOffset = _dataOffset;
		copy->_lastModifiedFileDate = _lastModifiedFileDate;
		copy->_lastModifiedFileTime = _lastModifiedFileTime;
		copy->_CRC16 = _CRC16;
		copy->_uncompressedSize = _uncompressedSize;
		copy->_compressedSize = _compressedSize;
		copy->_minVersionNeeded = _minVersionNeeded;
		copy->_deleted = _deleted;
		copy->_fileComment = [_fileComment copy];
		copy->_directoryName = [_directoryName copy];
		copy->_operatingSystemIdentifier = _operatingSystemIdentifier;
		copy->_POSIXPermissions = [_POSIXPermissions retain];
		copy->_timeZone = _timeZone;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (uint8_t)headerType
{
	return _headerType;
}

- (uint8_t)compressionMethod
{
	return _compressionMethod;
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

	if (_timeZone == 0x7F)
		date = [[OFDate alloc]
		    initWithLocalDateString: dateString
				     format: @"%Y-%m-%d %H:%M:%S"];
	else {
		date = [OFDate dateWithDateString: dateString
					   format: @"%Y-%m-%d %H:%M:%S"];
		date = [[date dateByAddingTimeInterval:
		    (OFTimeInterval)_timeZone * 900] retain];
	}

	objc_autoreleasePoolPop(pool);

	return [date autorelease];
}

- (uint16_t)CRC16
{
	return _CRC16;
}

- (unsigned long long)uncompressedSize
{
	return _uncompressedSize;
}

- (unsigned long long)compressedSize
{
	return _compressedSize;
}

- (uint16_t)minVersionNeeded
{
	return _minVersionNeeded;
}

- (bool)isDeleted
{
	return _deleted;
}

- (OFString *)fileComment
{
	return _fileComment;
}

- (OFString *)fileName
{
	if (_directoryName == nil)
		return _fileName;

	return [OFString stringWithFormat: @"%@/%@", _directoryName, _fileName];
}

- (uint16_t)operatingSystemIdentifier
{
	return _operatingSystemIdentifier;
}

- (OFNumber *)POSIXPermissions
{
	return _POSIXPermissions;
}

- (OFNumber *)timeZone
{
	if (_timeZone == 0x7F)
		return nil;

	return [OFNumber numberWithFloat: -(float)_timeZone / 4];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tFile comment = %@\n"
	    @"\tCompressed size = %llu\n"
	    @"\tUncompressed size = %llu\n"
	    @"\tCompression method = %u\n"
	    @"\tModification date = %@\n"
	    @"\tCRC16 = %04" @PRIX16 @"\n"
	    @"\tDeleted = %u\n"
	    @">",
	    self.class, _fileName, _fileComment, _compressedSize,
	    _uncompressedSize, _compressionMethod, self.modificationDate,
	    _CRC16, _deleted];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
