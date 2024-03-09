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

#import "OFMutableZIPArchiveEntry.h"
#import "OFZIPArchiveEntry+Private.h"
#import "OFString.h"
#import "OFData.h"
#import "OFDate.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableZIPArchiveEntry
@dynamic fileName, fileComment, extraField, versionMadeBy, minVersionNeeded;
@dynamic modificationDate, compressionMethod, compressedSize, uncompressedSize;
@dynamic CRC32, versionSpecificAttributes, generalPurposeBitFlag;
@dynamic of_startDiskNumber, of_localFileHeaderOffset;
/*
 * The following are optional in OFMutableArchiveEntry, but Apple GCC 4.0.1 is
 * buggy and needs this to stop complaining.
 */
@dynamic POSIXPermissions, ownerAccountID, groupOwnerAccountID;
@dynamic ownerAccountName, groupOwnerAccountName;

+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [super of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (fileName.UTF8StringLength > UINT16_MAX)
			@throw [OFOutOfRangeException exception];

		_fileName = [fileName copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (id)copy
{
	OFMutableZIPArchiveEntry *copy = [self mutableCopy];
	[copy makeImmutable];
	return copy;
}

- (void)setFileName: (OFString *)fileName
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old;

	if (fileName.UTF8StringLength > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	old = _fileName;
	_fileName = [fileName copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setFileComment: (OFString *)fileComment
{
	void *pool = objc_autoreleasePoolPush();
	OFString *old;

	if (fileComment.UTF8StringLength > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	old = _fileComment;
	_fileComment = [fileComment copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setExtraField: (OFData *)extraField
{
	void *pool = objc_autoreleasePoolPush();
	OFData *old;

	if (extraField.itemSize != 1)
		@throw [OFInvalidArgumentException exception];

	if (extraField.count > UINT16_MAX)
		@throw [OFOutOfRangeException exception];

	old = _extraField;
	_extraField = [extraField copy];
	[old release];

	objc_autoreleasePoolPop(pool);
}

- (void)setVersionMadeBy:
    (OFZIPArchiveEntryAttributeCompatibility)versionMadeBy
{
	_versionMadeBy = versionMadeBy;
}

- (void)setMinVersionNeeded:
    (OFZIPArchiveEntryAttributeCompatibility)minVersionNeeded
{
	_minVersionNeeded = minVersionNeeded;
}

- (void)setModificationDate: (OFDate *)date
{
	void *pool = objc_autoreleasePoolPush();

	_lastModifiedFileDate = (((date.localYear - 1980) & 0xFF) << 9) |
	    ((date.localMonthOfYear & 0x0F) << 5) |
	    (date.localDayOfMonth & 0x1F);
	_lastModifiedFileTime = ((date.localHour & 0x1F) << 11) |
	    ((date.localMinute & 0x3F) << 5) | ((date.second >> 1) & 0x0F);

	objc_autoreleasePoolPop(pool);
}

- (void)setCompressionMethod:
    (OFZIPArchiveEntryCompressionMethod)compressionMethod
{
	_compressionMethod = compressionMethod;
}

- (void)setCompressedSize: (unsigned long long)compressedSize
{
	_compressedSize = compressedSize;
}

- (void)setUncompressedSize: (unsigned long long)uncompressedSize
{
	_uncompressedSize = uncompressedSize;
}

- (void)setCRC32: (uint32_t)CRC32
{
	_CRC32 = CRC32;
}

- (void)setVersionSpecificAttributes: (uint32_t)versionSpecificAttributes
{
	_versionSpecificAttributes = versionSpecificAttributes;
}

- (void)setGeneralPurposeBitFlag: (uint16_t)generalPurposeBitFlag
{
	_generalPurposeBitFlag = generalPurposeBitFlag;
}

- (void)of_setStartDiskNumber: (uint32_t)startDiskNumber
{
	_startDiskNumber = startDiskNumber;
}

- (void)of_setLocalFileHeaderOffset: (int64_t)localFileHeaderOffset
{
	if (localFileHeaderOffset < 0)
		@throw [OFInvalidArgumentException exception];

	_localFileHeaderOffset = localFileHeaderOffset;
}

- (void)makeImmutable
{
	object_setClass(self, [OFZIPArchiveEntry class]);
}
@end
