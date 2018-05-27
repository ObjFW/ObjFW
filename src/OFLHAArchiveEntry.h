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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFData;
@class OFDate;
@class OFNumber;
@class OFString;

/*!
 * @class OFLHAArchiveEntry OFLHAArchiveEntry.h ObjFW/OFLHAArchiveEntry.h
 *
 * @brief A class which represents an entry in the central directory of a LHA
 *	  archive.
 */
@interface OFLHAArchiveEntry: OFObject <OFCopying>
{
#ifdef OF_LHA_ARCHIVE_ENTRY_M
@public
#endif
	OFString *_fileName, *_Nullable _directoryName, *_method;
	uint32_t _compressedSize, _uncompressedSize;
	OFDate *_date;
	uint8_t _level;
	uint16_t _CRC16;
	uint8_t _operatingSystemIdentifier;
	OFString *_Nullable _fileComment;
	OFNumber *_Nullable _mode, *_Nullable _UID, *_Nullable _GID;
	OFString *_Nullable _owner, *_Nullable _group;
	OFDate *_Nullable _modificationDate;
	OFArray OF_GENERIC(OFData *) *_extensions;
}

/*!
 * @brief The file name of the entry.
 */
@property (readonly, copy, nonatomic) OFString *fileName;

/*!
 * @brief The method of the entry.
 */
@property (readonly, copy, nonatomic) OFString *method;

/*!
 * @brief The compressed size of the entry's file.
 */
@property (readonly, nonatomic) uint32_t compressedSize;

/*!
 * @brief The uncompressed size of the entry's file.
 */
@property (readonly, nonatomic) uint32_t uncompressedSize;

/*!
 * @brief The date of the file.
 */
@property (readonly, retain, nonatomic) OFDate *date;

/*!
 * @brief The LHA level of the file.
 */
@property (readonly, nonatomic) uint8_t level;

/*!
 * @brief The CRC16 of the file.
 */
@property (readonly, nonatomic) uint16_t CRC16;

/*!
 * @brief The operating system identifier of the file.
 */
@property (readonly, nonatomic) uint8_t operatingSystemIdentifier;

/*!
 * @brief The comment of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *fileComment;

/*!
 * @brief The LHA extensions of the file.
 */
@property (readonly, copy, nonatomic) OFArray OF_GENERIC(OFData *) *extensions;

/*!
 * @brief The mode of the entry.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic) OFNumber *mode;

/*!
 * @brief The UID of the owner.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic) OFNumber *UID;

/*!
 * @brief The GID of the group.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic) OFNumber *GID;

/*!
 * @brief The owner of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *owner;

/*!
 * @brief The group of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *group;

/*!
 * @brief The date of the last modification of the file.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFDate *modificationDate;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
