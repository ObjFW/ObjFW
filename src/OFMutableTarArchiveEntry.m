/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFString.h"
#import "OFDate.h"

@implementation OFMutableTarArchiveEntry
@dynamic fileName, mode, UID, GID, compressedSize, uncompressedSize;
@dynamic modificationDate, type, targetFileName, owner, group, deviceMajor;
@dynamic deviceMinor;

+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- (instancetype)initWithFileName: (OFString *)fileName
{
	self = [super of_init];

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
	OFMutableTarArchiveEntry *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)setFileName: (OFString *)fileName
{
	OFString *old = _fileName;
	_fileName = [fileName copy];
	[old release];
}

- (void)setMode: (unsigned long)mode
{
	_mode = mode;
}

- (void)setUID: (unsigned long)UID
{
	_UID = UID;
}

- (void)setGID: (unsigned long)GID
{
	_GID = GID;
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

- (void)setType: (OFTarArchiveEntryType)type
{
	_type = type;
}

- (void)setTargetFileName: (OFString *)targetFileName
{
	OFString *old = _targetFileName;
	_targetFileName = [targetFileName copy];
	[old release];
}

- (void)setOwner: (OFString *)owner
{
	OFString *old = _owner;
	_owner = [owner copy];
	[old release];
}

- (void)setGroup: (OFString *)group
{
	OFString *old = _group;
	_group = [group copy];
	[old release];
}

- (void)setDeviceMajor: (unsigned long)deviceMajor
{
	_deviceMajor = deviceMajor;
}

- (void)setDeviceMinor: (unsigned long)deviceMinor
{
	_deviceMinor = deviceMinor;
}

- (void)makeImmutable
{
	object_setClass(self, [OFTarArchiveEntry class]);
}
@end
