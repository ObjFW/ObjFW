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
#import "OFString.h"

@class OFFile;
@class OFArray;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFStream;

/*!
 * @class OFZIPArchive OFZIPArchive.h ObjFW/OFZIPArchive.h
 *
 * @brief A class for accessing and manipulating ZIP files.
 */
@interface OFZIPArchive: OFObject
{
	OFFile *_file;
	OFString *_path;
	uint32_t _diskNumber, _centralDirectoryDisk;
	uint64_t _centralDirectoryEntriesInDisk, _centralDirectoryEntries;
	uint64_t _centralDirectorySize, _centralDirectoryOffset;
	OFString *_archiveComment;
	OFMutableArray *_entries;
	OFMutableDictionary *_pathToEntryMap;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *archiveComment;
@property (readonly, copy) OFArray *entries;
#endif

/*!
 * @brief Creates a new OFZIPArchive object for the specified file.
 *
 * @param path The path to the ZIP file
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithPath: (OFString*)path;

/*!
 * @brief Initializes an already allocated OFZIPArchive object for the
 *	  specified file.
 *
 * @param path The path to the ZIP file
 * @return An initialized OFZIPArchive
 */
- initWithPath: (OFString*)path;

/*!
 * @brief Returns the entries of the central directory of the archive as an
 * 	  array of objects of class @ref OFZIPArchiveEntry.
 *
 * The objects of the array have the same order as the entries in the central
 * directory, which does not need to be the order in which the actual files are
 * stored.
 *
 * @return The entries of the central directory of the archive as an array
 */
- (OFArray*)entries;

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
@end
