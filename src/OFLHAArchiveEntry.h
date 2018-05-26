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

/*! @file */

/*!
 * @brief The compression method of the archive entry.
 */
typedef enum of_lha_archive_method_t {
	/*! No compression */
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH0,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LZS,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LZ4,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH1,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH2,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH3,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH4,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH5,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH6,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH7,
	OF_LHA_ARCHIVE_ENTRY_METHOD_LH8,
	/*! Directory */
	OF_LHA_ARCHIVE_ENTRY_METHOD_LHD
} of_lha_archive_method_t;

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
	of_lha_archive_method_t _method;
	OFString *_fileName, *_directoryName;
	uint32_t _compressedSize, _uncompressedSize;
	OFDate *_date;
	uint8_t _level;
	uint16_t _CRC16;
	uint8_t _operatingSystemIdentifier;
	OFArray OF_GENERIC(OFData *) *_extensions;
}

/*!
 * @brief The method of the entry.
 */
@property (readonly, nonatomic) of_lha_archive_method_t method;

/*!
 * @brief The file name of the entry.
 */
@property (readonly, copy, nonatomic) OFString *fileName;

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
 * @brief The LHA level.
 */
@property (readonly, nonatomic) uint8_t level;

/*!
 * @brief The CRC16 of the file.
 */
@property (readonly, nonatomic) uint16_t CRC16;

/*!
 * @brief The operating system identifier.
 */
@property (readonly, nonatomic) uint8_t operatingSystemIdentifier;

/*!
 * @brief The LHA extensions of the file.
 */
@property (readonly, copy, nonatomic) OFArray OF_GENERIC(OFData *) *extensions;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
