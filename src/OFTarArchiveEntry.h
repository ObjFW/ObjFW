/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFDate;
@class OFNumber;

/**
 * @brief The type of the archive entry.
 */
typedef enum {
	/** Normal file */
	OFTarArchiveEntryTypeFile	     = '0',
	/** Hard link */
	OFTarArchiveEntryTypeLink	     = '1',
	/** Symbolic link */
	OFTarArchiveEntryTypeSymlink	     = '2',
	/** Character device */
	OFTarArchiveEntryTypeCharacterDevice = '3',
	/** Block device */
	OFTarArchiveEntryTypeBlockDevice     = '4',
	/** Directory */
	OFTarArchiveEntryTypeDirectory	     = '5',
	/** FIFO */
	OFTarArchiveEntryTypeFIFO	     = '6',
	/** Contiguous file */
	OFTarArchiveEntryTypeContiguousFile  = '7',
} OFTarArchiveEntryType;

/**
 * @class OFTarArchiveEntry OFTarArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents an entry of a tar archive.
 */
@interface OFTarArchiveEntry: OFObject <OFArchiveEntry, OFCopying,
    OFMutableCopying>
{
	OFString *_fileName;
	OFNumber *_POSIXPermissions, *_ownerAccountID, *_groupOwnerAccountID;
	unsigned long long _compressedSize, _uncompressedSize;
	OFDate *_modificationDate;
	OFTarArchiveEntryType _type;
	OFString *_Nullable _targetFileName;
	OFString *_Nullable _ownerAccountName;
	OFString *_Nullable _groupOwnerAccountName;
	unsigned long _deviceMajor, _deviceMinor;
	OF_RESERVE_IVARS(OFTarArchiveEntry, 4)
}

/**
 * @brief The type of the archive entry.
 *
 * See @ref OFTarArchiveEntryType.
 */
@property (readonly, nonatomic) OFTarArchiveEntryType type;

/**
 * @brief The file name of the target (for a hard link or symbolic link).
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *targetFileName;

/**
 * @brief The device major (if the file is a device).
 */
@property (readonly, nonatomic) unsigned long deviceMajor;

/**
 * @brief The device major (if the file is a device).
 */
@property (readonly, nonatomic) unsigned long deviceMinor;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableTarArchiveEntry.h"
