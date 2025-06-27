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
#import "OFLHAArchiveEntry.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;
@class OFStream;

/**
 * @class OFLHAArchive OFLHAArchive.h ObjFW/ObjFW.h
 *
 * @brief A class for accessing and manipulating LHA files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFLHAArchive: OFObject
{
	OFStream *_stream;
	uint_least8_t _mode;
	OFStringEncoding _encoding;
	OFLHAArchiveEntry *_Nullable _currentEntry;
#ifdef OF_LHA_ARCHIVE_M
@public
#endif
	OFStream *_Nullable _lastReturnedStream;
@protected
	bool _hasWritten;
}

/**
 * @brief The encoding to use for the archive. Defaults to UTF-8.
 */
@property (nonatomic) OFStringEncoding encoding;

/**
 * @brief Creates a new OFLHAArchive object with the specified stream.
 *
 * @param stream A stream from which the LHA archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFLHAArchive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode;

/**
 * @brief Creates a new OFLHAArchive object with the specified file.
 *
 * @param IRI The IRI to the LHA file
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFLHAArchive
 */
+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Creates an IRI for accessing the specified file within the specified
 *	  LHA archive.
 *
 * @param path The path of the file within the archive
 * @param IRI The IRI of the archive
 * @return An IRI for accessing the specified file within the specified LHA
 *	   archive
 */
+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFLHAArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the LHA archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFLHAArchive
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFLHAArchive object with the
 *	  specified file.
 *
 * @param IRI The IRI to the LHA file
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFLHAArchive
 */
- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Returns the next entry from the LHA archive or `nil` if all entries
 *	  have been read.
 *
 * @note This is only available in read mode.
 *
 * @warning Calling @ref nextEntry will invalidate all streams returned by
 *	    @ref streamForReadingCurrentEntry or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @return The next entry from the LHA archive or `nil` if all entries have
 *	   been read
 * @throw OFInvalidFormatException The archive's format is invalid
 * @throw OFUnsupportedVersionException The archive's format is of an
 *					unsupported version
 * @throw OFTruncatedDataException The archive was truncated
 */
- (nullable OFLHAArchiveEntry *)nextEntry;

/**
 * @brief Returns a stream for reading the current entry.
 *
 * @note This is only available in read mode.
 *
 * @note The returned stream conforms to @ref OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @return A stream for reading the current entry
 */
- (OFStream *)streamForReadingCurrentEntry;

/**
 * @brief Returns a stream for writing the specified entry.
 *
 * @note This is only available in write and append mode.
 *
 * @note The uncompressed size, compressed size and CRC16 of the specified
 *	 entry are ignored.
 *
 * @note The returned stream conforms to @ref OFReadyForWritingObserving if the
 *	 underlying stream does so, too.
 *
 * @warning Calling @ref streamForWritingEntry: will invalidate all streams
 *	    returned by @ref streamForReadingCurrentEntry or
 *	    @ref streamForWritingEntry:! Reading from or writing to an
 *	    invalidated stream will throw an @ref OFReadFailedException or
 *	    @ref OFWriteFailedException!
 *
 * @param entry The entry for which a stream for writing should be returned
 * @return A stream for writing the specified entry
 */
- (OFStream *)streamForWritingEntry: (OFLHAArchiveEntry *)entry;

/**
 * @brief Closes the OFLHAArchive.
 *
 * @throw OFNotOpenException The archive is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
