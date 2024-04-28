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

@class OFDate;
@class OFNumber;
@class OFString;

/**
 * @class OFZooArchiveEntry OFZooArchiveEntry.h ObjFW/OFZooArchiveEntry.h
 *
 * @brief A class which represents an entry in a Zoo archive.
 */
@interface OFZooArchiveEntry: OFObject <OFArchiveEntry, OFCopying,
    OFMutableCopying>
{
	uint8_t _headerType, _compressionMethod;
#ifdef OF_ZOO_ARCHIVE_M
@public
#endif
	unsigned long long _nextHeaderOffset, _dataOffset;
@protected
	uint16_t _lastModifiedFileDate, _lastModifiedFileTime;
	uint16_t _CRC16;
	unsigned long long _uncompressedSize, _compressedSize;
	uint16_t _minVersionNeeded;
	bool _deleted;
	OFString *_Nullable _fileComment;
	OFString *_fileName, *_Nullable _directoryName;
	uint16_t _operatingSystemIdentifier;
	OFNumber *_Nullable _POSIXPermissions;
	int8_t _timeZone;
	OF_RESERVE_IVARS(OFZooArchiveEntry, 4)
}

/**
 * @brief The header type of the entry.
 */
@property (readonly, nonatomic) uint8_t headerType;

/**
 * @brief The compression method of the entry.
 */
@property (readonly, nonatomic) uint8_t compressionMethod;

/**
 * @brief The CRC16 of the file.
 */
@property (readonly, nonatomic) uint16_t CRC16;

/**
 * @brief The minimum version required to extract the file.
 *
 * The upper 8 bits are the major version and the lower 8 bits the minor
 * version.
 */
@property (readonly, nonatomic) uint16_t minVersionNeeded;

/**
 * @brief Whether the file was deleted.
 */
@property (readonly, nonatomic, getter=isDeleted) bool deleted;

/**
 * @brief The operating system identifier of the file.
 */
@property (readonly, nonatomic) uint16_t operatingSystemIdentifier;

/**
 * @brief The time zone in which the file was stored, as an offset in hours
 *	  from UTC (as a float).
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic) OFNumber *timeZone;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableZooArchiveEntry.h"
