/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
#import "OFKernelEventObserver.h"
#import "OFLHAArchiveEntry.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

/*!
 * @class OFLHAArchive OFLHAArchive.h ObjFW/OFLHAArchive.h
 *
 * @brief A class for accessing and manipulating LHA files.
 */
@interface OFLHAArchive: OFObject
{
	OF_KINDOF(OFStream *) _stream;
	of_string_encoding_t _encoding;
	OF_KINDOF(OFStream *) _Nullable _lastReturnedStream;
}

/*!
 * @brief The encoding to use for the archive. Defaults to ISO 8859-1.
 */
@property (nonatomic) of_string_encoding_t encoding;

/*!
 * @brief A stream for reading the current entry.
 *
 * @note This is only available in read mode.
 *
 * @note The returned stream only conforms to @ref OFReadyForReadingObserving if
 *	 the underlying stream does so, too.
 */
@property (readonly, nonatomic)
    OFStream <OFReadyForReadingObserving> *streamForReadingCurrentEntry;

/*!
 * @brief Creates a new OFLHAArchive object with the specified stream.
 *
 * @param stream A stream from which the LHA archive will be read.
 *		 For read and append mode, this needs to be an OFSeekableStream.
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFLHAArchive
 */
+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode;

#ifdef OF_HAVE_FILES
/*!
 * @brief Creates a new OFLHAArchive object with the specified file.
 *
 * @param path The path to the LHA file
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return A new, autoreleased OFLHAArchive
 */
+ (instancetype)archiveWithPath: (OFString *)path
			   mode: (OFString *)mode;
#endif

- (instancetype)init OF_UNAVAILABLE;

/*!
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
- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;

#ifdef OF_HAVE_FILES
/*!
 * @brief Initializes an already allocated OFLHAArchive object with the
 *	  specified file.
 *
 * @param path The path to the LHA file
 * @param mode The mode for the LHA file. Valid modes are "r" for reading,
 *	       "w" for creating a new file and "a" for appending to an existing
 *	       archive.
 * @return An initialized OFLHAArchive
 */
- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode;
#endif

/*!
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
 */
- (nullable OFLHAArchiveEntry *)nextEntry;

/*!
 * @brief Closes the OFLHAArchive.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
