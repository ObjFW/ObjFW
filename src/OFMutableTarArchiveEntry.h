/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableTarArchiveEntry \
 *	  OFMutableTarArchiveEntry.h ObjFW/OFMutableTarArchiveEntry.h
 *
 * @brief A class which represents a mutable entry of a tar archive.
 */
@interface OFMutableTarArchiveEntry: OFTarArchiveEntry
{
	OF_RESERVE_IVARS(OFMutableTarArchiveEntry, 4)
}

/**
 * @brief The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/**
 * @brief The mode of the entry.
 */
@property (readwrite, nonatomic) unsigned long mode;

/**
 * @brief The UID of the owner.
 */
@property (readwrite, nonatomic) unsigned long UID;

/**
 * @brief The GID of the group.
 */
@property (readwrite, nonatomic) unsigned long GID;

/**
 * @brief The size of the file.
 */
@property (readwrite, nonatomic) unsigned long long size;

/**
 * @brief The date of the last modification of the file.
 */
@property (readwrite, retain, nonatomic) OFDate *modificationDate;

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
 * @brief The owner of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *owner;

/**
 * @brief The group of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *group;

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
