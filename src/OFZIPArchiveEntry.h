/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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
	/** MS-DOS and OS/2 */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MSDOS	       =  0,
	/** Amiga */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_AMIGA	       =  1,
	/** OpenVMS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OPENVMS       =  2,
	/** UNIX */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX	       =  3,
	/** VM/CMS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VM_CMS	       =  4,
	/** Atari ST */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ATARI_ST      =  5,
	/** OS/2 HPFS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS2_HPFS      =  6,
	/** Macintosh */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MACINTOSH     =  7,
	/** Z-System */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_Z_SYSTEM      =  8,
	/** CP/M */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_CP_M	       =  9,
	/** Windows NTFS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_WINDOWS_NTFS  = 10,
	/** MVS (OS/390 - Z/OS) */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_MVS	       = 11,
	/** VSE */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VSE	       = 12,
	/** Acorn Risc */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ACORN_RISC    = 13,
	/** VFAT */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_VFAT	       = 14,
	/** Alternate MVS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_ALTERNATE_MVS = 15,
	/** BeOS */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_BEOS	       = 16,
	/** Tandem */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_TANDEM	       = 17,
	/** OS/400 */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_400	       = 18,
	/** OS X (Darwin) */
	OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_OS_X	       = 19
};

enum {
	OF_ZIP_ARCHIVE_ENTRY_EXTRA_FIELD_ZIP64 = 0x0001
};

@class OFString;
@class OFDataArray;
@class OFFile;
@class OFDate;

/*!
 * @class OFZIPArchiveEntry OFZIPArchiveEntry.h ObjFW/OFZIPArchiveEntry.h
 *
 * @brief A class which represents an entry in the central directory of a ZIP
 *	  archive.
 */
@interface OFZIPArchiveEntry: OFObject
{
	uint16_t _versionMadeBy, _minVersionNeeded, _generalPurposeBitFlag;
	uint16_t _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	uint64_t _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFDataArray *_extraField;
	OFString *_fileComment;
	uint32_t _startDiskNumber;
	uint16_t _internalAttributes;
	uint32_t _versionSpecificAttributes;
	uint64_t _localFileHeaderOffset;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *fileName, *fileComment;
@property (readonly) uint16_t versionMadeBy, minVersionNeeded;
@property (readonly) uint16_t compressionMethod;
@property (readonly) uint64_t compressedSize, uncompressedSize;
@property (readonly, retain) OFDate *modificationDate;
@property (readonly) uint32_t CRC32;
@property (readonly) uint32_t versionSpecificAttributes;
@property (readonly, copy) OFDataArray *extraField;
#endif

/*!
 * @brief Returns the file name of the entry.
 *
 * @return The file name of the entry
 */
- (OFString*)fileName;

/*!
 * @brief Returns the comment of the entry's file.
 *
 * @return The comment of the entry's file
 */
- (OFString*)fileComment;

/*!
 * @brief Returns the version which made the entry.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 *
 * @return The version which made the entry
 */
- (uint16_t)versionMadeBy;

/*!
 * @brief Returns the minimum version required to extract the file.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref of_zip_archive_entry_attribute_compatibility.
 *
 * @return The minimum version required to extract the file
 */
- (uint16_t)minVersionNeeded;

/*!
 * @brief Returns the compression method of the entry
 *
 * Supported values are:
 * Value                                             | Description
 * --------------------------------------------------|---------------
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_NONE      | No compression
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE   | Deflate
 * OF_ZIP_ARCHIVE_ENTRY_COMPRESSION_METHOD_DEFLATE64 | Deflate64
 *
 * Other values may be returned, but the file cannot be extracted then.
 *
 * @return The compression method of the entry
 */
- (uint16_t)compressionMethod;

/*!
 * @brief Returns the compressed size of the entry's file.
 *
 * @return The compressed size of the entry's file
 */
- (uint64_t)compressedSize;

/*!
 * @brief Returns the uncompressed size of the entry's file.
 *
 * @return The uncompressed size of the entry's file
 */
- (uint64_t)uncompressedSize;

/*!
 * @brief Returns the last modification date of the entry's file.
 *
 * @return The last modification date of the entry's file
 */
- (OFDate*)modificationDate;

/*!
 * @brief Returns the CRC32 checksum of the entry's file.
 *
 * @return The CRC32 checksum of the entry's file
 */
- (uint32_t)CRC32;

/*!
 * @brief Returns the version specific attributes.
 *
 * The meaning of the version specific attributes depends on the attribute
 * compatibility part of the version that made the entry.
 *
 * @return The version specific attributes
 */
- (uint32_t)versionSpecificAttributes;

/*!
 * @brief Returns the extra field of the entry.
 *
 * @return The extra field of the entry
 */
- (OFDataArray*)extraField;
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
extern OFString* of_zip_archive_entry_version_to_string(uint16_t version);

/*!
 * @brief Gets a pointer to and the size of the extensible data field with the
 *	  specified tag.
 *
 * @param extraField The extra field to search for an extensible data field with
 *		     the specified tag
 * @param tag The tag to look for
 * @param data A pointer to a pointer that should be set to the start of the
 *	       extra field with the specified tag
 * @param size A pointer to an uint16_t that should be set to the size
 */
extern void of_zip_archive_entry_extra_field_find(OFDataArray *extraField,
    uint16_t tag, uint8_t **data, uint16_t *size);
#ifdef __cplusplus
}
#endif
