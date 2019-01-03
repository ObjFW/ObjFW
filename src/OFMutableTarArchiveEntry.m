/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFMutableTarArchiveEntry.h"
#import "OFString.h"
#import "OFDate.h"

@implementation OFMutableTarArchiveEntry
@dynamic fileName, mode, UID, GID, size, modificationDate, type, targetFileName;
@dynamic owner, group, deviceMajor, deviceMinor;

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

- (void)setMode: (uint32_t)mode
{
	_mode = mode;
}

- (void)setUID: (uint32_t)UID
{
	_UID = UID;
}

- (void)setGID: (uint32_t)GID
{
	_GID = GID;
}

- (void)setSize: (uint64_t)size
{
	_size = size;
}

- (void)setModificationDate: (OFDate *)modificationDate
{
	OFDate *old = _modificationDate;
	_modificationDate = [modificationDate retain];
	[old release];
}

- (void)setType: (of_tar_archive_entry_type_t)type
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

- (void)setDeviceMajor: (uint32_t)deviceMajor
{
	_deviceMajor = deviceMajor;
}

- (void)setDeviceMinor: (uint32_t)deviceMinor
{
	_deviceMinor = deviceMinor;
}

- (void)makeImmutable
{
	object_setClass(self, [OFTarArchiveEntry class]);
}
@end
