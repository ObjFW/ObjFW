/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFLHAArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMutableLHAArchiveEntry \
 *	  OFMutableLHAArchiveEntry.h ObjFW/OFMutableLHAArchiveEntry.h
 *
 * @brief A class which represents a mutable entry in an LHA archive.
 */
@interface OFMutableLHAArchiveEntry: OFLHAArchiveEntry

/*!
 * @brief The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/*!
 * @brief The compression method of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *compressionMethod;

/*!
 * @brief The compressed size of the entry's file.
 */
@property (readwrite, nonatomic) uint32_t compressedSize;

/*!
 * @brief The uncompressed size of the entry's file.
 */
@property (readwrite, nonatomic) uint32_t uncompressedSize;

/*!
 * @brief The date of the file.
 */
@property (readwrite, retain, nonatomic) OFDate *date;

/*!
 * @brief The LHA level of the file.
 */
@property (readwrite, nonatomic) uint8_t headerLevel;

/*!
 * @brief The CRC16 of the file.
 */
@property (readwrite, nonatomic) uint16_t CRC16;

/*!
 * @brief The operating system identifier of the file.
 */
@property (readwrite, nonatomic) uint8_t operatingSystemIdentifier;

/*!
 * @brief The comment of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *fileComment;

/*!
 * @brief The mode of the entry.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic) OFNumber *mode;

/*!
 * @brief The UID of the owner.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic) OFNumber *UID;

/*!
 * @brief The GID of the group.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic) OFNumber *GID;

/*!
 * @brief The owner of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *owner;

/*!
 * @brief The group of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *group;

/*!
 * @brief The date of the last modification of the file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, retain, nonatomic)
    OFDate *modificationDate;

/*!
 * @brief The LHA extensions of the file.
 */
@property (readwrite, copy, nonatomic) OFArray OF_GENERIC(OFData *) *extensions;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Converts the OFMutableLHAArchiveEntry to an immutable
 *	  OFLHAArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
