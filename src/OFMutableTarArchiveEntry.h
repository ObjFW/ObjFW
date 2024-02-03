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

#import "OFTarArchiveEntry.h"
#import "OFMutableArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableTarArchiveEntry \
 *	  OFMutableTarArchiveEntry.h ObjFW/OFMutableTarArchiveEntry.h
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
