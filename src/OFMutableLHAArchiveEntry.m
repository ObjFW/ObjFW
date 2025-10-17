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

#import "OFMutableLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFMutableLHAArchiveEntry
@dynamic fileName, fileType, compressionMethod, compressedSize;
@dynamic uncompressedSize, modificationDate, headerLevel, CRC16;
@dynamic operatingSystemIdentifier, fileComment, POSIXPermissions;
@dynamic ownerAccountID, groupOwnerAccountID, ownerAccountName;
@dynamic groupOwnerAccountName, MSDOSAttributes, amigaComment, extensions;
/*
 * The following are optional in OFMutableArchiveEntry, but Apple GCC 4.0.1 is
 * buggy and needs this to stop complaining.
 */
@dynamic targetFileName, deviceMajor, deviceMinor;

+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithFileName: fileName]);
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [self of_init];

	@try {
		_fileName = [fileName copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (id)copy
{
	OFMutableLHAArchiveEntry *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)setFileName: (OFString *)fileName
{
	OFString *old = _fileName;
	_fileName = [fileName copy];
	objc_release(old);

	objc_release(_directoryName);
	_directoryName = nil;
}

- (void)setFileType: (OFArchiveEntryFileType)fileType
{
	switch (fileType) {
	case OFArchiveEntryFileTypeDirectory:
		if (![_fileName hasSuffix: @"/"]) {
			void *pool = objc_autoreleasePoolPush();
			self.fileName =
			    [self.fileName stringByAppendingString: @"/"];
			objc_autoreleasePoolPop(pool);
		}
		break;
	case OFArchiveEntryFileTypeRegular:
		if ([_fileName hasSuffix: @"/"]) {
			void *pool = objc_autoreleasePoolPush();
			OFString *fileName = self.fileName;
			fileName =
			    [fileName substringToIndex: fileName.length - 1];
			self.fileName = fileName;
			objc_autoreleasePoolPop(pool);
		}
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

- (void)setCompressionMethod: (OFString *)compressionMethod
{
	OFString *old = _compressionMethod;
	_compressionMethod = [compressionMethod copy];
	objc_release(old);
}

- (void)setCompressedSize: (unsigned long long)compressedSize
{
	_compressedSize = compressedSize;
}

- (void)setUncompressedSize: (unsigned long long)uncompressedSize
{
	_uncompressedSize = uncompressedSize;
}

- (void)setModificationDate: (OFDate *)modificationDate
{
	OFDate *old = _modificationDate;
	_modificationDate = objc_retain(modificationDate);
	objc_release(old);
}

- (void)setHeaderLevel: (uint8_t)headerLevel
{
	_headerLevel = headerLevel;
}

- (void)setCRC16: (uint16_t)CRC16
{
	_CRC16 = CRC16;
}

- (void)setOperatingSystemIdentifier: (uint8_t)operatingSystemIdentifier
{
	_operatingSystemIdentifier = operatingSystemIdentifier;
}

- (void)setFileComment: (OFString *)fileComment
{
	OFString *old = _fileComment;
	_fileComment = [fileComment copy];
	objc_release(old);
}

- (void)setPOSIXPermissions: (OFNumber *)POSIXPermissions
{
	OFNumber *old = _POSIXPermissions;
	_POSIXPermissions = objc_retain(POSIXPermissions);
	objc_release(old);
}

- (void)setOwnerAccountID: (OFNumber *)ownerAccountID
{
	OFNumber *old = _ownerAccountID;
	_ownerAccountID = objc_retain(ownerAccountID);
	objc_release(old);
}

- (void)setGroupOwnerAccountID: (OFNumber *)groupOwnerAccountID
{
	OFNumber *old = _groupOwnerAccountID;
	_groupOwnerAccountID = objc_retain(groupOwnerAccountID);
	objc_release(old);
}

- (void)setOwnerAccountName: (OFString *)ownerAccountName
{
	OFString *old = _ownerAccountName;
	_ownerAccountName = [ownerAccountName copy];
	objc_release(old);
}

- (void)setGroupOwnerAccountName: (OFString *)groupOwnerAccountName
{
	OFString *old = _groupOwnerAccountName;
	_groupOwnerAccountName = [groupOwnerAccountName copy];
	objc_release(old);
}

- (void)setMSDOSAttributes: (OFNumber *)MSDOSAttributes
{
	OFNumber *old = _MSDOSAttributes;
	_MSDOSAttributes = objc_retain(MSDOSAttributes);
	objc_release(old);
}

- (void)setAmigaComment: (OFString *)amigaComment
{
	OFString *old = _amigaComment;
	_amigaComment = [amigaComment copy];
	objc_release(old);
}

- (void)setExtensions: (OFArray OF_GENERIC(OFData *) *)extensions
{
	OFArray OF_GENERIC(OFData *) *old = _extensions;
	_extensions = [extensions copy];
	objc_release(old);
}

- (void)makeImmutable
{
	object_setClass(self, [OFLHAArchiveEntry class]);
}
@end
