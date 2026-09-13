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

#import "OFZooArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableZooArchiveEntry OFMutableZooArchiveEntry.h ObjFW/ObjFW.h
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
