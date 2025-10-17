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

#import "OFObject.h"
#import "OFArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFDate;
@class OFNumber;

/**
 * @brief The type of the archive entry.
 *
 * @deprecated Use @ref OFArchiveEntryFileType instead.
 */
typedef OFArchiveEntryFileType OFTarArchiveEntryType
    OF_DEPRECATED(ObjFW, 1, 5, "Use OFArchiveEntryFileType instead");

enum {
	/**
	 * @brief Normal file.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeRegular instead.
	 */
	OFTarArchiveEntryTypeFile OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveFileEntryTypeRegular instead") = '0',

	/**
	 * @brief Hard link.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeLink instead.
	 */
	OFTarArchiveEntryTypeLink OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeLink instead") = '1',

	/**
	 * @brief Symbolic link.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeSymbolicLink instead.
	 */
	OFTarArchiveEntryTypeSymlink OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeSymbolicLink instead") = '2',

	/**
	 * @brief Character device.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeCharacterDevice instead.
	 */
	OFTarArchiveEntryTypeCharacterDevice OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeCharacterDevice instead") = '3',

	/**
	 * @brief Block device.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeBlockDevice instead.
	 */
	OFTarArchiveEntryTypeBlockDevice OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeBlockDevice instead") = '4',

	/**
	 * @brief Directory.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeDirectory instead.
	 */
	OFTarArchiveEntryTypeDirectory OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeDirectory instead") = '5',

	/**
	 * @brief FIFO.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeFIFO instead.
	 */
	OFTarArchiveEntryTypeFIFO OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeFIFO instead") = '6',

	/**
	 * @brief Contiguous file.
	 *
	 * @deprecated Use @ref OFArchiveEntryFileTypeContiguousFile instead.
	 */
	OFTarArchiveEntryTypeContiguousFile OF_DEPRECATED(ObjFW, 1, 5,
	    "Use OFArchiveEntryFileTypeContiguousFile") = '7',
};

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
	OFArchiveEntryFileType _fileType;
	OFString *_Nullable _targetFileName;
	OFString *_Nullable _ownerAccountName;
	OFString *_Nullable _groupOwnerAccountName;
	unsigned long _deviceMajor, _deviceMinor;
	OF_RESERVE_IVARS(OFTarArchiveEntry, 4)
}

/**
 * @brief The type of the archive entry.
 *
 * @deprecated Use @ref OFArchiveEntry#fileType instead.
 */
@property (readonly, nonatomic) OFTarArchiveEntryType type
    OF_DEPRECATED(ObjFW, 1, 5, "Use -[OFArchiveEntry fileType] instead");

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableTarArchiveEntry.h"
