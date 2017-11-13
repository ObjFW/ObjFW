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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFURL;

/*!
 * @class OFLinkFailedException \
 *	  OFLinkFailedException.h ObjFW/OFLinkFailedException.h
 *
 * @brief An exception indicating that creating a link failed.
 */
@interface OFLinkFailedException: OFException
{
	OFURL *_sourceURL, *_destinationURL;
	int _errNo;
}

/*!
 * A URL with the source for the link.
 */
@property (readonly, nonatomic) OFURL *sourceURL;

/*!
 * A URL with the destination for the link.
 */
@property (readonly, nonatomic) OFURL *destinationURL;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased link failed exception.
 *
 * @param sourceURL The source for the link
 * @param destinationURL The destination for the link
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased link failed exception
 */
+ (instancetype)exceptionWithSourceURL: (OFURL *)sourceURL
			destinationURL: (OFURL *)destinationURL
				 errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated link failed exception.
 *
 * @param sourceURL The source for the link
 * @param destinationURL The destination for the link
 * @param errNo The errno of the error that occurred
 * @return An initialized link failed exception
 */
- (instancetype)initWithSourceURL: (OFURL*)sourceURL
		   destinationURL: (OFURL *)destinationURL
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
