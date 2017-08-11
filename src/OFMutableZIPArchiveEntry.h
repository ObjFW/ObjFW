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

#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMutableZIPArchiveEntry \
 *	  OFMutableZIPArchiveEntry.h ObjFW/OFMutableZIPArchiveEntry.h
 *
 * @brief A class which represents a mutable entry in the central directory of
 *	  a ZIP archive.
 */
@interface OFMutableZIPArchiveEntry: OFZIPArchiveEntry

/*!
 * The file name of the entry.
 */
@property (readwrite, copy, nonatomic) OFString *fileName;

/*!
 * The comment of the entry's file.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *fileComment;

/*!
 * The extra field of the entry.
 *
 * The item size *must* be 1!
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFData *extraField;

/*!
 * The version which made the entry.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 */
@property (readwrite, nonatomic) uint16_t versionMadeBy;

/*!
 * The minimum version required to extract the file.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 */
@property (readwrite, nonatomic) uint16_t minVersionNeeded;

/*!
 * The last modification date of the entry's file.
 *
 * @note Due to limitations of the ZIP format, this has only 2 second precision.
 */
@property (readwrite, retain, nonatomic) OFDate *modificationDate;

/*!
 * The compression method of the entry.
 *
 * Supported values are:
 * Value                                             | Description
 * --------------------------------------------------|---------------
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE      | No compression
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE   | Deflate
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64 | Deflate64
 *
 * Other values may be returned, but the file cannot be extracted then.
 */
@property (readwrite, nonatomic) uint16_t compressionMethod;

/*!
 * The compressed size of the entry's file.
 */
@property (readwrite, nonatomic) uint64_t compressedSize;

/*!
 * The uncompressed size of the entry's file.
 */
@property (readwrite, nonatomic) uint64_t uncompressedSize;

/*!
 * The CRC32 checksum of the entry's file.
 */
@property (readwrite, nonatomic) uint32_t CRC32;

/*!
 * The version specific attributes.
 *
 * The meaning of the version specific attributes depends on the attribute
 * compatibility part of the version that made the entry.
 */
@property (readwrite, nonatomic) uint32_t versionSpecificAttributes;

/*!
 * The general purpose bit flag of the entry.
 *
 * See the ZIP specification for details.
 */
@property (readwrite, nonatomic) uint16_t generalPurposeBitFlag;

/*!
 * @brief Converts the OFMutableZIPArchiveEntry to an immutable
 *	  OFZIPArchiveEntry.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
