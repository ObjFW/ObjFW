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

#import "OFMutableZooArchiveEntry.h"
#import "OFZooArchiveEntry+Private.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFString.h"

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
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [super of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		self.fileName = fileName;
		self.modificationDate = [OFDate date];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
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
	[old release];
}

- (void)setFileName: (OFString *)fileName
{
	void *pool = objc_autoreleasePoolPush();
	OFString *oldFileName = _fileName, *oldDirectoryName = _directoryName;
	size_t lastSlash;

	lastSlash = [fileName rangeOfString: @"/"
				    options: OFStringSearchBackwards].location;
	if (lastSlash != OFNotFound) {
		_fileName = [[fileName substringWithRange: OFMakeRange(
		    lastSlash + 1, fileName.length - lastSlash - 1)] copy];
		[oldFileName release];

		_directoryName = [[fileName substringWithRange:
		    OFMakeRange(0, lastSlash)] copy];
		[oldDirectoryName release];
	} else {
		_fileName = [fileName copy];
		[oldFileName release];

		[_directoryName release];
		_directoryName = nil;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setOperatingSystemIdentifier: (uint16_t)operatingSystemIdentifier
{
	_operatingSystemIdentifier = operatingSystemIdentifier;
}

- (void)setPOSIXPermissions: (OFNumber *)POSIXPermissions
{
	OFNumber *old = _POSIXPermissions;
	_POSIXPermissions = [POSIXPermissions copy];
	[old release];
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
