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
@class OFString;

/**
 * @class OFZooArchiveEntry OFZooArchiveEntry.h ObjFW/OFZooArchiveEntry.h
 *
 * @brief A class which represents an entry in an Zoo archive.
 */
@interface OFZooArchiveEntry: OFObject <OFArchiveEntry, OFCopying>
{
	uint8_t _compressionMethod;
#ifdef OF_ZOO_ARCHIVE_M
@public
#endif
	unsigned long long _nextHeaderOffset, _dataOffset;
@protected
	uint16_t _lastModifiedFileDate, _lastModifiedFileTime;
	uint16_t _CRC16;
	unsigned long long _uncompressedSize, _compressedSize;
	bool _deleted;
	OFString *_Nullable _fileComment;
	OFString *_fileName, *_Nullable _directoryName;
	OF_RESERVE_IVARS(OFZooArchiveEntry, 4)
}

/**
 * @brief The compression method of the entry.
 */
@property (readonly, nonatomic) uint8_t compressionMethod;

/**
 * @brief The CRC16 of the file.
 */
@property (readonly, nonatomic) uint16_t CRC16;

/**
 * @brief Whether the file was deleted.
 */
@property (readonly, nonatomic, getter=isDeleted) bool deleted;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
