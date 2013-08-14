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
#import "OFString.h"

@class OFFile;
@class OFDictionary;
@class OFMutableDictionary;
@class OFStream;

/*!
 * @brief A class for accessing and manipulating ZIP files.
 */
@interface OFZIPArchive: OFObject
{
	OFFile *_file;
	OFString *_path;
	uint16_t _diskNumber, _centralDirectoryDisk;
	uint16_t _centralDirectoryEntriesInDisk, _centralDirectoryEntries;
	uint32_t _centralDirectorySize, _centralDirectoryOffset;
	OFString *_archiveComment;
	OFMutableDictionary *_entries;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *archiveComment;
@property (readonly, copy) OFDictionary *entries;
#endif

/*!
 * @brief Creates a new OFZIPArchive object for the specified file.
 *
 * @param path The path to the ZIP file
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithFile: (OFString*)path;

/*!
 * @brief Initializes an already allocated OFZIPArchive object for the
 *	  specified file.
 *
 * @param path The path to the ZIP file
 * @return An Initialized OFZIPArchive
 */
- initWithFile: (OFString*)path;

/*!
 * @brief Returns the entries in the central directory of the archive as a
 * 	  dictionary.
 *
 * The dictionary maps the file name to an @ref OFZIPArchiveEntry.
 *
 * @return The entries in the central directory of the archive as a dictionary
 */
- (OFDictionary*)entries;

/*!
 * @brief Returns the archive comment.
 *
 * @return The archive comment
 */
- (OFString*)archiveComment;

/*!
 * @brief Returns a stream for reading the specified file from the archive.
 *
 * @param path The path to the file inside the archive
 * @return A stream for reading the specified file form the archive
 */
- (OFStream*)streamForReadingFile: (OFString*)path;

- (void)OF_readZIPInfo;
- (void)OF_readEntries;
@end
