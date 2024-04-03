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

#import "OFTarArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableTarArchiveEntry OFTarArchiveEntry.h ObjFW/OFTarArchiveEntry.h
 *
 * @brief A class which represents a mutable entry of a tar archive.
 */
@interface OFMutableTarArchiveEntry: OFTarArchiveEntry <OFMutableArchiveEntry>
{
	OF_RESERVE_IVARS(OFMutableTarArchiveEntry, 4)
}

/**
 * @brief The type of the archive entry.
 *
 * See @ref OFTarArchiveEntryType.
 */
@property (readwrite, nonatomic) OFTarArchiveEntryType type;

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

/**
 * @brief Creates a new OFMutableTarArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFTarArchiveEntry
 * @return A new, autoreleased OFTarArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

/**
 * @brief Initializes an already allocated OFMutableTarArchiveEntry with the
 *	  specified file name.
 *
 * @param fileName The file name for the OFTarArchiveEntry
 * @return An initialized OFTarArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;

/**
 * @brief Converts the OFMutableTarArchiveEntry to an immutable
 *	  OFTarArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
