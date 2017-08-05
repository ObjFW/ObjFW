/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFMutableZIPArchiveEntry.h"
#import "OFString.h"
#import "OFData.h"
#import "OFDate.h"

@implementation OFMutableZIPArchiveEntry
@dynamic fileName, fileComment, extraField, versionMadeBy, minVersionNeeded;
@dynamic modificationDate, compressionMethod, compressedSize, uncompressedSize;
@dynamic CRC32, versionSpecificAttributes, generalPurposeBitFlag;

- copy
{
	OFMutableZIPArchiveEntry *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)setFileName: (OFString *)fileName
{
	OFString *old = _fileName;
	_fileName = [fileName copy];
	[old release];
}

- (void)setFileComment: (OFString *)fileComment
{
	OFString *old = _fileComment;
	_fileComment = [fileComment copy];
	[old release];
}

- (void)setExtraField: (OFData *)extraField
{
	OFData *old = _extraField;
	_extraField = [extraField copy];
	[old release];
}

- (void)setVersionMadeBy: (uint16_t)versionMadeBy
{
	_versionMadeBy = versionMadeBy;
}

- (void)setMinVersionNeeded: (uint16_t)minVersionNeeded
{
	_minVersionNeeded = minVersionNeeded;
}

- (void)setModificationDate: (OFDate *)date
{
	void *pool = objc_autoreleasePoolPush();

	_lastModifiedFileDate = ((([date localYear] - 1980) & 0xFF) << 9) |
	    (([date localMonthOfYear] & 0x0F) << 5) |
	    ([date localDayOfMonth] & 0x1F);
	_lastModifiedFileTime = (([date localHour] & 0x1F) << 11) |
	    (([date localMinute] & 0x3F) << 5) | (([date second] >> 1) & 0x0F);

	objc_autoreleasePoolPop(pool);
}

- (void)setCompressionMethod: (uint16_t)compressionMethod
{
	_compressionMethod = compressionMethod;
}

- (void)setCompressedSize: (uint64_t)compressedSize
{
	_compressedSize = compressedSize;
}

- (void)setUncompressedSize: (uint64_t)uncompressedSize
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

- (void)makeImmutable
{
	object_setClass(self, [OFZIPArchiveEntry class]);
}
@end
