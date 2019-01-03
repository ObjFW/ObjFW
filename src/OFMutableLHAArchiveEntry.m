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

#import "OFMutableLHAArchiveEntry.h"

#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFNumber.h"
#import "OFString.h"

@implementation OFMutableLHAArchiveEntry
@dynamic fileName, compressionMethod, compressedSize, uncompressedSize, date;
@dynamic headerLevel, CRC16, operatingSystemIdentifier, fileComment, mode, UID;
@dynamic GID, owner, group, modificationDate, extensions;

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

- (void)setCompressedSize: (uint32_t)compressedSize
{
	_compressedSize = compressedSize;
}

- (void)setUncompressedSize: (uint32_t)uncompressedSize
{
	_uncompressedSize = uncompressedSize;
}

- (void)setDate: (OFDate *)date
{
	OFDate *old = _date;
	_date = [date retain];
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

- (void)setMode: (OFNumber *)mode
{
	OFNumber *old = _mode;
	_mode = [mode retain];
	[old release];
}

- (void)setUID: (OFNumber *)UID
{
	OFNumber *old = _UID;
	_UID = [UID retain];
	[old release];
}

- (void)setGID: (OFNumber *)GID
{
	OFNumber *old = _GID;
	_GID = [GID retain];
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

- (void)setModificationDate: (OFDate *)modificationDate
{
	OFDate *old = _modificationDate;
	_modificationDate = [modificationDate retain];
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
