/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFDate;

/**
 * @brief The type of the archive entry.
 */
typedef enum of_tar_archive_entry_type_t {
	/** Normal file */
	OF_TAR_ARCHIVE_ENTRY_TYPE_FILE		   = '0',
	/** Hard link */
	OF_TAR_ARCHIVE_ENTRY_TYPE_LINK		   = '1',
	/** Symbolic link */
	OF_TAR_ARCHIVE_ENTRY_TYPE_SYMLINK	   = '2',
	/** Character device */
	OF_TAR_ARCHIVE_ENTRY_TYPE_CHARACTER_DEVICE = '3',
	/** Block device */
	OF_TAR_ARCHIVE_ENTRY_TYPE_BLOCK_DEVICE	   = '4',
	/** Directory */
	OF_TAR_ARCHIVE_ENTRY_TYPE_DIRECTORY	   = '5',
	/** FIFO */
	OF_TAR_ARCHIVE_ENTRY_TYPE_FIFO		   = '6',
	/** Contiguous file */
	OF_TAR_ARCHIVE_ENTRY_TYPE_CONTIGUOUS_FILE  = '7',
} of_tar_archive_entry_type_t;

/**
 * @class OFTarArchiveEntry OFTarArchiveEntry.h ObjFW/OFTarArchiveEntry.h
 *
 * @brief A class which represents an entry of a tar archive.
 */
@interface OFTarArchiveEntry: OFObject <OFCopying, OFMutableCopying>
{
	OFString *_fileName;
	unsigned long _mode;
	unsigned long long _size;
	unsigned long _UID, _GID;
	OFDate *_modificationDate;
	of_tar_archive_entry_type_t _type;
	OFString *_Nullable _targetFileName;
	OFString *_Nullable _owner, *_Nullable _group;
	unsigned long _deviceMajor, _deviceMinor;
	OF_RESERVE_IVARS(OFTarArchiveEntry, 4)
}

/**
 * @brief The file name of the entry.
 */
@property (readonly, copy, nonatomic) OFString *fileName;

/**
 * @brief The mode of the entry.
 */
@property (readonly, nonatomic) unsigned long mode;

/**
 * @brief The UID of the owner.
 */
@property (readonly, nonatomic) unsigned long UID;

/**
 * @brief The GID of the group.
 */
@property (readonly, nonatomic) unsigned long GID;

/**
 * @brief The size of the file.
 */
@property (readonly, nonatomic) unsigned long long size;

/**
 * @brief The date of the last modification of the file.
 */
@property (readonly, retain, nonatomic) OFDate *modificationDate;

/**
 * @brief The type of the archive entry.
 *
 * See @ref of_tar_archive_entry_type_t.
 */
@property (readonly, nonatomic) of_tar_archive_entry_type_t type;

/**
 * @brief The file name of the target (for a hard link or symbolic link).
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *targetFileName;

/**
 * @brief The owner of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *owner;

/**
 * @brief The group of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *group;

/**
 * @brief The device major (if the file is a device).
 */
@property (readonly, nonatomic) unsigned long deviceMajor;

/**
 * @brief The device major (if the file is a device).
 */
@property (readonly, nonatomic) unsigned long deviceMinor;

/**
 * @brief Creates a new OFTarArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFTarArchiveEntry
 * @return A new, autoreleased OFTarArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFTarArchiveEntry with the specified
 *	  file name.
 *
 * @param fileName The file name for the OFTarArchiveEntry
 * @return An initialized OFTarArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableTarArchiveEntry.h"
