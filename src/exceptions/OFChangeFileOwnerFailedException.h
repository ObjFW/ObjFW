/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
 * \brief An exception indicating that changing the owner of a file failed.
 */
@interface OFChangeFileOwnerFailedException: OFException
{
	OFString *path;
	OFString *owner;
	OFString *group;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, assign) OFString *path;
@property (readonly, assign) OFString *owner;
@property (readonly, assign) OFString *group;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param owner The new owner for the file
 * \param group The new group for the file
 * \return An initialized change file owner failed exception
 */
+ exceptionWithClass: (Class)class_
		path: (OFString*)path
	       owner: (OFString*)owner
	       group: (OFString*)group;

/**
 * Initializes an already allocated change file owner failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param owner The new owner for the file
 * \param group The new group for the file
 * \return An initialized change file owner failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	  owner: (OFString*)owner
	  group: (OFString*)group;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the file
 */
- (OFString*)path;

/**
 * \return The new owner for the file
 */
- (OFString*)owner;

/**
 * \return The new group for the file
 */
- (OFString*)group;
@end
#endif
