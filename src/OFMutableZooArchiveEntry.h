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

#import "OFZooArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableZooArchiveEntry OFZooArchiveEntry.h ObjFW/OFZooArchiveEntry.h
 *
 * @brief A class which represents a mutable entry in a Zoo archive.
 */
@interface OFMutableZooArchiveEntry: OFZooArchiveEntry <OFMutableArchiveEntry>
{
	OF_RESERVE_IVARS(OFMutableZooArchiveEntry, 4)
}

/**
 * @brief The header type of the entry.
 */
@property (readwrite, nonatomic) uint8_t headerType;

/**
 * @brief The compression method of the entry.
 */
@property (readwrite, nonatomic) uint8_t compressionMethod;

/**
 * @brief The CRC16 of the file.
 */
@property (readwrite, nonatomic) uint16_t CRC16;

/**
 * @brief The minimum version required to extract the file.
 *
 * The upper 8 bits are the major version and the lower 8 bits the minor
 * version.
 */
@property (readwrite, nonatomic) uint16_t minVersionNeeded;

/**
 * @brief Whether the file was deleted.
 */
@property (readwrite, nonatomic, getter=isDeleted) bool deleted;

/**
 * @brief The operating system identifier of the file.
 */
@property (readwrite, nonatomic) uint16_t operatingSystemIdentifier;

/**
 * @brief The time zone in which the file was stored, as an offset in hours
 *	  from UTC (as a float).
 *
 * @note Make sure to set the correct time zone before setting the modification
 *	 date!
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFNumber *timeZone;

/**
 * @brief Creates a new OFMutableZooArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFZooArchiveEntry
 * @return A new, autoreleased OFZooArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

/**
 * @brief Initializes an already allocated OFMutableZooArchiveEntry with the
 *	  specified file name.
 *
 * @param fileName The file name for the OFZooArchiveEntry
 * @return An initialized OFZooArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;

/**
 * @brief Converts the OFMutableZooArchiveEntry to an immutable
 *	  OFZooArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
