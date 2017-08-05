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

#import "OFObject.h"
#import "OFString.h"
#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFStream;

/*!
 * @class OFZIPArchive OFZIPArchive.h ObjFW/OFZIPArchive.h
 *
 * @brief A class for accessing and manipulating ZIP files.
 */
@interface OFZIPArchive: OFObject
{
	OF_KINDOF(OFStream *) _stream;
	enum {
		OF_ZIP_ARCHIVE_MODE_READ,
		OF_ZIP_ARCHIVE_MODE_WRITE,
		OF_ZIP_ARCHIVE_MODE_APPEND
	} _mode;
	uint32_t _diskNumber, _centralDirectoryDisk;
	uint64_t _centralDirectoryEntriesInDisk, _centralDirectoryEntries;
	uint64_t _centralDirectorySize;
	int64_t _centralDirectoryOffset;
	OFString *_archiveComment;
	OFMutableArray OF_GENERIC(OFZIPArchiveEntry *) *_entries;
	OFMutableDictionary OF_GENERIC(OFString *, OFZIPArchiveEntry *)
	    *_pathToEntryMap;
	OFStream *_lastReturnedStream;
}

/*!
 * The archive comment.
 */
@property (readonly, nonatomic) OFString *archiveComment;

/*!
 * @brief Creates a new OFZIPArchive object with the specified stream.
 *
 * @param stream A stream from which the ZIP archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode;

#ifdef OF_HAVE_FILES
/*!
 * @brief Creates a new OFZIPArchive object with the specified file.
 *
 * @param path The path to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithPath: (OFString *)path
			   mode: (OFString *)mode;
#endif

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFZIPArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the ZIP archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFZIPArchive
 */
- initWithStream: (OF_KINDOF(OFStream *))stream
	    mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

#ifdef OF_HAVE_FILES
/*!
 * @brief Initializes an already allocated OFZIPArchive object with the
 *	  specified file.
 *
 * @param path The path to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFZIPArchive
 */
- initWithPath: (OFString *)path
	  mode: (OFString *)mode;
#endif

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
- (OFArray OF_GENERIC(OFZIPArchiveEntry *) *)entries;

/*!
 * @brief Returns a stream for reading the specified file from the archive.
 *
 * This method is only available in read and append mode.
 *
 * @warning Calling @ref streamForReadingFile: will invalidate all streams
 *	    previously returned by @ref streamForReadingFile:! Reading from an
 *	    invalidated stream will throw an @ref OFReadFailedException!
 *
 * @param path The path to the file inside the archive
 * @return A stream for reading the specified file form the archive
 */
- (OFStream *)streamForReadingFile: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
