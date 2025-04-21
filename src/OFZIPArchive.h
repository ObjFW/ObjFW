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
#import "OFString.h"
#import "OFZIPArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFSeekableStream;
@class OFStream;
@class OFZIPArchive;

/**
 * @protocol OFZIPArchiveDelegate OFZIPArchive.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFZIPArchive.
 */
@protocol OFZIPArchiveDelegate <OFObject>
@optional
/**
 * @brief A callback that is called when an @ref OFZIPArchive wants to read a
 *	  different archive part.
 *
 * @param archive The archive that wants to read another part
 * @param partNumber The number of the part the archive wants to read
 * @param lastPartNumber The number of the last archive part
 * @return The stream to read the needed part, or `nil` if no such part exists
 */
- (nullable OFSeekableStream *)archive: (OFZIPArchive *)archive
		     wantsPartNumbered: (unsigned int)partNumber
			lastPartNumber: (unsigned int)lastPartNumber;
@end

/**
 * @class OFZIPArchive OFZIPArchive.h ObjFW/ObjFW.h
 *
 * @brief A class for accessing and manipulating ZIP files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFZIPArchive: OFObject
{
#ifdef OF_ZIP_ARCHIVE_M
@public
#endif
	OFObject <OFZIPArchiveDelegate> *_Nullable _delegate;
	OF_KINDOF(OFStream *) _stream;
	int64_t _offset;
	uint_least8_t _mode;
	uint32_t _diskNumber, _lastDiskNumber;
@protected
	uint32_t _centralDirectoryDisk;
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
 * @brief The delegate of the ZIP archive.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    OFObject <OFZIPArchiveDelegate> *delegate;

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
 * @throw OFInvalidFormatException The format is not that of a valid ZIP archive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream mode: (OFString *)mode;

/**
 * @brief Creates a new OFZIPArchive object with the specified file.
 *
 * @param IRI The IRI to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFZIPArchive
 * @throw OFInvalidFormatException The format is not that of a valid ZIP archive
 */
+ (instancetype)archiveWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Creates an IRI for accessing the specified file within the specified
 *	  ZIP archive.
 *
 * @param path The path of the file within the archive
 * @param IRI The IRI of the archive
 * @return An IRI for accessing the specified file within the specified ZIP
 *	   archive
 */
+ (OFIRI *)IRIForFilePath: (OFString *)path inArchiveWithIRI: (OFIRI *)IRI;

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
 * @throw OFInvalidFormatException The format is not that of a valid ZIP archive
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFZIPArchive object with the
 *	  specified file.
 *
 * @param IRI The IRI to the ZIP file
 * @param mode The mode for the ZIP file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFZIPArchive
 * @throw OFInvalidFormatException The format is not that of a valid ZIP archive
 */
- (instancetype)initWithIRI: (OFIRI *)IRI mode: (OFString *)mode;

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
 * @throw OFNotOpenException The archive is not open
 * @throw OFInvalidArgumentException The archive is not in read mode
 * @throw OFOpenItemFailedException Opening the specified file within the
 *				    archive failed
 * @throw OFInvalidFormatException The local header and the header in the
 *				   central directory do not match enough
 * @throw OFUnsupportedVersionException The file uses a version of the ZIP
 *					format that is not supported
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
 * @throw OFNotOpenException The archive is not open
 * @throw OFInvalidArgumentException The archive is not in write mode
 * @throw OFOpenItemFailedException Opening the specified file within the
 *				    archive failed. If
 *				    @ref OFOpenItemFailedException#errNo is
 *				    `EEXIST`, it failed because there is
 *				    already a file with the same name in the
 *				    archive.
 * @throw OFNotImplementedException The desired compression method is not
 *				    implemented
 */
- (OFStream *)streamForWritingEntry: (OFZIPArchiveEntry *)entry;

/**
 * @brief Closes the OFZIPArchive.
 *
 * @throw OFNotOpenException The archive is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
