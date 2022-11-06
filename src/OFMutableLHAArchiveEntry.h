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

#import "OFLHAArchiveEntry.h"
#import "OFMutableArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableLHAArchiveEntry \
 *	  OFMutableLHAArchiveEntry.h ObjFW/OFMutableLHAArchiveEntry.h
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
