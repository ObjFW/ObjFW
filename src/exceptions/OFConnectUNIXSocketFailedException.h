/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFConnectSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFConnectUNIXSocketFailedException \
 *	  OFConnectUNIXSocketFailedException.h \
 *	  ObjFW/OFConnectUNIXSocketFailedException.h
 *
 * @brief An exception indicating that a UNIX socket connection could not be
 *	  established.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFConnectUNIXSocketFailedException: OFConnectSocketFailedException
{
	OFString *_Nullable _path;
}

/**
 * @brief The path to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief Creates a new, autoreleased connect UNIX socket failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connect UNIX socket failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated connect UNIX socket failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connect UNIX socket failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
