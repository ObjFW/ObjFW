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

#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableZIPArchiveEntry OFMutableZIPArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents a mutable entry in the central directory of
 *	  a ZIP archive.
 */
@interface OFMutableZIPArchiveEntry: OFZIPArchiveEntry <OFMutableArchiveEntry>
{
	OF_RESERVE_IVARS(OFMutableZIPArchiveEntry, 4)
}

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
 * @brief The compression method of the entry.
 *
 * See @ref OFZIPArchiveEntryCompressionMethod.
 *
 * Only @ref OFZIPArchiveEntryCompressionMethodNone,
 * @ref OFZIPArchiveEntryCompressionMethodDeflate and
 * @ref OFZIPArchiveEntryCompressionMethodDeflate64 can be extracted.
 */
@property (readwrite, nonatomic)
    OFZIPArchiveEntryCompressionMethod compressionMethod;

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
