/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#define OF_LHA_ARCHIVE_ENTRY_M

#include <string.h>

#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFStream.h"
#import "OFString.h"

#import "crc16.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

static OFDate *
parseMSDOSDate(uint32_t MSDOSDate)
{
	uint16_t year = ((MSDOSDate & 0xFE000000) >> 25) + 1980;
	uint8_t month = (MSDOSDate & 0x1E00000) >> 21;
	uint8_t day = (MSDOSDate & 0x1F);
	uint8_t hour = (MSDOSDate & 0xF800) >> 11;
	uint8_t minute = (MSDOSDate & 0x7E0) >> 5;
	uint8_t second = (MSDOSDate & 0x1F) << 1;
	OFString *dateString;

	dateString = [OFString
	    stringWithFormat: @"%04u-%02u-%02u %02u:%02u:%02u",
			      year, month, day, hour, minute, second];

	return [OFDate dateWithLocalDateString: dateString
					format: @"%Y-%m-%d %H:%M:%S"];
}

static void
parseFileNameExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	[entry->_fileName release];
	entry->_fileName = nil;

	entry->_fileName = [[OFString alloc]
	    initWithCString: (char *)[extension items] + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static void
parseDirectoryNameExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = [[extension mutableCopy] autorelease];
	char *items = [data items];
	size_t count = [data count];
	OFMutableString *directoryName;

	for (size_t i = 1; i < count; i++)
		if (items[i] == '\xFF')
			items[i] = '/';

	directoryName = [OFMutableString stringWithCString: items + 1
						  encoding: encoding
						    length: count - 1];

	if (![directoryName hasSuffix: @"/"])
		[directoryName appendString: @"/"];

	[directoryName makeImmutable];

	[entry->_directoryName release];
	entry->_directoryName = nil;

	entry->_directoryName = [directoryName copy];

	objc_autoreleasePoolPop(pool);
}

static void
parseCommentExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	[entry->_fileComment release];
	entry->_fileComment = nil;

	entry->_fileComment = [[OFString alloc]
	    initWithCString: (char *)[extension items] + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static void
parsePermissionsExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	uint16_t mode;

	if ([extension count] != 3)
		@throw [OFInvalidFormatException exception];

	memcpy(&mode, (char *)[extension items] + 1, 2);
	mode = OF_BSWAP16_IF_BE(mode);

	[entry->_mode release];
	entry->_mode = nil;

	entry->_mode = [[OFNumber alloc] initWithUInt16: mode];
}

static void
parseGIDUIDExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	uint16_t UID, GID;

	if ([extension count] != 5)
		@throw [OFInvalidFormatException exception];

	memcpy(&GID, (char *)[extension items] + 1, 2);
	GID = OF_BSWAP16_IF_BE(GID);

	memcpy(&UID, (char *)[extension items] + 3, 2);
	UID = OF_BSWAP16_IF_BE(UID);

	[entry->_GID release];
	entry->_GID = nil;

	[entry->_UID release];
	entry->_UID = nil;

	entry->_GID = [[OFNumber alloc] initWithUInt16: GID];
	entry->_UID = [[OFNumber alloc] initWithUInt16: UID];
}

static void
parseGroupExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	[entry->_group release];
	entry->_group = nil;

	entry->_group = [[OFString alloc]
	    initWithCString: (char *)[extension items] + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static void
parseOwnerExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	[entry->_owner release];
	entry->_owner = nil;

	entry->_owner = [[OFString alloc]
	    initWithCString: (char *)[extension items] + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static void
parseModificationDateExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding)
{
	uint32_t modificationDate;

	if ([extension count] != 5)
		@throw [OFInvalidFormatException exception];

	memcpy(&modificationDate, (char *)[extension items] + 1, 4);
	modificationDate = OF_BSWAP32_IF_BE(modificationDate);

	[entry->_modificationDate release];
	entry->_modificationDate = nil;

	entry->_modificationDate = [[OFDate alloc]
	    initWithTimeIntervalSince1970: modificationDate];
}

static bool
parseExtension(OFLHAArchiveEntry *entry, OFData *extension,
    of_string_encoding_t encoding, bool allowFileName)
{
	void (*function)(OFLHAArchiveEntry *, OFData *, of_string_encoding_t) =
	    NULL;

	switch (*(char *)[extension itemAtIndex: 0]) {
	case 0x01:
		if (allowFileName)
			function = parseFileNameExtension;
		break;
	case 0x02:
		function = parseDirectoryNameExtension;
		break;
	case 0x3F:
		function = parseCommentExtension;
		break;
	case 0x50:
		function = parsePermissionsExtension;
		break;
	case 0x51:
		function = parseGIDUIDExtension;
		break;
	case 0x52:
		function = parseGroupExtension;
		break;
	case 0x53:
		function = parseOwnerExtension;
		break;
	case 0x54:
		function = parseModificationDateExtension;
		break;
	}

	if (function == NULL)
		return false;

	function(entry, extension, encoding);
	return true;
}

static void
readExtensions(OFLHAArchiveEntry *entry, OFStream *stream,
    of_string_encoding_t encoding, bool allowFileName)
{
	uint16_t size;

	while ((size = [stream readLittleEndianInt16]) > 0) {
		OFData *extension;

		if (size < 2)
			@throw [OFInvalidFormatException exception];

		extension = [stream readDataWithCount: size - 2];

		if (!parseExtension(entry, extension, encoding, allowFileName))
			[entry->_extensions addObject: extension];

		if (entry->_headerLevel == 1) {
			if (entry->_compressedSize < size)
				@throw [OFInvalidFormatException exception];

			entry->_compressedSize -= size;
		}
	}
}

static void
getFileNameAndDirectoryName(OFLHAArchiveEntry *entry,
    of_string_encoding_t encoding,
    const char **fileName, size_t *fileNameLength,
    const char **directoryName, size_t *directoryNameLength)
{
	OFMutableData *data;
	char *cString;
	size_t length;
	size_t pos;

	/*
	 * We use OFMutableData to have an autoreleased buffer that we can
	 * return indirectly.
	 */
	data = [OFMutableData
	    dataWithItems: [entry->_directoryName cStringWithEncoding: encoding]
		    count: [entry->_directoryName
			       cStringLengthWithEncoding: encoding]];
	[data addItems: [entry->_fileName cStringWithEncoding: encoding]
		 count: [entry->_fileName cStringLengthWithEncoding: encoding]];

	cString = [data items];
	length = [data count];
	pos = 0;

	for (size_t i = 0; i < length; i++) {
		if (cString[i] == '/' || cString[i] == '\\') {
			cString[i] = '\xFF';
			pos = i + 1;
		}
	}

	*fileName = cString + pos;
	*fileNameLength = length - pos;
	*directoryName = cString;
	*directoryNameLength = pos;
}

@implementation OFLHAArchiveEntry
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
		_fileName = [fileName copy];
		_compressionMethod = @"-lh0-";
		_date = [[OFDate alloc] initWithTimeIntervalSince1970: 0];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithHeader: (char [21])header
			   stream: (OFStream *)stream
			 encoding: (of_string_encoding_t)encoding
{
	self = [super init];

	@try {
		uint32_t date;

		_compressionMethod = [[OFString alloc]
		    initWithCString: header + 2
			   encoding: OF_STRING_ENCODING_ASCII
			     length: 5];

		memcpy(&_compressedSize, header + 7, 4);
		_compressedSize = OF_BSWAP32_IF_BE(_compressedSize);

		memcpy(&_uncompressedSize, header + 11, 4);
		_uncompressedSize = OF_BSWAP32_IF_BE(_uncompressedSize);

		memcpy(&date, header + 15, 4);
		date = OF_BSWAP32_IF_BE(date);

		_headerLevel = header[20];
		_extensions = [[OFMutableArray alloc] init];

		switch (_headerLevel) {
		case 0:
		case 1:;
			void *pool = objc_autoreleasePoolPush();
			uint8_t fileNameLength;
			OFString *tmp;

			_date = [parseMSDOSDate(date) retain];

			fileNameLength = [stream readInt8];
			tmp = [stream readStringWithLength: fileNameLength
						  encoding: encoding];
			tmp = [tmp stringByReplacingOccurrencesOfString: @"\\"
							     withString: @"/"];
			_fileName = [tmp copy];

			_CRC16 = [stream readLittleEndianInt16];

			if (_headerLevel == 1) {
				_operatingSystemIdentifier = [stream readInt8];

				readExtensions(self, stream, encoding, false);
			}

			objc_autoreleasePoolPop(pool);
			break;
		case 2:
			_date = [[OFDate alloc]
			    initWithTimeIntervalSince1970: date];

			_CRC16 = [stream readLittleEndianInt16];
			_operatingSystemIdentifier = [stream readInt8];

			readExtensions(self, stream, encoding, true);

			break;
		default:;
			OFString *version = [OFString
			    stringWithFormat: @"%u", _headerLevel];

			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: version];
		}

		if (_fileName == nil)
			@throw [OFInvalidFormatException exception];

		[_extensions makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_compressionMethod release];
	[_fileName release];
	[_directoryName release];
	[_date release];
	[_fileComment release];
	[_mode release];
	[_UID release];
	[_GID release];
	[_owner release];
	[_group release];
	[_extensions release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFLHAArchiveEntry *copy = [[OFMutableLHAArchiveEntry alloc]
	    initWithFileName: _fileName];

	@try {
		[copy->_compressionMethod release];
		copy->_compressionMethod = nil;

		[copy->_date release];
		copy->_date = nil;

		copy->_directoryName = [_directoryName copy];
		copy->_compressionMethod = [_compressionMethod copy];
		copy->_compressedSize = _compressedSize;
		copy->_uncompressedSize = _uncompressedSize;
		copy->_date = [_date copy];
		copy->_headerLevel = _headerLevel;
		copy->_CRC16 = _CRC16;
		copy->_operatingSystemIdentifier = _operatingSystemIdentifier;
		copy->_fileComment = [_fileComment copy];
		copy->_mode = [_mode retain];
		copy->_UID = [_UID retain];
		copy->_GID = [_GID retain];
		copy->_owner = [_owner copy];
		copy->_group = [_group copy];
		copy->_modificationDate = [_modificationDate retain];
		copy->_extensions = [_extensions copy];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)fileName
{
	if (_directoryName == nil)
		return _fileName;

	return [_directoryName stringByAppendingString: _fileName];
}

- (OFString *)compressionMethod
{
	return _compressionMethod;
}

- (uint32_t)compressedSize
{
	return _compressedSize;
}

- (uint32_t)uncompressedSize
{
	return _uncompressedSize;
}

- (OFDate *)date
{
	return _date;
}

- (uint8_t)headerLevel
{
	return _headerLevel;
}

- (uint16_t)CRC16
{
	return _CRC16;
}

- (uint8_t)operatingSystemIdentifier
{
	return _operatingSystemIdentifier;
}

- (OFString *)fileComment
{
	return _fileComment;
}

- (OFNumber *)mode
{
	return _mode;
}

- (OFNumber *)UID
{
	return _UID;
}

- (OFNumber *)GID
{
	return _GID;
}

- (OFString *)owner
{
	return _owner;
}

- (OFString *)group
{
	return _group;
}

- (OFDate *)modificationDate
{
	return _modificationDate;
}

- (OFArray OF_GENERIC(OFData *) *)extensions
{
	return _extensions;
}

- (void)of_writeToStream: (OFStream *)stream
		encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = [OFMutableData dataWithCapacity: 24];
	const char *fileName, *directoryName;
	size_t fileNameLength, directoryNameLength;
	uint16_t tmp16;
	uint32_t tmp32;
	size_t headerSize;

	if ([_compressionMethod cStringLengthWithEncoding:
	    OF_STRING_ENCODING_ASCII] != 5)
		@throw [OFInvalidArgumentException exception];

	getFileNameAndDirectoryName(self, encoding, &fileName, &fileNameLength,
	    &directoryName, &directoryNameLength);

	if (fileNameLength > UINT16_MAX - 3 ||
	    directoryNameLength > UINT16_MAX - 3)
		@throw [OFOutOfRangeException exception];

	/* Length. Filled in after we're done. */
	[data increaseCountBy: 2];

	[data addItems: [_compressionMethod
			    cStringWithEncoding: OF_STRING_ENCODING_ASCII]
		 count: 5];

	tmp32 = OF_BSWAP32_IF_BE(_compressedSize);
	[data addItems: &tmp32
		 count: sizeof(tmp32)];

	tmp32 = OF_BSWAP32_IF_BE(_uncompressedSize);
	[data addItems: &tmp32
		 count: sizeof(tmp32)];

	tmp32 = OF_BSWAP32_IF_BE((uint32_t)[_date timeIntervalSince1970]);
	[data addItems: &tmp32
		 count: sizeof(tmp32)];

	/* Reserved */
	[data increaseCountBy: 1];

	/* Header level */
	[data addItem: "\x02"];

	/* CRC16 */
	tmp16 = OF_BSWAP16_IF_BE(_CRC16);
	[data addItems: &tmp16
		 count: sizeof(tmp16)];

	/* Operating system identifier */
	[data addItem: "U"];

	/* Common header. Contains CRC16, which is written at the end. */
	tmp16 = OF_BSWAP16_IF_BE(5);
	[data addItems: &tmp16
		 count: sizeof(tmp16)];
	[data addItem: "\x00"];
	[data increaseCountBy: 2];

	tmp16 = OF_BSWAP16_IF_BE((uint16_t)fileNameLength + 3);
	[data addItems: &tmp16
		 count: sizeof(tmp16)];
	[data addItem: "\x01"];
	[data addItems: fileName
		 count: fileNameLength];

	if (directoryNameLength > 0) {
		tmp16 = OF_BSWAP16_IF_BE((uint16_t)directoryNameLength + 3);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x02"];
		[data addItems: directoryName
			 count: directoryNameLength];
	}

	if (_fileComment != nil) {
		size_t fileCommentLength =
		    [_fileComment cStringLengthWithEncoding: encoding];

		if (fileCommentLength > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OF_BSWAP16_IF_BE((uint16_t)fileCommentLength + 3);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x3F"];
		[data addItems: [_fileComment cStringWithEncoding: encoding]
			 count: fileCommentLength];
	}

	if (_mode != nil) {
		tmp16 = OF_BSWAP16_IF_BE(5);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x50"];

		tmp16 = OF_BSWAP16_IF_BE([_mode uInt16Value]);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
	}

	if (_UID != nil || _GID != nil) {
		if (_UID == nil || _GID == nil)
			@throw [OFInvalidArgumentException exception];

		tmp16 = OF_BSWAP16_IF_BE(7);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x51"];

		tmp16 = OF_BSWAP16_IF_BE([_GID uInt16Value]);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];

		tmp16 = OF_BSWAP16_IF_BE([_UID uInt16Value]);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
	}

	if (_group != nil) {
		size_t groupLength =
		    [_group cStringLengthWithEncoding: encoding];

		if (groupLength > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OF_BSWAP16_IF_BE((uint16_t)groupLength + 3);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x52"];
		[data addItems: [_group cStringWithEncoding: encoding]
			 count: groupLength];
	}

	if (_owner != nil) {
		size_t ownerLength =
		    [_owner cStringLengthWithEncoding: encoding];

		if (ownerLength > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OF_BSWAP16_IF_BE((uint16_t)ownerLength + 3);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x53"];
		[data addItems: [_owner cStringWithEncoding: encoding]
			 count: ownerLength];
	}

	if (_modificationDate != nil) {
		tmp16 = OF_BSWAP16_IF_BE(7);
		[data addItems: &tmp16
			 count: sizeof(tmp16)];
		[data addItem: "\x54"];

		tmp32 = OF_BSWAP32_IF_BE(
		    (uint32_t)[_modificationDate timeIntervalSince1970]);
		[data addItems: &tmp32
			 count: sizeof(tmp32)];
	}

	/* Zero-length extension to terminate */
	[data increaseCountBy: 2];

	headerSize = [data count];

	if (headerSize > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	/* Now fill in the size and CRC16 for the entire header */
	tmp16 = OF_BSWAP16_IF_BE(headerSize);
	memcpy([data itemAtIndex: 0], &tmp16, sizeof(tmp16));

	tmp16 = OF_BSWAP16_IF_BE(of_crc16(0, [data items], [data count]));
	memcpy([data itemAtIndex: 27], &tmp16, sizeof(tmp16));

	[stream writeData: data];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *mode = (_mode == nil
	    ? nil
	    : [OFString stringWithFormat: @"%" PRIo16, [_mode uInt16Value]]);
	OFString *extensions = [[_extensions description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tCompression method = %@\n"
	    @"\tCompressed size = %" @PRIu32 "\n"
	    @"\tUncompressed size = %" @PRIu32 "\n"
	    @"\tDate = %@\n"
	    @"\tHeader level = %u\n"
	    @"\tCRC16 = %04" @PRIX16 @"\n"
	    @"\tOperating system identifier = %c\n"
	    @"\tComment = %@\n"
	    @"\tMode = %@\n"
	    @"\tUID = %@\n"
	    @"\tGID = %@\n"
	    @"\tOwner = %@\n"
	    @"\tGroup = %@\n"
	    @"\tModification date = %@\n"
	    @"\tExtensions: %@"
	    @">",
	    [self class], [self fileName], _compressionMethod, _compressedSize,
	    _uncompressedSize, _date, _headerLevel, _CRC16,
	    _operatingSystemIdentifier, _fileComment, mode, _UID, _GID, _owner,
	    _group, _modificationDate, extensions];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
