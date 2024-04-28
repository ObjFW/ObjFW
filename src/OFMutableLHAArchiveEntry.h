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

#import "OFLHAArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableLHAArchiveEntry OFLHAArchiveEntry.h ObjFW/OFHAArchiveEntry.h
 *
 * @brief A class which represents a mutable entry in an LHA archive.
 */
@interface OFMutableLHAArchiveEntry: OFLHAArchiveEntry <OFMutableArchiveEntry>
{
	OF_RESERVE_IVARS(OFMutableLHAArchiveEntry, 4)
}

/**
 * @brief The compression method of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *compressionMethod;

/**
 * @brief The LHA level of the file.
 */
@property (readwrite, nonatomic) uint8_t headerLevel;

/**
 * @brief The CRC16 of the file.
 */
@property (readwrite, nonatomic) uint16_t CRC16;

/**
 * @brief The operating system identifier of the file.
 */
@property (readwrite, nonatomic) uint8_t operatingSystemIdentifier;

/**
 * @brief The LHA extensions of the file.
 */
@property (readwrite, copy, nonatomic) OFArray OF_GENERIC(OFData *) *extensions;

/**
 * @brief Creates a new OFMutableLHAArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFLHAArchiveEntry
 * @return A new, autoreleased OFLHAArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

/**
 * @brief Initializes an already allocated OFMutableLHAArchiveEntry with the
 *	  specified file name.
 *
 * @param fileName The file name for the OFLHAArchiveEntry
 * @return An initialized OFLHAArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;

/**
 * @brief Converts the OFMutableLHAArchiveEntry to an immutable
 *	  OFLHAArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
