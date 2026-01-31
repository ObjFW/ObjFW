/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFMutableArchiveEntry OFArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents a mutable entry in an archive.
 */
@protocol OFMutableArchiveEntry <OFArchiveEntry>

/**
 * @brief The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/**
 * @brief The file type of the entry.
 */
@property (readwrite, nonatomic) OFArchiveEntryFileType fileType;

/**
 * @brief The compressed size of the entry's file.
 */
@property (readwrite, nonatomic) unsigned long long compressedSize;

/**
 * @brief The uncompressed size of the entry's file.
 */
@property (readwrite, nonatomic) unsigned long long uncompressedSize;

@optional
/**
 * @brief The modification date of the file.
 */
@property (readwrite, retain, nonatomic) OFDate *modificationDate;

/**
 * @brief The comment of the entry's file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *fileComment;

/**
 * @brief The POSIX permissions of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFNumber *POSIXPermissions;

/**
 * @brief The file owner's account ID.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFNumber *ownerAccountID;

/**
 * @brief The file owner's group account ID.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFNumber *groupOwnerAccountID;

/**
 * @brief The file owner's account name.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFString *ownerAccountName;

/**
 * @brief The file owner's group account name.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFString *groupOwnerAccountName;

/**
 * @brief The file name of the target (for a hard link or symbolic link).
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *targetFileName;

/**
 * @brief The device major (if the file is a device).
 */
@property (readwrite, nonatomic) unsigned long deviceMajor;

/**
 * @brief The device major (if the file is a device).
 */
@property (readwrite, nonatomic) unsigned long deviceMinor;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableArchiveEntry.h"
