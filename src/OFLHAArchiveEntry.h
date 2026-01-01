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
#import "OFArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFData;
@class OFDate;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFNumber;
@class OFString;

/**
 * @class OFLHAArchiveEntry OFLHAArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents an entry in an LHA archive.
 */
@interface OFLHAArchiveEntry: OFObject <OFArchiveEntry, OFCopying,
    OFMutableCopying>
{
	OFString *_fileName, *_Nullable _directoryName, *_compressionMethod;
	unsigned long long _compressedSize, _uncompressedSize;
	OFDate *_modificationDate;
	uint8_t _headerLevel;
	uint16_t _CRC16;
	uint8_t _operatingSystemIdentifier;
	OFString *_Nullable _fileComment;
	OFNumber *_Nullable _POSIXPermissions, *_Nullable _ownerAccountID;
	OFNumber *_Nullable _groupOwnerAccountID;
	OFString *_Nullable _ownerAccountName;
	OFString *_Nullable _groupOwnerAccountName;
	OFMutableArray OF_GENERIC(OFData *) *_extensions;
	OF_RESERVE_IVARS(OFLHAArchiveEntry, 4)
}

/**
 * @brief The compression method of the entry.
 */
@property (readonly, copy, nonatomic) OFString *compressionMethod;

/**
 * @brief The LHA level of the file.
 */
@property (readonly, nonatomic) uint8_t headerLevel;

/**
 * @brief The CRC16 of the file.
 */
@property (readonly, nonatomic) uint16_t CRC16;

/**
 * @brief The operating system identifier of the file.
 */
@property (readonly, nonatomic) uint8_t operatingSystemIdentifier;

/**
 * @brief The LHA extensions of the file.
 */
@property (readonly, copy, nonatomic) OFArray OF_GENERIC(OFData *) *extensions;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableLHAArchiveEntry.h"
