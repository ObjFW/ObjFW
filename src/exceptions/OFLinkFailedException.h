/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFException.h"

#ifndef _WIN32
/**
 * \brief An exception indicating that creating a link failed.
 */
@interface OFLinkFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

# ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
# endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The source for the link
 * \param dest The destination for the link
 * \return A new link failed exception
 */
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest;

/**
 * Initializes an already allocated link failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The source for the link
 * \param dest The destination for the link
 * \return An initialized link failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string with the source for the link
 */
- (OFString*)sourcePath;

/**
 * \return A string with the destination for the link
 */
- (OFString*)destinationPath;
@end
#endif
