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

#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

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
	OFString *tmp = [OFString
	    stringWithCString: (char *)[extension items] + 1
		     encoding: encoding
		       length: [extension count] - 1];
	OFString *separator = [OFString stringWithCString: "\xFF"
						 encoding: encoding
						   length: 1];

	if (![tmp hasSuffix: separator])
		@throw [OFInvalidFormatException exception];

	tmp = [tmp stringByReplacingOccurrencesOfString: separator
					     withString: @"/"];

	[entry->_directoryName release];
	entry->_directoryName = nil;

	entry->_directoryName = [tmp copy];

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
    of_string_encoding_t encoding)
{
	void (*function)(OFLHAArchiveEntry *, OFData *, of_string_encoding_t) =
	    NULL;

	switch (*(char *)[extension itemAtIndex: 0]) {
	case 0x01:
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

@implementation OFLHAArchiveEntry
@synthesize method = _method, compressedSize = _compressedSize;
@synthesize uncompressedSize = _uncompressedSize, date = _date;
@synthesize level = _level, CRC16 = _CRC16;
@synthesize operatingSystemIdentifier = _operatingSystemIdentifier;
@synthesize fileComment = _fileComment, mode = _mode, UID = _UID, GID = _GID;
@synthesize owner = _owner, group = _group;
@synthesize modificationDate = _modificationDate, extensions = _extensions;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithHeaderSize: (uint8_t)headerSize
			       stream: (OFStream *)stream
			     encoding: (of_string_encoding_t)encoding
{
	self = [super init];

	@try {
		char header[20];
		uint32_t date;
		uint16_t nextSize;
		OFMutableArray *extensions;

		if (headerSize < 21)
			@throw [OFInvalidFormatException exception];

		[stream readIntoBuffer: header
			   exactLength: 20];

		if (memcmp(header + 1, "-lh0-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH0;
		else if (memcmp(header + 1, "-lzs-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LZS;
		else if (memcmp(header + 1, "-lz4-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LZ4;
		else if (memcmp(header + 1, "-lh1-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH1;
		else if (memcmp(header + 1, "-lh2-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH2;
		else if (memcmp(header + 1, "-lh3-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH3;
		else if (memcmp(header + 1, "-lh4-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH4;
		else if (memcmp(header + 1, "-lh5-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH5;
		else if (memcmp(header + 1, "-lh6-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH6;
		else if (memcmp(header + 1, "-lh7-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH7;
		else if (memcmp(header + 1, "-lh8-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LH8;
		else if (memcmp(header + 1, "-lhd-", 5) == 0)
			_method = OF_LHA_ARCHIVE_ENTRY_METHOD_LHD;
		else {
			OFString *version = [OFString
			    stringWithCString: header + 1
				     encoding: OF_STRING_ENCODING_ASCII
				       length: 5];

			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: version];
		}

		memcpy(&_compressedSize, header + 6, 4);
		_compressedSize = OF_BSWAP32_IF_BE(_compressedSize);

		memcpy(&_uncompressedSize, header + 10, 4);
		_uncompressedSize = OF_BSWAP32_IF_BE(_uncompressedSize);

		memcpy(&date, header + 14, 4);
		date = OF_BSWAP32_IF_BE(date);

		_level = header[19];

		if (_level != 2) {
			OFString *version = [OFString
			    stringWithFormat: @"%u", _level];

			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: version];
		}

		_date = [[OFDate alloc] initWithTimeIntervalSince1970: date];

		_CRC16 = [stream readLittleEndianInt16];
		_operatingSystemIdentifier = [stream readInt8];

		extensions = [[OFMutableArray alloc] init];
		_extensions = extensions;

		while ((nextSize = [stream readLittleEndianInt16]) > 0) {
			OFData *extension;

			if (nextSize < 2)
				@throw [OFInvalidFormatException exception];

			extension = [stream readDataWithCount: nextSize - 2];

			if (!parseExtension(self, extension, encoding))
				[extensions addObject: extension];
		}

		[extensions makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
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

- (OFString *)fileName
{
	if (_directoryName == nil)
		return _fileName;

	return [_directoryName stringByAppendingString: _fileName];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *mode = (_mode == nil
	    ? @"(nil)"
	    : [OFString stringWithFormat: @"%" PRIo16, [_mode uInt16Value]]);
	OFString *extensions = [[_extensions description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tCompressed size = %" @PRIu32 "\n"
	    @"\tUncompressed size = %" @PRIu32 "\n"
	    @"\tDate = %@\n"
	    @"\tLevel = %u\n"
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
	    [self class], [self fileName], _compressedSize, _uncompressedSize,
	    _date, _level, _CRC16, _operatingSystemIdentifier, _fileComment,
	    mode, _UID, _GID, _owner, _group, _modificationDate, extensions];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
