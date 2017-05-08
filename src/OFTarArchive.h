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
#import "OFTarArchiveEntry.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFStream;

/*!
 * @class OFTarArchive OFTarArchive.h ObjFW/OFTarArchive.h
 *
 * @brief A class for accessing and manipulating tar archives.
 */
@interface OFTarArchive: OFObject
{
#ifdef OF_TAR_ARCHIVE_ENTRY_M
@public
#endif
	OFStream *_stream;
@protected
	OFTarArchiveEntry *_lastReturnedEntry;
}

/*!
 * @brief Creates a new OFTarArchive object with the specified stream.
 *
 * @param stream A stream from which the tar archive will be read
 * @return A new, autoreleased OFTarArchive
 */
+ (instancetype)archiveWithStream: (OFStream *)stream;

#ifdef OF_HAVE_FILES
/*!
 * @brief Creates a new OFTarArchive object with the specified file.
 *
 * @param path The path to the tar archive
 * @return A new, autoreleased OFTarArchive
 */
+ (instancetype)archiveWithPath: (OFString *)path;
#endif

/*!
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified stream.
 *
 * @param stream A stream from which the tar archive will be read
 * @return An initialized OFTarArchive
 */
- initWithStream: (OFStream *)stream OF_DESIGNATED_INITIALIZER;

#ifdef OF_HAVE_FILES
/*!
 * @brief Initializes an already allocated OFTarArchive object with the
 *	  specified file.
 *
 * @param path The path to the tar archive
 * @return An initialized OFTarArchive
 */
- initWithPath: (OFString *)path;
#endif

/*!
 * @brief Returns the next entry from the tar archive or `nil` if all entries
 *	  have been read.
 *
 * @warning Calling @ref nextEntry will invalidate all streams returned by the
 *	    previous entry! Reading from an invalidated stream will throw an
 *	    @ref OFReadFailedException!
 *
 * @return The next entry from the tar archive or `nil` if all entries have
 *	   been read
 */
- (OFTarArchiveEntry *)nextEntry;
@end

OF_ASSUME_NONNULL_END
