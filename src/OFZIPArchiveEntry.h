/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdio.h>

@class OFString;
@class OFDataArray;
@class OFFile;
@class OFDate;

/*!
 * @brief A class which represents an entry in the central directory of a ZIP
 *	  archive.
 */
@interface OFZIPArchiveEntry: OFObject
{
	uint16_t _madeWithVersion, _minVersion, _generalPurposeBitFlag;
	uint16_t _compressionMethod, _lastModifiedFileTime;
	uint16_t _lastModifiedFileDate;
	uint32_t _CRC32, _compressedSize, _uncompressedSize;
	OFString *_fileName;
	OFDataArray *_extraField;
	OFString *_fileComment;
	uint16_t _startDiskNumber, _internalAttributes;
	uint32_t _externalAttributes, _localFileHeaderOffset;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *fileName, *fileComment;
@property (readonly) off_t compressedSize, uncompressedSize;
@property (readonly, retain) OFDate *modificationDate;
@property (readonly) uint32_t CRC32;
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
 * @brief Returns the compressed size of the entry's file.
 *
 * @return The compressed size of the entry's file
 */
- (off_t)compressedSize;

/*!
 * @brief Returns the uncompressed size of the entry's file.
 *
 * @return The uncompressed size of the entry's file
 */
- (off_t)uncompressedSize;

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
@end
