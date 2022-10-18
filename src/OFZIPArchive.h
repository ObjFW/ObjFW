/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

/**
 * @class OFZIPArchive OFZIPArchive.h ObjFW/OFZIPArchive.h
 *
 * @brief A class for accessing and manipulating ZIP files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFZIPArchive: OFObject
{
	OFStream *_stream;
#ifdef OF_ZIP_ARCHIVE_M
@public
#endif
	int64_t _offset;
@protected
	uint_least8_t _mode;
	uint32_t _diskNumber, _centralDirectoryDisk;
	uint64_t _centralDirectoryEntriesInDisk, _centralDirectoryEntries;
	uint64_t _centralDirectorySize;
	int64_t _centralDirectoryOffset;
	OFString *_Nullable _archiveComment;
#ifdef OF_ZIP_ARCHIVE_M
@public
#endif
	OFMutableArray OF_GENERIC(OFZIPArchiveEntry *) *_entries;
	OFMutableDictionary OF_GENERIC(OFString *, OFZIPArchiveEntry *)
	    *_pathToEntryMap;
	OFStream *_Nullable _lastReturnedStream;
}

/**
 * @brief The archive comment.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *archiveComment;

/**
 * @brief The entries in the central directory of the archive as an array of
 *	  objects of class @ref OFZIPArchiveEntry.
 *
 * The objects of the array have the same order as the entries in the central
 * directory, which does not need to be the order in which the actual files are
 * stored.
 */
@property (readonly, nonatomic)
    OFArray OF_GENERIC(OFZIPArchiveEntry *) *entries;

/**
 * @brief Creates a new OFZIPArchive object with the specified stream.
 *
 * @param stream A stream from which the ZIP archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode;

/**
 * @brief Creates a new OFZIPArchive object with the specified file.
 *
 * @param URI The URI to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFZIPArchive
 */
+ (instancetype)archiveWithURI: (OFURI *)URI mode: (OFString *)mode;

/**
 * @brief Creates a URI for accessing a the specified file within the specified
 *	  ZIP archive.
 *
 * @param path The path of the file within the archive
 * @param URI The URI of the archive
 * @return A URI for accessing the specified file within the specified ZIP
 *	   archive
 */
+ (OFURI *)URIForFilePath: (OFString *)path inArchiveWithURI: (OFURI *)URI;

- (instancetype)init OF_UNAVAILABLE;

/**
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
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFZIPArchive object with the
 *	  specified file.
 *
 * @param URI The URI to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFZIPArchive
 */
- (instancetype)initWithURI: (OFURI *)URI mode: (OFString *)mode;

/**
 * @brief Returns a stream for reading the specified file from the archive.
 *
 * @note This method is only available in read mode.
 *
 * @note The returned stream conforms to @ref OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @warning Calling @ref streamForReadingFile: will invalidate all streams
 *	    previously returned by @ref streamForReadingFile: or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @param path The path to the file inside the archive
 * @return A stream for reading the specified file form the archive
 */
- (OFStream *)streamForReadingFile: (OFString *)path;

/**
 * @brief Returns a stream for writing the specified entry to the archive.
 *
 * @note This method is only available in write and append mode.
 *
 * @note The returned stream conforms to @ref OFReadyForWritingObserving if the
 *	 underlying stream does so, too.
 *
 * @warning Calling @ref streamForWritingEntry: will invalidate all streams
 *	    previously returned by @ref streamForReadingFile: or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @param entry The entry to write to the archive.@n
 *		The following parts of the specified entry will be ignored:
 *		  * The lower 8 bits of the version made by.
 *		  * The lower 8 bits of the minimum version needed.
 *		  * The compressed size.
 *		  * The uncompressed size.
 *		  * The CRC32.
 *		  * Bit 3 and 11 of the general purpose bit flag.
 * @return A stream for writing the specified entry to the archive
 */
- (OFStream *)streamForWritingEntry: (OFZIPArchiveEntry *)entry;

/**
 * @brief Closes the OFZIPArchive.
 */
- (void)close;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern uint32_t OFZIPArchiveReadField32(const uint8_t *_Nonnull *_Nonnull,
    uint16_t *_Nonnull);
extern uint64_t OFZIPArchiveReadField64(const uint8_t *_Nonnull *_Nonnull,
    uint16_t *_Nonnull);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
