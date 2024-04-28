/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFString.h"
#import "OFTarArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;
@class OFStream;

/**
 * @class OFTarArchive OFTarArchive.h ObjFW/OFTarArchive.h
 *
 * @brief A class for accessing and manipulating tar archives.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFTarArchive: OFObject
{
	OFStream *_stream;
	uint_least8_t _mode;
	OFStringEncoding _encoding;
	OFTarArchiveEntry *_Nullable _currentEntry;
#ifdef OF_TAR_ARCHIVE_M
@public
#endif
	OFStream *_Nullable _lastReturnedStream;
}

/**
 * @brief The encoding to use for the archive. Defaults to UTF-8.
 */
@property (nonatomic) OFStringEncoding encoding;

/**
 * @brief Creates a new OFTarArchive object with the specified stream.
 *
 * @param stream A stream from which the tar archive will be read.
 *		 For append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFTarArchive
 * @throw OFInvalidFormatException The archive has an invalid format
 * @throw OFSeekFailedException The archive was open in append mode and seeking
 *				failed
 */
+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode;

/**
 * @brief Creates a new OFTarArchive object with the specified file.
 *
 * @param IRI The IRI to the tar archive
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFTarArchive
 * @throw OFInvalidFormatException The archive has an invalid format
 * @throw OFSeekFailedException The archive was open in append mode and seeking
 *				failed
 */
+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Creates an IRI for accessing the specified file within the specified
 *	  tar archive.
 *
 * @param path The path of the file within the archive
 * @param IRI The IRI of the archive
 * @return An IRI for accessing the specified file within the specified tar
 *	   archive
 */
+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the tar archive will be read.
 *		 For append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFTarArchive
 * @throw OFInvalidFormatException The archive has an invalid format
 * @throw OFSeekFailedException The archive was open in append mode and seeking
 *				failed
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified file.
 *
 * @param IRI The IRI to the tar archive
 * @param mode The mode for the tar file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFTarArchive
 * @throw OFInvalidFormatException The archive has an invalid format
 * @throw OFSeekFailedException The archive was open in append mode and seeking
 *				failed
 */
- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Returns the next entry from the tar archive or `nil` if all entries
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
 * @return The next entry from the tar archive or `nil` if all entries have
 *	   been read
 * @throw OFInvalidFormatException The archive has an invalid format
 */
- (nullable OFTarArchiveEntry *)nextEntry;

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
- (OFStream *)streamForWritingEntry: (OFTarArchiveEntry *)entry;

/**
 * @brief Closes the OFTarArchive.
 *
 * @throw OFNotOpenException The archive is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
