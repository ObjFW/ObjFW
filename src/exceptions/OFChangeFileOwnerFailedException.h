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
/*!
 * @brief An exception indicating that changing the owner of a file failed.
 */
@interface OFChangeFileOwnerFailedException: OFException
{
	OFString *path;
	OFString *owner;
	OFString *group;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy, nonatomic) OFString *path;
@property (readonly, copy, nonatomic) OFString *owner;
@property (readonly, copy, nonatomic) OFString *group;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased change file owner failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param path The path of the file
 * @param owner The new owner for the file
 * @param group The new group for the file
 * @return A new, autoreleased change file owner failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			      path: (OFString*)path
			     owner: (OFString*)owner
			     group: (OFString*)group;

/*!
 * @brief Initializes an already allocated change file owner failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param path The path of the file
 * @param owner The new owner for the file
 * @param group The new group for the file
 * @return An initialized change file owner failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	  owner: (OFString*)owner
	  group: (OFString*)group;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;

/*!
 * @brief Returns the path of the file.
 *
 * @return The path of the file
 */
- (OFString*)path;

/*!
 * @brief Returns the new owner for the file.
 *
 * @return The new owner for the file
 */
- (OFString*)owner;

/*!
 * @brief Returns the new group for the file.
 *
 * @return The new group for the file
 */
- (OFString*)group;
@end
#endif
