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
#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
#endif
@class OFSeekableStream;
@class OFStream;

/*!
 * @class OFZIPArchive OFZIPArchive.h ObjFW/OFZIPArchive.h
 *
 * @brief A class for accessing and manipulating ZIP files.
 */
@interface OFZIPArchive: OFObject
{
	OFSeekableStream *_stream;
	uint32_t _diskNumber, _centralDirectoryDisk;
	uint64_t _centralDirectoryEntriesInDisk, _centralDirectoryEntries;
	uint64_t _centralDirectorySize, _centralDirectoryOffset;
	OFString *_archiveComment;
	OFMutableArray OF_GENERIC(OFZIPArchiveEntry*) *_entries;
	OFMutableDictionary OF_GENERIC(OFString*, OFZIPArchiveEntry*)
	    *_pathToEntryMap;
	OFStream *_lastReturnedStream;
}

/*!
 * The archive comment.
 */
@property (readonly, copy) OFString *archiveComment;

/*!
 * @brief Creates a new OFZIPArchive object with the specified seekable stream.
 *
 * @param stream A seekable stream from which the ZIP archive will be read
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithSeekableStream: (OFSeekableStream*)stream;

/*!
 * @brief Creates a new OFZIPArchive object with the specified file.
 *
 * @param path The path to the ZIP file
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithPath: (OFString*)path;

/*!
 * @brief Initializes an already allocated OFZIPArchive object with the
 *	  specified seekable stream.
 *
 * @param stream A seekable stream from which the ZIP archive will be read
 * @return An initialized OFZIPArchive
 */
- initWithSeekableStream: (OFSeekableStream*)stream;

/*!
 * @brief Initializes an already allocated OFZIPArchive object with the
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
- (OFArray OF_GENERIC(OFZIPArchiveEntry*)*)entries;

/*!
 * @brief Returns a stream for reading the specified file from the archive.
 *
 * @warning Calling @ref streamForReadingFile: will invalidate all streams
 *	    previously returned by @ref streamForReadingFile:! Reading from an
 *	    invalidated stream will throw an @ref OFReadFailedException!
 *
 * @param path The path to the file inside the archive
 * @return A stream for reading the specified file form the archive
 */
- (OFStream*)streamForReadingFile: (OFString*)path;
@end

OF_ASSUME_NONNULL_END
