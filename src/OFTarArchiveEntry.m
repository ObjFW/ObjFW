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

#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

static OFString *
stringFromBuffer(const unsigned char *buffer, size_t length,
    OFStringEncoding encoding)
{
	for (size_t i = 0; i < length; i++)
		if (buffer[i] == '\0')
			length = i;

	return [OFString stringWithCString: (const char *)buffer
				  encoding: encoding
				    length: length];
}

static void
stringToBuffer(unsigned char *buffer, OFString *string, size_t length,
    OFStringEncoding encoding)
{
	size_t cStringLength = [string cStringLengthWithEncoding: encoding];

	if (cStringLength > length)
		@throw [OFOutOfRangeException exception];

	memcpy(buffer, [string cStringWithEncoding: encoding], cStringLength);

	for (size_t i = cStringLength; i < length; i++)
		buffer[i] = '\0';
}

static unsigned long long
octalValueFromBuffer(const unsigned char *buffer, size_t length,
    unsigned long long max)
{
	unsigned long long value = 0;

	if (length == 0)
		return 0;

	if (buffer[0] == 0x80) {
		for (size_t i = 1; i < length; i++)
			value = (value << 8) | buffer[i];
	} else
		value = [stringFromBuffer(buffer, length,
		    OFStringEncodingASCII) unsignedLongLongValueWithBase: 8];

	if (value > max)
		@throw [OFOutOfRangeException exception];

	return value;
}

@implementation OFTarArchiveEntry
/*
 * The following is optional in OFArchiveEntry, but Apple GCC 4.0.1 is buggy
 * and needs this to stop complaining.
 */
@dynamic fileComment;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	self = [super init];

	@try {
		_type = OFTarArchiveEntryTypeFile;
		_POSIXPermissions =
		    [[OFNumber alloc] initWithUnsignedShort: 0644];
		_modificationDate = [[OFDate alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)of_initWithHeader: (unsigned char [512])header
			 encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *targetFileName;

		_fileName = [stringFromBuffer(header, 100, encoding) copy];
		_POSIXPermissions = [[OFNumber alloc] initWithUnsignedLongLong:
		    octalValueFromBuffer(header + 100, 8, ULONG_MAX)];
		_ownerAccountID = [[OFNumber alloc] initWithUnsignedLongLong:
		    octalValueFromBuffer(header + 108, 8, ULONG_MAX)];
		_groupOwnerAccountID = [[OFNumber alloc]
		    initWithUnsignedLongLong:
		    octalValueFromBuffer(header + 116, 8, ULONG_MAX)];
		_uncompressedSize = (unsigned long long)octalValueFromBuffer(
		    header + 124, 12, ULLONG_MAX);
		_compressedSize =
		    _uncompressedSize + (512 - _uncompressedSize % 512);
		_modificationDate = [[OFDate alloc]
		    initWithTimeIntervalSince1970:
		    (OFTimeInterval)octalValueFromBuffer(
		    header + 136, 12, ULLONG_MAX)];
		_type = header[156];

		targetFileName = stringFromBuffer(header + 157, 100, encoding);
		if (targetFileName.length > 0)
			_targetFileName = [targetFileName copy];

		if (_type == '\0')
			_type = OFTarArchiveEntryTypeFile;

		if (memcmp(header + 257, "ustar\0" "00", 8) == 0) {
			OFString *prefix;

			_ownerAccountName =
			    [stringFromBuffer(header + 265, 32, encoding) copy];
			_groupOwnerAccountName = [stringFromBuffer(header + 297,
			    32, encoding) copy];

			_deviceMajor = (unsigned long)octalValueFromBuffer(
			    header + 329, 8, ULONG_MAX);
			_deviceMinor = (unsigned long)octalValueFromBuffer(
			    header + 337, 8, ULONG_MAX);

			prefix = stringFromBuffer(header + 345, 155, encoding);
			if (prefix.length > 0) {
				OFString *fileName = [OFString
				    stringWithFormat: @"%@/%@",
						      prefix, _fileName];
				objc_release(_fileName);
				_fileName = [fileName copy];
			}
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
	objc_release(_POSIXPermissions);
	objc_release(_ownerAccountID);
	objc_release(_groupOwnerAccountID);
	objc_release(_modificationDate);
	objc_release(_targetFileName);
	objc_release(_ownerAccountName);
	objc_release(_groupOwnerAccountName);

	[super dealloc];
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	OFTarArchiveEntry *copy = [[OFMutableTarArchiveEntry alloc]
	    initWithFileName: _fileName];

	@try {
		copy->_POSIXPermissions = objc_retain(_POSIXPermissions);
		copy->_ownerAccountID = objc_retain(_ownerAccountID);
		copy->_groupOwnerAccountID = objc_retain(_groupOwnerAccountID);
		copy->_compressedSize = _compressedSize;
		copy->_uncompressedSize = _uncompressedSize;
		copy->_modificationDate = [_modificationDate copy];
		copy->_type = _type;
		copy->_targetFileName = [_targetFileName copy];
		copy->_ownerAccountName = [_ownerAccountName copy];
		copy->_groupOwnerAccountName = [_groupOwnerAccountName copy];
		copy->_deviceMajor = _deviceMajor;
		copy->_deviceMinor = _deviceMinor;
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

- (OFTarArchiveEntryType)type
{
	return _type;
}

- (OFString *)targetFileName
{
	return _targetFileName;
}

- (OFString *)ownerAccountName
{
	return _ownerAccountName;
}

- (OFString *)groupOwnerAccountName
{
	return _groupOwnerAccountName;
}

- (unsigned long)deviceMajor
{
	return _deviceMajor;
}

- (unsigned long)deviceMinor
{
	return _deviceMinor;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *POSIXPermissions = nil, *ret;

	if (_POSIXPermissions != nil)
		POSIXPermissions = [OFString stringWithFormat: @"%ho",
		    _POSIXPermissions.unsignedShortValue];

	ret = [OFString stringWithFormat: @"<%@:\n"
	     @"\tFile name = %@\n"
	     @"\tPOSIX permissions = %@\n"
	     @"\tOwner account ID = %@\n"
	     @"\tGroup owner account ID = %@\n"
	     @"\tCompressed size = %llu\n"
	     @"\tUncompressed size = %llu\n"
	     @"\tModification date = %@\n"
	     @"\tType = %u\n"
	     @"\tTarget file name = %@\n"
	     @"\tOwner account name = %@\n"
	     @"\tGroup owner account name = %@\n"
	     @"\tDevice major = %" PRIu32 @"\n"
	     @"\tDevice minor = %" PRIu32 @"\n"
	     @">",
	    self.class, _fileName, POSIXPermissions, _ownerAccountID,
	    _groupOwnerAccountID, _compressedSize, _uncompressedSize,
	    _modificationDate, _type, _targetFileName,
	    _ownerAccountName, _groupOwnerAccountName, _deviceMajor,
	    _deviceMinor];

	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (void)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	unsigned char buffer[512];
	unsigned long long modificationDate;
	uint16_t checksum = 0;

	stringToBuffer(buffer, _fileName, 100, encoding);
	stringToBuffer(buffer + 100,
	    [OFString stringWithFormat: @"%06o ",
	    _POSIXPermissions.unsignedShortValue], 8, OFStringEncodingASCII);
	stringToBuffer(buffer + 108,
	    [OFString stringWithFormat: @"%06o ",
	    _ownerAccountID.unsignedShortValue], 8, OFStringEncodingASCII);
	stringToBuffer(buffer + 116,
	    [OFString stringWithFormat: @"%06o ",
	    _groupOwnerAccountID.unsignedShortValue], 8, OFStringEncodingASCII);
	stringToBuffer(buffer + 124,
	    [OFString stringWithFormat: @"%011llo ", _uncompressedSize], 12,
	    OFStringEncodingASCII);
	modificationDate = _modificationDate.timeIntervalSince1970;
	stringToBuffer(buffer + 136,
	    [OFString stringWithFormat: @"%011llo", modificationDate],
	    12, OFStringEncodingASCII);

	/*
	 * During checksumming, the checksum field is expected to be set to 8
	 * spaces.
	 */
	memset(buffer + 148, ' ', 8);

	buffer[156] = _type;
	stringToBuffer(buffer + 157, _targetFileName, 100, encoding);

	/* ustar */
	memcpy(buffer + 257, "ustar\0" "00", 8);
	stringToBuffer(buffer + 265, _ownerAccountName, 32, encoding);
	stringToBuffer(buffer + 297, _groupOwnerAccountName, 32, encoding);
	stringToBuffer(buffer + 329,
	    [OFString stringWithFormat: @"%06" PRIo32 " ", _deviceMajor], 8,
	    OFStringEncodingASCII);
	stringToBuffer(buffer + 337,
	    [OFString stringWithFormat: @"%06" PRIo32 " ", _deviceMinor], 8,
	    OFStringEncodingASCII);
	memset(buffer + 345, '\0', 155 + 12);

	/* Fill in the checksum */
	for (size_t i = 0; i < 500; i++)
		checksum += buffer[i];
	stringToBuffer(buffer + 148,
	    [OFString stringWithFormat: @"%06" PRIo16, checksum], 7,
	    OFStringEncodingASCII);

	[stream writeBuffer: buffer length: sizeof(buffer)];

	objc_autoreleasePoolPop(pool);
}
@end
