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
 * @class OFTarArchiveEntry OFTarArchiveEntry.h ObjFW/OFTarArchiveEntry.h
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
