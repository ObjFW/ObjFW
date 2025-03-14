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

@implementation OFMutableLHAArchiveEntry
@dynamic fileName, compressionMethod, compressedSize, uncompressedSize;
@dynamic modificationDate, headerLevel, CRC16, operatingSystemIdentifier;
@dynamic fileComment, POSIXPermissions, ownerAccountID, groupOwnerAccountID;
@dynamic ownerAccountName, groupOwnerAccountName, extensions;

+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [self of_init];

	@try {
		_fileName = [fileName copy];
	} @catch (id e) {
		[self release];
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
	[old release];

	[_directoryName release];
	_directoryName = nil;
}

- (void)setCompressionMethod: (OFString *)compressionMethod
{
	OFString *old = _compressionMethod;
	_compressionMethod = [compressionMethod copy];
	[old release];
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
	_modificationDate = [modificationDate retain];
	[old release];
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
	[old release];
}

- (void)setPOSIXPermissions: (OFNumber *)POSIXPermissions
{
	OFNumber *old = _POSIXPermissions;
	_POSIXPermissions = [POSIXPermissions retain];
	[old release];
}

- (void)setOwnerAccountID: (OFNumber *)ownerAccountID
{
	OFNumber *old = _ownerAccountID;
	_ownerAccountID = [ownerAccountID retain];
	[old release];
}

- (void)setGroupOwnerAccountID: (OFNumber *)groupOwnerAccountID
{
	OFNumber *old = _groupOwnerAccountID;
	_groupOwnerAccountID = [groupOwnerAccountID retain];
	[old release];
}

- (void)setOwnerAccountName: (OFString *)ownerAccountName
{
	OFString *old = _ownerAccountName;
	_ownerAccountName = [ownerAccountName copy];
	[old release];
}

- (void)setGroupOwnerAccountName: (OFString *)groupOwnerAccountName
{
	OFString *old = _groupOwnerAccountName;
	_groupOwnerAccountName = [groupOwnerAccountName copy];
	[old release];
}

- (void)setExtensions: (OFArray OF_GENERIC(OFData *) *)extensions
{
	OFArray OF_GENERIC(OFData *) *old = _extensions;
	_extensions = [extensions copy];
	[old release];
}

- (void)makeImmutable
{
	object_setClass(self, [OFLHAArchiveEntry class]);
}
@end
