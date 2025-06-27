/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

typedef enum {
	OFZIPArchiveEntryCompressionMethodNone		=  0,
	OFZIPArchiveEntryCompressionMethodShrink	=  1,
	OFZIPArchiveEntryCompressionMethodReduceFactor1 =  2,
	OFZIPArchiveEntryCompressionMethodReduceFactor2 =  3,
	OFZIPArchiveEntryCompressionMethodReduceFactor3 =  4,
	OFZIPArchiveEntryCompressionMethodReduceFactor4 =  5,
	OFZIPArchiveEntryCompressionMethodImplode	=  6,
	OFZIPArchiveEntryCompressionMethodDeflate	=  8,
	OFZIPArchiveEntryCompressionMethodDeflate64	=  9,
	OFZIPArchiveEntryCompressionMethodBZIP2		= 12,
	OFZIPArchiveEntryCompressionMethodLZMA		= 14,
	OFZIPArchiveEntryCompressionMethodWavPack	= 97,
	OFZIPArchiveEntryCompressionMethodPPMd		= 98
} OFZIPArchiveEntryCompressionMethod;

/**
 * @brief Attribute compatibility part of ZIP versions.
 */
typedef enum {
	/** MS-DOS and OS/2 */
	OFZIPArchiveEntryAttributeCompatibilityMSDOS	    =  0,
	/** Amiga */
	OFZIPArchiveEntryAttributeCompatibilityAmiga	    =  1,
	/** OpenVMS */
	OFZIPArchiveEntryAttributeCompatibilityOpenVMS	    =  2,
	/** UNIX */
	OFZIPArchiveEntryAttributeCompatibilityUNIX	    =  3,
	/** VM/CMS */
	OFZIPArchiveEntryAttributeCompatibilityVM_CMS	    =  4,
	/** Atari ST */
	OFZIPArchiveEntryAttributeCompatibilityAtariST	    =  5,
	/** OS/2 HPFS */
	OFZIPArchiveEntryAttributeCompatibilityOS2HPFS	    =  6,
	/** Macintosh */
	OFZIPArchiveEntryAttributeCompatibilityMacintosh    =  7,
	/** Z-System */
	OFZIPArchiveEntryAttributeCompatibilityZSystem	    =  8,
	/** CP/M */
	OFZIPArchiveEntryAttributeCompatibilityCPM	    =  9,
	/** Windows NTFS */
	OFZIPArchiveEntryAttributeCompatibilityWindowsNTFS  = 10,
	/** MVS (OS/390 - Z/OS) */
	OFZIPArchiveEntryAttributeCompatibilityMVS	    = 11,
	/** VSE */
	OFZIPArchiveEntryAttributeCompatibilityVSE	    = 12,
	/** Acorn RISC OS */
	OFZIPArchiveEntryAttributeCompatibilityAcornRISCOS  = 13,
	/** VFAT */
	OFZIPArchiveEntryAttributeCompatibilityVFAT	    = 14,
	/** Alternate MVS */
	OFZIPArchiveEntryAttributeCompatibilityAlternateMVS = 15,
	/** BeOS */
	OFZIPArchiveEntryAttributeCompatibilityBeOS	    = 16,
	/** Tandem */
	OFZIPArchiveEntryAttributeCompatibilityTandem	    = 17,
	/** OS/400 */
	OFZIPArchiveEntryAttributeCompatibilityOS400	    = 18,
	/** OS X (Darwin) */
	OFZIPArchiveEntryAttributeCompatibilityOSX	    = 19
} OFZIPArchiveEntryAttributeCompatibility;

/**
 * @brief Tags for the extra field.
 */
typedef enum {
	/** ZIP64 extra field tag */
	OFZIPArchiveEntryExtraFieldTagZIP64 = 0x0001
} OFZIPArchiveEntryExtraFieldTag;

@class OFString;
@class OFData;
@class OFFile;
@class OFDate;

/**
 * @class OFZIPArchiveEntry OFZIPArchiveEntry.h ObjFW/ObjFW.h
 *
 * @brief A class which represents an entry in the central directory of a ZIP
 *	  archive.
 */
@interface OFZIPArchiveEntry: OFObject <OFArchiveEntry, OFCopying,
    OFMutableCopying>
{
	OFZIPArchiveEntryAttributeCompatibility _versionMadeBy;
	OFZIPArchiveEntryAttributeCompatibility _minVersionNeeded;
	uint16_t _generalPurposeBitFlag;
	OFZIPArchiveEntryCompressionMethod _compressionMethod;
	uint16_t _lastModifiedFileTime, _lastModifiedFileDate;
	uint32_t _CRC32;
	unsigned long long _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFData *_Nullable _extraField;
	OFString *_Nullable _fileComment;
	uint32_t _startDiskNumber;
	uint16_t _internalAttributes;
	uint32_t _versionSpecificAttributes;
	int64_t _localFileHeaderOffset;
	OF_RESERVE_IVARS(OFZIPArchiveEntry, 4)
}

/**
 * @brief The extra field of the entry.
 *
 * The item size *must* be 1!
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFData *extraField;

/**
 * @brief The version which made the entry.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref OFZIPArchiveEntryAttributeCompatibility.
 */
@property (readonly, nonatomic)
    OFZIPArchiveEntryAttributeCompatibility versionMadeBy;

/**
 * @brief The minimum version required to extract the file.
 *
 * The lower 8 bits are the ZIP specification version.@n
 * The upper 8 bits are the attribute compatibility.
 * See @ref OFZIPArchiveEntryAttributeCompatibility.
 */
@property (readonly, nonatomic)
    OFZIPArchiveEntryAttributeCompatibility minVersionNeeded;

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
@property (readonly, nonatomic)
    OFZIPArchiveEntryCompressionMethod compressionMethod;

/**
 * @brief The CRC32 checksum of the entry's file.
 */
@property (readonly, nonatomic) uint32_t CRC32;

/**
 * @brief The version specific attributes.
 *
 * The meaning of the version specific attributes depends on the attribute
 * compatibility part of the version that made the entry.
 */
@property (readonly, nonatomic) uint32_t versionSpecificAttributes;

/**
 * @brief The general purpose bit flag of the entry.
 *
 * See the ZIP specification for details.
 */
@property (readonly, nonatomic) uint16_t generalPurposeBitFlag;

- (instancetype)init OF_UNAVAILABLE;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Converts the ZIP entry version to a string.
 *
 * @param version The ZIP entry version to convert to a string
 * @return The ZIP entry version as a string
 */
extern OFString *OFZIPArchiveEntryVersionToString(uint16_t version);

/**
 * @brief Converts the ZIP entry compression method to a string.
 *
 * @param compressionMethod The ZIP entry compression method to convert to a
 *			    string
 * @return The ZIP entry compression method as a string
 */
extern OFString *OFZIPArchiveEntryCompressionMethodName(
    OFZIPArchiveEntryCompressionMethod compressionMethod);

/**
 * @brief Gets a pointer to and the size of the extensible data field with the
 *	  specified tag.
 *
 * @param extraField The extra field to search for an extensible data field with
 *		     the specified tag
 * @param tag The tag to look for
 * @param size A pointer to an uint16_t that should be set to the size
 * @return The index at which the extra field content starts in the OFData, or
 *	   `OFNotFound`
 */
extern size_t OFZIPArchiveEntryExtraFieldFind(OFData *extraField,
    OFZIPArchiveEntryExtraFieldTag tag, uint16_t *size);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFMutableZIPArchiveEntry.h"
