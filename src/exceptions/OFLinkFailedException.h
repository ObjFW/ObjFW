/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <errno.h>

#import "OFException.h"

#ifdef OF_HAVE_LINK
/*!
 * @class OFLinkFailedException \
 *	  OFLinkFailedException.h ObjFW/OFLinkFailedException.h
 *
 * @brief An exception indicating that creating a link failed.
 */
@interface OFLinkFailedException: OFException
{
	OFString *_sourcePath, *_destinationPath;
	int _errNo;
}

# ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *sourcePath, *destinationPath;
@property (readonly) int errNo;
# endif

/*!
 * @brief Creates a new, autoreleased link failed exception.
 *
 * @param sourcePath The source for the link
 * @param destinationPath The destination for the link
 * @return A new, autoreleased link failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath;

/*!
 * @brief Initializes an already allocated link failed exception.
 *
 * @param sourcePath The source for the link
 * @param destinationPath The destination for the link
 * @return An initialized link failed exception
 */
- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath;

/*!
 * @brief Returns a string with the source for the link.
 *
 * @return A string with the source for the link
 */
- (OFString*)sourcePath;

/*!
 * @brief Returns a string with the destination for the link.
 *
 * @return A string with the destination for the link
 */
- (OFString*)destinationPath;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
#endif
