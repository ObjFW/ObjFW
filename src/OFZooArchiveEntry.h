/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@class OFDate;
@class OFNumber;
@class OFString;

/**
 * @class OFZooArchiveEntry OFZooArchiveEntry.h ObjFW/OFZooArchiveEntry.h
 *
 * @brief A class which represents an entry in an Zoo archive.
 */
@interface OFZooArchiveEntry: OFObject <OFArchiveEntry, OFCopying>
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
	OFNumber *_Nullable _POSIXPermissions;
	int8_t _timeZone;
	uint16_t _operatingSystemIdentifier;
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
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFNumber *timeZone;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
