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

#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableZIPArchiveEntry \
 *	  OFMutableZIPArchiveEntry.h ObjFW/OFMutableZIPArchiveEntry.h
 *
 * @brief A class which represents a mutable entry in the central directory of
 *	  a ZIP archive.
 */
@interface OFMutableZIPArchiveEntry: OFZIPArchiveEntry
{
	OF_RESERVE_IVARS(OFMutableZIPArchiveEntry, 4)
}

/**
 * @brief The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/**
 * @brief The comment of the entry's file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *fileComment;

/**
 * @brief The extra field of the entry.
 *
 * The item size *must* be 1!
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFData *extraField;

/**
 * @brief The version which made the entry.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref OFZIPArchiveEntryAttributeCompatibility.
 */
@property (readwrite, nonatomic)
    OFZIPArchiveEntryAttributeCompatibility versionMadeBy;

/**
 * @brief The minimum version required to extract the file.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref OFZIPArchiveEntryAttributeCompatibility.
 */
@property (readwrite, nonatomic)
    OFZIPArchiveEntryAttributeCompatibility minVersionNeeded;

/**
 * @brief The last modification date of the entry's file.
 *
 * @note Due to limitations of the ZIP format, this has only 2 second precision.
 */
@property (readwrite, retain, nonatomic) OFDate *modificationDate;

/**
 * @brief The compression method of the entry.
 *
 * Supported values are:
 * Value                                       | Description
 * --------------------------------------------|---------------
 * OFZIPArchiveEntryCompressionMethodNone      | No compression
 * OFZIPArchiveEntryCompressionMethodDeflate   | Deflate
 * OFZIPArchiveEntryCompressionMethodDeflate64 | Deflate64
 *
 * Other values may be returned, but the file cannot be extracted then.
 */
@property (readwrite, nonatomic)
    OFZIPArchiveEntryCompressionMethod compressionMethod;

/**
 * @brief The compressed size of the entry's file.
 */
@property (readwrite, nonatomic) unsigned long long compressedSize;

/**
 * @brief The uncompressed size of the entry's file.
 */
@property (readwrite, nonatomic) unsigned long long uncompressedSize;

/**
 * @brief The CRC32 checksum of the entry's file.
 */
@property (readwrite, nonatomic) uint32_t CRC32;

/**
 * @brief The version specific attributes.
 *
 * The meaning of the version specific attributes depends on the attribute
 * compatibility part of the version that made the entry.
 */
@property (readwrite, nonatomic) uint32_t versionSpecificAttributes;

/**
 * @brief The general purpose bit flag of the entry.
 *
 * See the ZIP specification for details.
 */
@property (readwrite, nonatomic) uint16_t generalPurposeBitFlag;

/**
 * @brief Creates a new OFMutableZIPArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFZIPArchiveEntry
 * @return A new, autoreleased OFZIPArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

/**
 * @brief Initializes an already allocated OFMutableZIPArchiveEntry with the
 *	  specified file name.
 *
 * @param fileName The file name for the OFZIPArchiveEntry
 * @return An initialized OFZIPArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;

/**
 * @brief Converts the OFMutableZIPArchiveEntry to an immutable
 *	  OFZIPArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
