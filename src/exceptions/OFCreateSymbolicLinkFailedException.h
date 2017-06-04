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

/*!
 * @class OFCreateSymbolicLinkFailedException \
 *	  OFCreateSymbolicLinkFailedException.h \
 *	  ObjFW/OFCreateSymbolicLinkFailedException.h
 *
 * @brief An exception indicating that creating a symbolic link failed.
 */
@interface OFCreateSymbolicLinkFailedException: OFException
{
	OFString *_sourcePath, *_destinationPath;
	int _errNo;
}

/*!
 * The source for the symlink.
 */
@property (readonly, nonatomic) OFString *sourcePath;

/*!
 * The destination for the symlink.
 */
@property (readonly, nonatomic) OFString *destinationPath;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased create symbolic link failed exception.
 *
 * @param sourcePath The source for the symbolic link
 * @param destinationPath The destination for the symbolic link
 * @return A new, autoreleased create symbolic link failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString *)sourcePath
			destinationPath: (OFString *)destinationPath;

/*!
 * @brief Creates a new, autoreleased create symbolic link failed exception.
 *
 * @param sourcePath The source for the symbolic link
 * @param destinationPath The destination for the symbolic link
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased create symbolic link failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString *)sourcePath
			destinationPath: (OFString *)destinationPath
				  errNo: (int)errNo;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated create symbolic link failed
 *	  exception.
 *
 * @param sourcePath The source for the symbolic link
 * @param destinationPath The destination for the symbolic link
 * @return An initialized create symbolic link failed exception
 */
- initWithSourcePath: (OFString *)sourcePath
     destinationPath: (OFString *)destinationPath;

/*!
 * @brief Initializes an already allocated create symbolic link failed
 *	  exception.
 *
 * @param sourcePath The source for the symbolic link
 * @param destinationPath The destination for the symbolic link
 * @param errNo The errno of the error that occurred
 * @return An initialized create symbolic link failed exception
 */
- initWithSourcePath: (OFString *)sourcePath
     destinationPath: (OFString *)destinationPath
	       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
