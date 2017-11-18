/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

/*!
 * @class OFMutableTarArchiveEntry \
 *	  OFMutableTarArchiveEntry.h ObjFW/OFMutableTarArchiveEntry.h
 *
 * @brief A class which represents a mutable entry of a tar archive.
 */
@interface OFMutableTarArchiveEntry: OFTarArchiveEntry

/*!
 * @brief The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/*!
 * @brief The mode of the entry.
 */
@property (readwrite, nonatomic) uint32_t mode;

/*!
 * @brief The UID of the owner.
 */
@property (readwrite, nonatomic) uint32_t UID;

/*!
 * @brief The GID of the group.
 */
@property (readwrite, nonatomic) uint32_t GID;

/*!
 * @brief The size of the file.
 */
@property (readwrite, nonatomic) uint64_t size;

/*!
 * @brief The date of the last modification of the file.
 */
@property (readwrite, retain, nonatomic) OFDate *modificationDate;

/*!
 * @brief The type of the archive entry.
 *
 * See @ref of_tar_archive_entry_type_t.
 */
@property (readwrite, nonatomic) of_tar_archive_entry_type_t type;

/*!
 * @brief The file name of the target (for a hard link or symbolic link).
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *targetFileName;

/*!
 * @brief The owner of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *owner;

/*!
 * @brief The group of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *group;

/*!
 * @brief The device major (if the file is a device).
 */
@property (readwrite, nonatomic) uint32_t deviceMajor;

/*!
 * @brief The device major (if the file is a device).
 */
@property (readwrite, nonatomic) uint32_t deviceMinor;

/*!
 * @brief Converts the OFMutableTarArchiveEntry to an immutable
 *	  OFTarArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
