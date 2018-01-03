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

/*! @file */

enum {
	OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE	  = 0,
	OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE	  = 8,
	OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64 = 9
};

/*!
 * @brief Attribute compatibility part of ZIP versions.
 */
enum of_zip_archive_entry_attribute_compatibility {
	/*! MS-DOS and OS/2 */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MSDOS	       =  0,
	/*! Amiga */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_AMIGA	       =  1,
	/*! OpenVMS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OPENVMS       =  2,
	/*! UNIX */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX	       =  3,
	/*! VM/CMS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VM_CMS	       =  4,
	/*! Atari ST */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ATARI_ST      =  5,
	/*! OS/2 HPFS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS2_HPFS      =  6,
	/*! Macintosh */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MACINTOSH     =  7,
	/*! Z-System */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_Z_SYSTEM      =  8,
	/*! CP/M */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_CP_M	       =  9,
	/*! Windows NTFS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_WINDOWS_NTFS  = 10,
	/*! MVS (OS/390 - Z/OS) */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MVS	       = 11,
	/*! VSE */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VSE	       = 12,
	/*! Acorn Risc */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ACORN_RISC    = 13,
	/*! VFAT */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VFAT	       = 14,
	/*! Alternate MVS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ALTERNATE_MVS = 15,
	/*! BeOS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_BEOS	       = 16,
	/*! Tandem */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_TANDEM	       = 17,
	/*! OS/400 */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_400	       = 18,
	/*! OS X (Darwin) */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_X	       = 19
};

enum {
	OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64 = 0x0001
};

@class OFString;
@class OFData;
@class OFFile;
@class OFDate;

/*!
 * @class OFZIPArchiveEntry OFZIPArchiveEntry.h ObjFW/OFZIPArchiveEntry.h
 *
 * @brief A class which represents an entry in the central directory of a ZIP
 *	  archive.
 */
@interface OFZIPArchiveEntry: OFObject <OFCopying, OFMutableCopying>
{
	uint16_t _versionMadeBy, _minVersionNeeded, _generalPurposeBitFlag;
	uint16_t _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	uint64_t _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFData *_Nullable _extraField;
	OFString *_Nullable _fileComment;
	uint32_t _startDiskNumber;
	uint16_t _internalAttributes;
	uint32_t _versionSpecificAttributes;
	int64_t _localFileHeaderOffset;
}

/*!
 * @brief The file name of the entry.
 */
@property (readonly, copy, nonatomic) OFString *fileName;

/*!
 * @brief The comment of the entry's file.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *fileComment;

/*!
 * @brief The extra field of the entry.
 *
 * The item size *must* be 1!
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFData *extraField;

/*!
 * @brief The version which made the entry.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 */
@property (readonly, nonatomic) uint16_t versionMadeBy;

/*!
 * @brief The minimum version required to extract the file.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 */
@property (readonly, nonatomic) uint16_t minVersionNeeded;

/*!
 * @brief The last modification date of the entry's file.
 *
 * @note Due to limitations of the ZIP format, this has only 2 second precision.
 */
@property (readonly, retain, nonatomic) OFDate *modificationDate;

/*!
 * @brief The compression method of the entry.
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
@property (readonly, nonatomic) uint16_t compressionMethod;

/*!
 * @brief The compressed size of the entry's file.
 */
@property (readonly, nonatomic) uint64_t compressedSize;

/*!
 * @brief The uncompressed size of the entry's file.
 */
@property (readonly, nonatomic) uint64_t uncompressedSize;

/*!
 * @brief The CRC32 checksum of the entry's file.
 */
@property (readonly, nonatomic) uint32_t CRC32;

/*!
 * @brief The version specific attributes.
 *
 * The meaning of the version specific attributes depends on the attribute
 * compatibility part of the version that made the entry.
 */
@property (readonly, nonatomic) uint32_t versionSpecificAttributes;

/*!
 * @brief The general purpose bit flag of the entry.
 *
 * See the ZIP specification for details.
 */
@property (readonly, nonatomic) uint16_t generalPurposeBitFlag;

/*!
 * @brief Creates a new OFZIPArchiveEntry with the specified file name.
 *
 * @param fileName The file name for the OFZIPArchiveEntry
 * @return A new, autoreleased OFZIPArchiveEntry
 */
+ (instancetype)entryWithFileName: (OFString *)fileName;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFZIPArchiveEntry with the specified
 *	  file name.
 *
 * @param fileName The file name for the OFZIPArchiveEntry
 * @return An initialized OFZIPArchiveEntry
 */
- (instancetype)initWithFileName: (OFString *)fileName;
@end

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Converts the ZIP entry version to a string
 *
 * @param version The ZIP entry version to convert to a string
 * @return The ZIP entry version as a string
 */
extern OFString *of_zip_archive_entry_version_to_string(uint16_t version);

/*!
 * @brief Gets a pointer to and the size of the extensible data field with the
 *	  specified tag.
 *
 * @param extraField The extra field to search for an extensible data field with
 *		     the specified tag
 * @param tag The tag to look for
 * @param size A pointer to an uint16_t that should be set to the size
 * @return The index at which the extra field content starts in the OFData, or
 *	   OF_NOT_FOUND
 */
extern size_t of_zip_archive_entry_extra_field_find(OFData *extraField,
    uint16_t tag, uint16_t *size);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFMutableZIPArchiveEntry.h"
