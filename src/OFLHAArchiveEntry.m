/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFArray.h"
#import "OFCRC16.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFSeekableStream.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

static OFDate *
parseMSDOSDate(uint32_t MSDOSDate)
{
	uint16_t year = ((MSDOSDate & 0xFE000000) >> 25) + 1980;
	uint8_t month = (MSDOSDate & 0x1E00000) >> 21;
	uint8_t day = (MSDOSDate & 0x1F0000) >> 16;
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

@implementation OFLHAArchiveEntry
/*
 * The following are optional in OFArchiveEntry, but Apple GCC 4.0.1 is buggy
 * and needs this to stop complaining.
 */
@dynamic targetFileName, deviceMajor, deviceMinor;

static void
parseFileNameExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	objc_release(entry->_fileName);
	entry->_fileName = nil;

	entry->_fileName = [[OFString alloc]
	    initWithCString: (char *)extension.items + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static void
parseDirectoryNameExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = objc_autorelease([extension mutableCopy]);
	char *items = data.mutableItems;
	size_t count = data.count;
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

	objc_release(entry->_directoryName);
	entry->_directoryName = nil;

	entry->_directoryName = [directoryName copy];

	objc_autoreleasePoolPop(pool);
}

static void
parseCommentExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	objc_release(entry->_fileComment);
	entry->_fileComment = nil;

	entry->_fileComment = [[OFString alloc]
	    initWithCString: (char *)extension.items + 1
		   encoding: encoding
		     length: extension.count - 1];
}

static void
parsePermissionsExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	uint16_t POSIXPermissions;

	if (extension.count != 3)
		@throw [OFInvalidFormatException exception];

	memcpy(&POSIXPermissions, (char *)extension.items + 1, 2);
	POSIXPermissions = OFFromLittleEndian16(POSIXPermissions);

	objc_release(entry->_POSIXPermissions);
	entry->_POSIXPermissions = nil;

	entry->_POSIXPermissions =
	    [[OFNumber alloc] initWithUnsignedShort: POSIXPermissions];
}

static void
parseGIDUIDExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	uint16_t ownerAccountID, groupOwnerAccountID;

	if (extension.count != 5)
		@throw [OFInvalidFormatException exception];

	memcpy(&groupOwnerAccountID, (char *)extension.items + 1, 2);
	groupOwnerAccountID = OFFromLittleEndian16(groupOwnerAccountID);

	memcpy(&ownerAccountID, (char *)extension.items + 3, 2);
	ownerAccountID = OFFromLittleEndian16(ownerAccountID);

	objc_release(entry->_groupOwnerAccountID);
	entry->_groupOwnerAccountID = nil;

	objc_release(entry->_ownerAccountID);
	entry->_ownerAccountID = nil;

	entry->_groupOwnerAccountID =
	    [[OFNumber alloc] initWithUnsignedShort: groupOwnerAccountID];
	entry->_ownerAccountID =
	    [[OFNumber alloc] initWithUnsignedShort: ownerAccountID];
}

static void
parseGroupExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	objc_release(entry->_groupOwnerAccountName);
	entry->_groupOwnerAccountName = nil;

	entry->_groupOwnerAccountName = [[OFString alloc]
	    initWithCString: (char *)extension.items + 1
		   encoding: encoding
		     length: extension.count - 1];
}

static void
parseOwnerExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	objc_release(entry->_ownerAccountName);
	entry->_ownerAccountName = nil;

	entry->_ownerAccountName = [[OFString alloc]
	    initWithCString: (char *)extension.items + 1
		   encoding: encoding
		     length: extension.count - 1];
}

static void
parseModificationDateExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	uint32_t modificationDate;

	if (extension.count != 5)
		@throw [OFInvalidFormatException exception];

	memcpy(&modificationDate, (char *)extension.items + 1, 4);
	modificationDate = OFFromLittleEndian32(modificationDate);

	objc_release(entry->_modificationDate);
	entry->_modificationDate = nil;

	entry->_modificationDate = [[OFDate alloc]
	    initWithTimeIntervalSince1970: modificationDate];
}

static void
parseFileSizeExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	uint64_t tmp;

	if (extension.count != 17)
		@throw [OFInvalidFormatException exception];

	memcpy(&tmp, (char *)extension.items + 1, 8);
	entry->_compressedSize = OFFromLittleEndian64(tmp);

	memcpy(&tmp, (char *)extension.items + 9, 8);
	entry->_uncompressedSize = OFFromLittleEndian64(tmp);
}

static void
parseMSDOSAttributesExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	uint16_t tmp;

	if (extension.count != 3)
		@throw [OFInvalidFormatException exception];

	objc_release(entry->_MSDOSAttributes);
	entry->_MSDOSAttributes = nil;

	memcpy(&tmp, (char *)extension.items + 1, 2);
	entry->_MSDOSAttributes = [OFNumber numberWithUnsignedShort:
	    OFFromLittleEndian16(tmp)];
}

static void
parseAmigaCommentExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding)
{
	objc_release(entry->_amigaComment);
	entry->_amigaComment = nil;

	entry->_amigaComment = [[OFString alloc]
	    initWithCString: (char *)extension.items + 1
		   encoding: encoding
		     length: [extension count] - 1];
}

static bool
parseExtension(OFLHAArchiveEntry *entry, OFData *extension,
    OFStringEncoding encoding, bool allowFileName)
{
	void (*function)(OFLHAArchiveEntry *, OFData *, OFStringEncoding) =
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
	case 0x40:
		function = parseMSDOSAttributesExtension;
		break;
	case 0x42:
		function = parseFileSizeExtension;
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
	case 0x71:
		function = parseAmigaCommentExtension;
		break;
	}

	if (function == NULL)
		return false;

	function(entry, extension, encoding);
	return true;
}

static size_t
readExtensions(OFLHAArchiveEntry *entry, OFStream *stream,
    OFStringEncoding encoding, bool allowFileName)
{
	size_t consumed = 0;

	for (;;) {
		uint32_t size;
		OFData *extension;

		if (entry->_headerLevel == 3) {
			size = [stream readLittleEndianInt32];
			consumed += 4;
		} else {
			size = [stream readLittleEndianInt16];
			consumed += 2;
		}

		if (size == 0)
			break;

		if (size < 2 || (entry->_headerLevel == 3 && size < 4))
			@throw [OFInvalidFormatException exception];

		extension = [stream readDataWithCount:
		    size - (entry->_headerLevel == 3 ? 4 : 2)];
		consumed += extension.count;

		if (!parseExtension(entry, extension, encoding, allowFileName))
			[entry->_extensions addObject: extension];

		if (entry->_headerLevel == 1) {
			if (entry->_compressedSize < size)
				@throw [OFInvalidFormatException exception];

			entry->_compressedSize -= size;
		}
	}

	return consumed;
}

static void
getFileNameAndDirectoryName(OFLHAArchiveEntry *entry, OFStringEncoding encoding,
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

	cString = data.mutableItems;
	length = data.count;
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

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	self = [super init];

	@try {
		_compressionMethod = @"-lh0-";
		_modificationDate = [[OFDate alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithHeader: (char [21])header
			   stream: (OFStream *)stream
			 encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		uint32_t tmp, date;

		memcpy(&tmp, header + 7, 4);
		_compressedSize = OFFromLittleEndian32(tmp);

		memcpy(&tmp, header + 11, 4);
		_uncompressedSize = OFFromLittleEndian32(tmp);

		memcpy(&date, header + 15, 4);
		date = OFFromLittleEndian32(date);

		_headerLevel = header[20];
		_extensions = [[OFMutableArray alloc] init];

		switch (_headerLevel) {
		case 0:
		case 1:;
			void *pool = objc_autoreleasePoolPush();
			uint8_t extendedAreaSize;
			char fileNameBuffer[255];
			uint8_t fileNameLength;
			OFString *fileName;
			char *amigaCommentPtr;

			if (header[0] < (21 - 2) + 1 + 2)
				@throw [OFInvalidFormatException exception];

			_modificationDate = objc_retain(parseMSDOSDate(date));

			fileNameLength = [stream readInt8];
			[stream readIntoBuffer: fileNameBuffer
				   exactLength: fileNameLength];

			_MSDOSAttributes = [[OFNumber alloc]
			    initWithUnsignedChar: header[19]];

			_CRC16 = [stream readLittleEndianInt16];

			extendedAreaSize =
			    header[0] - (21 - 2) - 1 - fileNameLength - 2;

			if (_headerLevel == 1) {
				if (extendedAreaSize < 3)
					@throw [OFInvalidFormatException
					    exception];

				_operatingSystemIdentifier = [stream readInt8];

				/*
				 * 1 for the operating system identifier, 2
				 * because we don't want to skip the size of
				 * the next extended header.
				 */
				extendedAreaSize -= 1 + 2;
			}

			amigaCommentPtr = memchr(fileNameBuffer, '\0',
			    fileNameLength);
			if (amigaCommentPtr != NULL) {
				size_t newFileNameLength =
				    (amigaCommentPtr - fileNameBuffer);

				_amigaComment = [[OFString alloc]
				    initWithCString: amigaCommentPtr + 1
					   encoding: encoding
					     length: fileNameLength -
						     newFileNameLength - 1];

				fileNameLength = newFileNameLength;
			}

			fileName = [OFString stringWithCString: fileNameBuffer
						      encoding: encoding
							length: fileNameLength];
			fileName = [fileName
			    stringByReplacingOccurrencesOfString: @"\\"
						      withString: @"/"];
			_fileName = [fileName copy];

			/* Skip extended area */
			if ([stream isKindOfClass: [OFSeekableStream class]])
				[(OFSeekableStream *)stream
				    seekToOffset: extendedAreaSize
					  whence: OFSeekCurrent];
			else {
				char buffer[256];

				while (extendedAreaSize > 0)
					extendedAreaSize -= [stream
					    readIntoBuffer: buffer
						    length: extendedAreaSize];
			}

			if (_headerLevel == 1)
				readExtensions(self, stream, encoding, false);

			objc_autoreleasePoolPop(pool);
			break;
		case 2:
		case 3:;
			size_t padding = 0;

			_modificationDate = [[OFDate alloc]
			    initWithTimeIntervalSince1970: date];

			_CRC16 = [stream readLittleEndianInt16];
			_operatingSystemIdentifier = [stream readInt8];

			if (_operatingSystemIdentifier == 'A') {
				/*
				 * Amiga LHA uses seconds since 1970-01-01 in
				 * local time rather than UTC.
				 */
				OFString *tmpStr = [_modificationDate
				    dateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
				OFDate *tmpDate = [OFDate
				    dateWithLocalDateString: tmpStr
						     format: @"%Y-%m-%d "
							     @"%H:%M:%S"];
				objc_release(_modificationDate);
				_modificationDate = objc_retain(tmpDate);
			}

			if (_headerLevel == 3)
				/* Size of entire header */
				padding = [stream readLittleEndianInt32];
			else
				padding = (header[1] << 8) | header[0];

			/*
			 * 21 for header, 2 for CRC16, 1 for operating system
			 * identifier.
			 */
			padding -= 21 + 2 + 1;

			padding -= readExtensions(self, stream, encoding, true);

			/* Skip padding */
			if ([stream isKindOfClass: [OFSeekableStream class]])
				[(OFSeekableStream *)stream
				    seekToOffset: padding
					  whence: OFSeekCurrent];
			else {
				while (padding > 0) {
					char buffer[512];
					size_t min = padding;

					if (min > 512)
						min = 512;

					padding -= [stream
					    readIntoBuffer: buffer
						    length: min];
				}
			}

			break;
		default:;
			OFString *version = [OFString
			    stringWithFormat: @"%u", _headerLevel];

			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: version];
		}

		if (_fileName == nil)
			@throw [OFInvalidFormatException exception];

		_compressionMethod = [[OFString alloc]
		    initWithCString: header + 2
			   encoding: OFStringEncodingASCII
			     length: 5];

		[_extensions makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_compressionMethod);
	objc_release(_fileName);
	objc_release(_directoryName);
	objc_release(_modificationDate);
	objc_release(_fileComment);
	objc_release(_POSIXPermissions);
	objc_release(_ownerAccountID);
	objc_release(_groupOwnerAccountID);
	objc_release(_ownerAccountName);
	objc_release(_groupOwnerAccountName);
	objc_release(_MSDOSAttributes);
	objc_release(_amigaComment);
	objc_release(_extensions);

	[super dealloc];
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	OFLHAArchiveEntry *copy = [[OFMutableLHAArchiveEntry alloc]
	    initWithFileName: _fileName];

	@try {
		objc_release(copy->_compressionMethod);
		copy->_compressionMethod = nil;

		objc_release(copy->_modificationDate);
		copy->_modificationDate = nil;

		copy->_directoryName = [_directoryName copy];
		copy->_compressionMethod = [_compressionMethod copy];
		copy->_compressedSize = _compressedSize;
		copy->_uncompressedSize = _uncompressedSize;
		copy->_modificationDate = [_modificationDate copy];
		copy->_headerLevel = _headerLevel;
		copy->_CRC16 = _CRC16;
		copy->_operatingSystemIdentifier = _operatingSystemIdentifier;
		copy->_fileComment = [_fileComment copy];
		copy->_POSIXPermissions = objc_retain(_POSIXPermissions);
		copy->_ownerAccountID = objc_retain(_ownerAccountID);
		copy->_groupOwnerAccountID = objc_retain(_groupOwnerAccountID);
		copy->_ownerAccountName = [_ownerAccountName copy];
		copy->_groupOwnerAccountName = [_groupOwnerAccountName copy];
		copy->_extensions = [_extensions copy];
		copy->_MSDOSAttributes = objc_retain(_MSDOSAttributes);
		copy->_amigaComment = [_amigaComment copy];
	} @catch (id e) {
		objc_release(copy);
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

- (OFArchiveEntryFileType)fileType
{
	if ([_fileName hasSuffix: @"/"])
		return OFArchiveEntryFileTypeDirectory;

	return OFArchiveEntryFileTypeRegular;
}

- (OFString *)compressionMethod
{
	return _compressionMethod;
}

- (unsigned long long)compressedSize
{
	return _compressedSize;
}

- (unsigned long long)uncompressedSize
{
	return _uncompressedSize;
}

- (OFDate *)modificationDate
{
	return _modificationDate;
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

- (OFNumber *)POSIXPermissions
{
	return _POSIXPermissions;
}

- (OFNumber *)ownerAccountID
{
	return _ownerAccountID;
}

- (OFNumber *)groupOwnerAccountID
{
	return _groupOwnerAccountID;
}

- (OFString *)ownerAccountName
{
	return _ownerAccountName;
}

- (OFString *)groupOwnerAccountName
{
	return _groupOwnerAccountName;
}

- (OFNumber *)MSDOSAttributes
{
	return _MSDOSAttributes;
}

- (OFString *)amigaComment
{
	return _amigaComment;
}

- (OFArray OF_GENERIC(OFData *) *)extensions
{
	return _extensions;
}

- (void)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = [OFMutableData dataWithCapacity: 24];
	const char *fileName, *directoryName;
	size_t fileNameLength, directoryNameLength;
	uint16_t tmp16;
	uint32_t tmp32;
	uint64_t tmp64;
	size_t headerSize;

	if ([_compressionMethod cStringLengthWithEncoding:
	    OFStringEncodingASCII] != 5)
		@throw [OFInvalidArgumentException exception];

	getFileNameAndDirectoryName(self, encoding, &fileName, &fileNameLength,
	    &directoryName, &directoryNameLength);

	if (fileNameLength > UINT16_MAX - 3 ||
	    directoryNameLength > UINT16_MAX - 3 ||
	    _compressedSize > UINT64_MAX || _uncompressedSize > UINT64_MAX)
		@throw [OFOutOfRangeException exception];

	/* Length. Filled in after we're done. */
	[data increaseCountBy: 2];

	[data addItems: [_compressionMethod
			    cStringWithEncoding: OFStringEncodingASCII]
		 count: 5];

	tmp32 = OFToLittleEndian32((uint32_t)_compressedSize);
	[data addItems: &tmp32 count: sizeof(tmp32)];

	tmp32 = OFToLittleEndian32((uint32_t)_uncompressedSize);
	[data addItems: &tmp32 count: sizeof(tmp32)];

	if (_operatingSystemIdentifier == 'A') {
		/*
		 * Amiga LHA uses seconds since 1970-01-01 in local time rather
		 * than UTC.
		 */
		OFString *tmpStr = [_modificationDate
		    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
		OFDate *tmpDate = [OFDate
		    dateWithDateString: tmpStr
				format: @"%Y-%m-%d %H:%M:%S"];
		tmp32 = OFToLittleEndian32(
		    (uint32_t)tmpDate.timeIntervalSince1970);
	} else
		tmp32 = OFToLittleEndian32(
		    (uint32_t)_modificationDate.timeIntervalSince1970);
	[data addItems: &tmp32 count: sizeof(tmp32)];

	/* Reserved */
	[data increaseCountBy: 1];

	/* Header level */
	[data addItem: "\x02"];

	/* CRC16 */
	tmp16 = OFToLittleEndian16(_CRC16);
	[data addItems: &tmp16 count: sizeof(tmp16)];

	/* Operating system identifier */
	if (_operatingSystemIdentifier != 0)
		[data addItem: &_operatingSystemIdentifier];
	else
		[data addItem: "U"];

	/* Common header. Contains CRC16, which is written at the end. */
	tmp16 = OFToLittleEndian16(5);
	[data addItems: &tmp16 count: sizeof(tmp16)];
	[data addItem: "\x00"];
	[data increaseCountBy: 2];

	tmp16 = OFToLittleEndian16((uint16_t)fileNameLength + 3);
	[data addItems: &tmp16 count: sizeof(tmp16)];
	[data addItem: "\x01"];
	[data addItems: fileName count: fileNameLength];

	if (directoryNameLength > 0) {
		tmp16 = OFToLittleEndian16((uint16_t)directoryNameLength + 3);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x02"];
		[data addItems: directoryName count: directoryNameLength];
	}

	if (_fileComment != nil) {
		size_t fileCommentLength =
		    [_fileComment cStringLengthWithEncoding: encoding];

		if (fileCommentLength > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OFToLittleEndian16((uint16_t)fileCommentLength + 3);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x3F"];
		[data addItems: [_fileComment cStringWithEncoding: encoding]
			 count: fileCommentLength];
	}

	/*
	 * Always include the file size extension, as the header can be written
	 * with size 0 initially and then rewritten with the actual size in
	 * case the data to be archived is being streamed - but for that we
	 * need to make sure we always have the space.
	 */
	tmp16 = OFToLittleEndian16(19);
	[data addItems: &tmp16 count: sizeof(tmp16)];
	[data addItem: "\x42"];
	tmp64 = OFToLittleEndian64(_compressedSize);
	[data addItems: &tmp64 count: sizeof(tmp64)];
	tmp64 = OFToLittleEndian64(_uncompressedSize);
	[data addItems: &tmp64 count: sizeof(tmp64)];

	if (_MSDOSAttributes != nil) {
		tmp16 = OFToLittleEndian16(5);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x40"];

		tmp16 =
		    OFToLittleEndian16(_MSDOSAttributes.unsignedShortValue);
		[data addItems: &tmp16 count: sizeof(tmp16)];
	}

	if (_POSIXPermissions != nil) {
		tmp16 = OFToLittleEndian16(5);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x50"];

		tmp16 =
		    OFToLittleEndian16(_POSIXPermissions.unsignedShortValue);
		[data addItems: &tmp16 count: sizeof(tmp16)];
	}

	if (_ownerAccountID != nil || _groupOwnerAccountID != nil) {
		if (_ownerAccountID == nil || _groupOwnerAccountID == nil)
			@throw [OFInvalidArgumentException exception];

		tmp16 = OFToLittleEndian16(7);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x51"];

		tmp16 = OFToLittleEndian16(
		    _groupOwnerAccountID.unsignedShortValue);
		[data addItems: &tmp16 count: sizeof(tmp16)];

		tmp16 = OFToLittleEndian16(_ownerAccountID.unsignedShortValue);
		[data addItems: &tmp16 count: sizeof(tmp16)];
	}

	if (_groupOwnerAccountName != nil) {
		size_t length = [_groupOwnerAccountName
		    cStringLengthWithEncoding: encoding];

		if (length > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OFToLittleEndian16((uint16_t)length + 3);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x52"];
		[data addItems: [_groupOwnerAccountName
				    cStringWithEncoding: encoding]
			 count: length];
	}

	if (_ownerAccountName != nil) {
		size_t length =
		    [_ownerAccountName cStringLengthWithEncoding: encoding];

		if (length > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OFToLittleEndian16((uint16_t)length + 3);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x53"];
		[data addItems: [_ownerAccountName
				    cStringWithEncoding: encoding]
			 count: length];
	}

	if (_amigaComment != nil) {
		size_t length =
		    [_amigaComment cStringLengthWithEncoding: encoding];

		if (length > UINT16_MAX - 3)
			@throw [OFOutOfRangeException exception];

		tmp16 = OFToLittleEndian16((uint16_t)length + 3);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItem: "\x71"];
		[data addItems: [_amigaComment cStringWithEncoding: encoding]
			 count: length];
	}

	for (OFData *extension in _extensions) {
		size_t extensionLength = extension.count;

		if (extension.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		if (extensionLength > UINT16_MAX - 2)
			@throw [OFOutOfRangeException exception];

		tmp16 = OFToLittleEndian16((uint16_t)extensionLength + 2);
		[data addItems: &tmp16 count: sizeof(tmp16)];
		[data addItems: extension.items count: extension.count];
	}

	/* Zero-length extension to terminate */
	[data increaseCountBy: 2];

	/*
	 * Some implementations only check the first byte to see if the end of
	 * the archive has been reached, which is 0 for every multiple of 256.
	 * Add one byte of padding to avoid this.
	 */
	if ((data.count & 0xFF) == 0)
		[data increaseCountBy: 1];

	headerSize = data.count;

	if (headerSize > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	/* Now fill in the size and CRC16 for the entire header */
	tmp16 = OFToLittleEndian16(headerSize);
	memcpy([data mutableItemAtIndex: 0], &tmp16, sizeof(tmp16));

	tmp16 = _OFCRC16(0, data.items, data.count);
	tmp16 = OFToLittleEndian16(tmp16);
	memcpy([data mutableItemAtIndex: 27], &tmp16, sizeof(tmp16));

	[stream writeData: data];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *POSIXPermissions = nil;
	OFString *extensions = [_extensions.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *ret;

	if (_POSIXPermissions != nil)
		POSIXPermissions = [OFString stringWithFormat: @"%ho",
		    _POSIXPermissions.unsignedShortValue];

	ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tCompression method = %@\n"
	    @"\tCompressed size = %llu\n"
	    @"\tUncompressed size = %llu\n"
	    @"\tModification date = %@\n"
	    @"\tHeader level = %u\n"
	    @"\tCRC16 = %04" @PRIX16 @"\n"
	    @"\tOperating system identifier = %c\n"
	    @"\tComment = %@\n"
	    @"\tPOSIX permissions = %@\n"
	    @"\tOwner account ID = %@\n"
	    @"\tGroup owner account ID = %@\n"
	    @"\tOwner account name = %@\n"
	    @"\tGroup owner accounut name = %@\n"
	    @"\tMS-DOS attributes = %@\n"
	    @"\tAmiga comment = %@\n"
	    @"\tExtensions: %@"
	    @">",
	    self.class, self.fileName, _compressionMethod, _compressedSize,
	    _uncompressedSize, _modificationDate, _headerLevel, _CRC16,
	    _operatingSystemIdentifier, _fileComment, POSIXPermissions,
	    _ownerAccountID, _groupOwnerAccountID, _ownerAccountName,
	    _groupOwnerAccountName, _MSDOSAttributes, _amigaComment,
	    extensions];

	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
