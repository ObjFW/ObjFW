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
#import "OFSeekableStream.h"
#import "OFString.h"
#import "OFZooArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFZooArchive OFZooArchive.h ObjFW/ObjFW.h
 *
 * @brief A class for accessing and manipulating Zoo files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFZooArchive: OFObject
{
	OF_KINDOF(OFStream *) _stream;
	uint_least8_t _mode;
	OFStringEncoding _encoding;
	uint16_t _minVersionNeeded;
	uint8_t _headerType;
	OFString *_Nullable _archiveComment;
	OFZooArchiveEntry *_Nullable _currentEntry;
#ifdef OF_ZOO_ARCHIVE_M
@public
#endif
	OFStream *_Nullable _lastReturnedStream;
@protected
	OFStreamOffset _lastHeaderOffset;
	size_t _lastHeaderLength;
}

/**
 * @brief The encoding to use for the archive. Defaults to UTF-8.
 */
@property (nonatomic) OFStringEncoding encoding;

/**
 * @brief The archive comment.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *archiveComment;

/**
 * @brief Creates a new OFZooArchive object with the specified stream.
 *
 * @param stream A stream from which the Zoo archive will be read.
 *		 This needs to be an OFSeekableStream. For writing, the stream
 *		 needs to support both reading and writing at the same time.
 * @param mode The mode for the Zoo file. Valid modes are "r" for reading and
 *	       "w" for creating a new file.
 * @return A new, autoreleased OFZooArchive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode;

/**
 * @brief Creates a new OFZooArchive object with the specified file.
 *
 * @param IRI The IRI to the Zoo file
 * @param mode The mode for the Zoo file. Valid modes are "r" for reading and
 *	       "w" for creating a new file.
 * @return A new, autoreleased OFZooArchive
 */
+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Creates an IRI for accessing the specified file within the specified
 *	  Zoo archive.
 *
 * @param path The path of the file within the archive
 * @param IRI The IRI of the archive
 * @return An IRI for accessing the specified file within the specified Zoo
 *	   archive
 */
+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFZooArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the Zoo archive will be read.
 *		 This needs to be an OFSeekableStream. For writing, the stream
 *		 needs to support both reading and writing at the same time.
 * @param mode The mode for the Zoo file. Valid modes are "r" for reading and
 *	       "w" for creating a new file.
 * @return An initialized OFZooArchive
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFZooArchive object with the
 *	  specified file.
 *
 * @param IRI The IRI to the Zoo file
 * @param mode The mode for the Zoo file. Valid modes is "r" for reading and
 *	       "w" for creating a new file.
 * @return An initialized OFZooArchive
 */
- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Returns the next entry from the Zoo archive or `nil` if all entries
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
 * @return The next entry from the Zoo archive or `nil` if all entries have
 *	   been read
 * @throw OFInvalidFormatException The archive's format is invalid
 * @throw OFUnsupportedVersionException The archive's format is of an
 *					unsupported version
 * @throw OFTruncatedDataException The archive was truncated
 */
- (nullable OFZooArchiveEntry *)nextEntry;

/**
 * @brief Returns a stream for reading the current entry.
 *
 * @note This is only available in read mode.
 *
 * @note The returned stream conforms to @ref OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @return A stream for reading the current entry
 * @throw OFSeekFailedException Seeking to the data in the archive failed
 */
- (OFStream *)streamForReadingCurrentEntry;

/**
 * @brief Returns a stream for writing the specified entry.
 *
 * @note This is only available in write and append mode.
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
 * @param entry The entry for which a stream for writing should be returned.@n
 *	        The following parts of the specified entry will be ignored:
 *	          * The header type.
 *	          * The minimum version needed.
 *	          * The compressed size.
 *	          * The uncompressed size.
 *	          * The CRC16.
 * @return A stream for writing the specified entry
 */
- (OFStream *)streamForWritingEntry: (OFZooArchiveEntry *)entry;

/**
 * @brief Closes the OFZooArchive.
 *
 * @throw OFNotOpenException The archive is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
