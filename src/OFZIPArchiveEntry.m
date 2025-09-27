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

#import "OFZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFZIPArchive.h"
#import "OFZIPArchive+Private.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

OFString *
OFZIPArchiveEntryVersionToString(uint16_t version)
{
	const char *attrCompat = NULL;

	switch (version >> 8) {
	case OFZIPArchiveEntryAttributeCompatibilityMSDOS:
		attrCompat = "MS-DOS or OS/2";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityAmiga:
		attrCompat = "Amiga";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityOpenVMS:
		attrCompat = "OpenVMS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityUNIX:
		attrCompat = "UNIX";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityVM_CMS:
		attrCompat = "VM/CMS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityAtariST:
		attrCompat = "Atari ST";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityOS2HPFS:
		attrCompat = "OS/2 HPFS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityMacintosh:
		attrCompat = "Macintosh";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityZSystem:
		attrCompat = "Z-System";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityCPM:
		attrCompat = "CP/M";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityWindowsNTFS:
		attrCompat = "Windows NTFS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityMVS:
		attrCompat = "MVS (OS/390 - Z/OS)";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityVSE:
		attrCompat = "VSE";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityAcornRISCOS:
		attrCompat = "Acorn RISC OS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityVFAT:
		attrCompat = "VFAT";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityAlternateMVS:
		attrCompat = "Alternate MVS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityBeOS:
		attrCompat = "BeOS";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityTandem:
		attrCompat = "Tandem";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityOS400:
		attrCompat = "OS/400";
		break;
	case OFZIPArchiveEntryAttributeCompatibilityOSX:
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
OFZIPArchiveEntryCompressionMethodName(
    OFZIPArchiveEntryCompressionMethod compressionMethod)
{
	switch (compressionMethod) {
	case OFZIPArchiveEntryCompressionMethodNone:
		return @"none";
	case OFZIPArchiveEntryCompressionMethodShrink:
		return @"Shrink";
	case OFZIPArchiveEntryCompressionMethodReduceFactor1:
		return @"Reduce (factor 1)";
	case OFZIPArchiveEntryCompressionMethodReduceFactor2:
		return @"Reduce (factor 2)";
	case OFZIPArchiveEntryCompressionMethodReduceFactor3:
		return @"Reduce (factor 3)";
	case OFZIPArchiveEntryCompressionMethodReduceFactor4:
		return @"Reduce (factor 4)";
	case OFZIPArchiveEntryCompressionMethodImplode:
		return @"Implode";
	case OFZIPArchiveEntryCompressionMethodDeflate:
		return @"Deflate";
	case OFZIPArchiveEntryCompressionMethodDeflate64:
		return @"Deflate64";
	case OFZIPArchiveEntryCompressionMethodBZIP2:
		return @"BZip2";
	case OFZIPArchiveEntryCompressionMethodLZMA:
		return @"LZMA";
	case OFZIPArchiveEntryCompressionMethodWavPack:
		return @"WavPack";
	case OFZIPArchiveEntryCompressionMethodPPMd:
		return @"PPMd";
	default:
		return @"unknown";
	}
}

size_t
OFZIPArchiveEntryExtraFieldFind(OFData *extraField,
    OFZIPArchiveEntryExtraFieldTag tag, uint16_t *size)
{
	const uint8_t *bytes = extraField.items;
	size_t count = extraField.count;

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
	return OFNotFound;
}

@implementation OFZIPArchiveEntry
/*
 * The following are optional in OFArchiveEntry, but Apple GCC 4.0.1 is buggy
 * and needs this to stop complaining.
 */
@dynamic POSIXPermissions, ownerAccountID, groupOwnerAccountID;
@dynamic ownerAccountName, groupOwnerAccountName;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)of_initWithStream: (OFStream *)stream
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableData *extraField = nil;
		uint16_t fileNameLength, extraFieldLength, fileCommentLength;
		OFStringEncoding encoding;
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

		encoding = (_generalPurposeBitFlag & (1u << 11)
		    ? OFStringEncodingUTF8 : OFStringEncodingCodepage437);

		_fileName = [[stream readStringWithLength: fileNameLength
						 encoding: encoding] copy];
		if (extraFieldLength > 0)
			extraField = objc_autorelease([[stream
			    readDataWithCount: extraFieldLength] mutableCopy]);
		if (fileCommentLength > 0)
			_fileComment = [[stream
			    readStringWithLength: fileCommentLength
					encoding: encoding] copy];

		ZIP64Index = OFZIPArchiveEntryExtraFieldFind(extraField,
		    OFZIPArchiveEntryExtraFieldTagZIP64, &ZIP64Size);

		if (ZIP64Index != OFNotFound && ZIP64Size > 0) {
			const uint8_t *ZIP64 =
			    [extraField itemAtIndex: ZIP64Index];
			OFRange range =
			    OFMakeRange(ZIP64Index - 4, ZIP64Size + 4);

			if (_uncompressedSize == 0xFFFFFFFF)
				_uncompressedSize = _OFZIPArchiveReadField64(
				    &ZIP64, &ZIP64Size);
			if (_compressedSize == 0xFFFFFFFF)
				_compressedSize = _OFZIPArchiveReadField64(
				    &ZIP64, &ZIP64Size);
			if (_localFileHeaderOffset == 0xFFFFFFFF)
				_localFileHeaderOffset =
				    _OFZIPArchiveReadField64(&ZIP64,
				    &ZIP64Size);
			if (_startDiskNumber == 0xFFFF)
				_startDiskNumber = _OFZIPArchiveReadField32(
				    &ZIP64, &ZIP64Size);

			if (ZIP64Size > 0 || _localFileHeaderOffset < 0)
				@throw [OFInvalidFormatException exception];

			[extraField removeItemsInRange: range];
		}

		if (extraField.count > 0) {
			[extraField makeImmutable];
			_extraField = [extraField copy];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_fileName);
	objc_release(_extraField);
	objc_release(_fileComment);

	[super dealloc];
}

- (id)copy
{
	return objc_retain(self);
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
		objc_release(copy);
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

- (OFZIPArchiveEntryAttributeCompatibility)versionMadeBy
{
	return _versionMadeBy;
}

- (OFZIPArchiveEntryAttributeCompatibility)minVersionNeeded
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

	return objc_autoreleaseReturnValue(date);
}

- (OFZIPArchiveEntryCompressionMethod)compressionMethod
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

- (uint32_t)of_startDiskNumber
{
	return _startDiskNumber;
}

- (void)of_setStartDiskNumber: (uint32_t)startDiskNumber
{
	_startDiskNumber = startDiskNumber;
}

- (int64_t)of_localFileHeaderOffset
{
	return _localFileHeaderOffset;
}

- (void)of_setLocalFileHeaderOffset: (int64_t)localFileHeaderOffset
{
	if (localFileHeaderOffset < 0)
		@throw [OFInvalidArgumentException exception];

	_localFileHeaderOffset = localFileHeaderOffset;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *compressionMethod =
	    OFZIPArchiveEntryCompressionMethodName(_compressionMethod);
	OFString *ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tFile name = %@\n"
	    @"\tFile comment = %@\n"
	    @"\tGeneral purpose bit flag = %u\n"
	    @"\tCompressed size = %llu\n"
	    @"\tUncompressed size = %llu\n"
	    @"\tCompression method = %@\n"
	    @"\tModification date = %@\n"
	    @"\tCRC32 = %08" @PRIX32 @"\n"
	    @"\tExtra field = %@\n"
	    @">",
	    self.class, _fileName, _fileComment, _generalPurposeBitFlag,
	    _compressedSize, _uncompressedSize, compressionMethod,
	    self.modificationDate, _CRC32, _extraField];

	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (uint64_t)of_writeToStream: (OFStream *)stream
{
	void *pool = objc_autoreleasePoolPush();
	uint64_t size = 0;

	if (UINT16_MAX - _extraField.count < 32)
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
	[stream writeLittleEndianInt16: (uint16_t)_fileName.UTF8StringLength];
	[stream writeLittleEndianInt16: (uint16_t)_extraField.count + 32];
	[stream writeLittleEndianInt16:
	    (uint16_t)_fileComment.UTF8StringLength];
	[stream writeLittleEndianInt16: 0xFFFF];
	[stream writeLittleEndianInt16: _internalAttributes];
	[stream writeLittleEndianInt32: _versionSpecificAttributes];
	[stream writeLittleEndianInt32: 0xFFFFFFFF];
	size += (4 + (6 * 2) + (3 * 4) + (5 * 2) + (2 * 4));

	[stream writeString: _fileName encoding: OFStringEncodingUTF8];
	size += (uint64_t)_fileName.UTF8StringLength;

	[stream writeLittleEndianInt16: OFZIPArchiveEntryExtraFieldTagZIP64];
	[stream writeLittleEndianInt16: 28];
	[stream writeLittleEndianInt64: _uncompressedSize];
	[stream writeLittleEndianInt64: _compressedSize];
	[stream writeLittleEndianInt64: _localFileHeaderOffset];
	[stream writeLittleEndianInt32: _startDiskNumber];
	size += (2 * 2) + (3 * 8) + 4;

	if (_extraField != nil)
		[stream writeData: _extraField];
	size += (uint64_t)_extraField.count;

	if (_fileComment != nil)
		[stream writeString: _fileComment
			   encoding: OFStringEncodingUTF8];
	size += (uint64_t)_fileComment.UTF8StringLength;

	objc_autoreleasePoolPop(pool);

	return size;
}
@end
