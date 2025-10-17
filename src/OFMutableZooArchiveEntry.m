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

#import "OFMutableZooArchiveEntry.h"
#import "OFZooArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFMutableZooArchiveEntry
@dynamic headerType, compressionMethod, modificationDate, CRC16;
@dynamic uncompressedSize, compressedSize, minVersionNeeded, deleted;
@dynamic fileComment, fileName, operatingSystemIdentifier, POSIXPermissions;
@dynamic timeZone;
/*
 * The following properties are not implemented, but old Apple GCC requries
 * @dynamic for @optional properties.
 */
@dynamic ownerAccountID, groupOwnerAccountID, ownerAccountName;
@dynamic groupOwnerAccountName;

+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithFileName: fileName]);
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [self of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		self.fileName = fileName;
		self.modificationDate = [OFDate date];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (id)copy
{
	OFMutableZooArchiveEntry *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)setHeaderType: (uint8_t)headerType
{
	_headerType = headerType;
}

- (void)setCompressionMethod: (uint8_t)compressionMethod
{
	_compressionMethod = compressionMethod;
}

- (void)setModificationDate: (OFDate *)date
{
	void *pool = objc_autoreleasePoolPush();

	if (_timeZone == 0x7F) {
		_lastModifiedFileDate =
		    (((date.localYear - 1980) & 0xFF) << 9) |
		    ((date.localMonthOfYear & 0x0F) << 5) |
		    (date.localDayOfMonth & 0x1F);
		_lastModifiedFileTime = ((date.localHour & 0x1F) << 11) |
		    ((date.localMinute & 0x3F) << 5) |
		    ((date.second >> 1) & 0x0F);
	} else {
		date = [date dateByAddingTimeInterval:
		    -(OFTimeInterval)_timeZone * 900];

		_lastModifiedFileDate = (((date.year - 1980) & 0xFF) << 9) |
		    ((date.monthOfYear & 0x0F) << 5) | (date.dayOfMonth & 0x1F);
		_lastModifiedFileTime = ((date.hour & 0x1F) << 11) |
		    ((date.minute & 0x3F) << 5) | ((date.second >> 1) & 0x0F);
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setCRC16: (uint16_t)CRC16
{
	_CRC16 = CRC16;
}

- (void)setUncompressedSize: (unsigned long long)uncompressedSize
{
	_uncompressedSize = uncompressedSize;
}

- (void)setCompressedSize: (unsigned long long)compressedSize
{
	_compressedSize = compressedSize;
}

- (void)setMinVersionNeeded: (uint16_t)minVersionNeeded
{
	_minVersionNeeded = minVersionNeeded;
}

- (void)setDeleted: (bool)deleted
{
	_deleted = deleted;
}

- (void)setFileComment: (OFString *)fileComment
{
	OFString *old = _fileComment;
	_fileComment = [fileComment copy];
	objc_release(old);
}

- (void)setFileName: (OFString *)fileName
{
	void *pool = objc_autoreleasePoolPush();
	OFString *oldFileName = _fileName, *oldDirectoryName = _directoryName;
	size_t lastSlash;

	lastSlash = [fileName rangeOfString: @"/"
				    options: OFStringSearchBackwards].location;
	if (lastSlash != OFNotFound) {
		_fileName = [[fileName substringFromIndex: lastSlash + 1] copy];
		objc_release(oldFileName);

		_directoryName = [[fileName substringToIndex: lastSlash] copy];
		objc_release(oldDirectoryName);
	} else {
		_fileName = [fileName copy];
		objc_release(oldFileName);

		objc_release(_directoryName);
		_directoryName = nil;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setFileType: (OFArchiveEntryFileType)fileType
{
	if (fileType != OFArchiveEntryFileTypeRegular)
		@throw [OFInvalidArgumentException exception];
}

- (void)setOperatingSystemIdentifier: (uint16_t)operatingSystemIdentifier
{
	_operatingSystemIdentifier = operatingSystemIdentifier;
}

- (void)setPOSIXPermissions: (OFNumber *)POSIXPermissions
{
	OFNumber *old = _POSIXPermissions;
	_POSIXPermissions = [POSIXPermissions copy];
	objc_release(old);
}

- (void)setTimeZone: (OFNumber *)timeZone
{
	if (timeZone == nil)
		_timeZone = 0x7F;
	else
		_timeZone = -timeZone.floatValue * 4;
}

- (void)makeImmutable
{
	object_setClass(self, [OFZooArchiveEntry class]);
}
@end
