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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFDate;
@class OFNumber;

/**
 * @brief The file type of an archive entry.
 *
 * Values between 0 and 0xFF are Tar file types. Types not representable by Tar
 * files therefore use values > 0xFF.
 */
typedef enum {
	/** Regular file. */
	OFArchiveEntryFileTypeRegular                 = '0',
	/** Hard link. */
	OFArchiveEntryFileTypeLink                    = '1',
	/** Symbolic link. */
	OFArchiveEntryFileTypeSymbolicLink            = '2',
	/** Character device. */
	OFArchiveEntryFileTypeCharacterDevice         = '3',
	/** Block device. */
	OFArchiveEntryFileTypeBlockDevice             = '4',
	/** Directory. */
	OFArchiveEntryFileTypeDirectory               = '5',
	/** FIFO. */
	OFArchiveEntryFileTypeFIFO                    = '6',
	/** Contiguous file */
	OFArchiveEntryFileTypeContiguousFile          = '7',
	/** PAX global extended header. */
	OFArchiveEntryFileTypePAXGlobalExtendedHeader = 'g',
	/** PAX extended header. */
	OFArchiveEntryFileTypePAXExtendedHeader       = 'x',
	/** Unknown. The implementation most likely cannot handle this entry. */
	OFArchiveEntryFileTypeUnknown                 = 0x100,
} OFArchiveEntryFileType;

/**
 * @protocol OFArchiveEntry OFArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents an entry in an archive.
 */
@protocol OFArchiveEntry <OFObject>

/**
 * @brief The file name of the entry.
 */
@property (readonly, copy, nonatomic) OFString *fileName;

/**
 * @brief The file type of the entry.
 */
@property (readonly, nonatomic) OFArchiveEntryFileType fileType;

/**
 * @brief The compressed size of the entry's file.
 */
@property (readonly, nonatomic) unsigned long long compressedSize;

/**
 * @brief The uncompressed size of the entry's file.
 */
@property (readonly, nonatomic) unsigned long long uncompressedSize;

@optional
/**
 * @brief The modification date of the file.
 */
@property (readonly, retain, nonatomic) OFDate *modificationDate;

/**
 * @brief The comment of the entry's file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *fileComment;

/**
 * @brief The POSIX permissions of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFNumber *POSIXPermissions;

/**
 * @brief The file owner's account ID.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFNumber *ownerAccountID;

/**
 * @brief The file owner's group account ID.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFNumber *groupOwnerAccountID;

/**
 * @brief The file owner's account name.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFString *ownerAccountName;

/**
 * @brief The file owner's group account name.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFString *groupOwnerAccountName;

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
@end

OF_ASSUME_NONNULL_END

#import "OFMutableArchiveEntry.h"
