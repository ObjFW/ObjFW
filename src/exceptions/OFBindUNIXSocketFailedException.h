/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFBindSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindUNIXSocketFailedException \
 *	  OFBindUNIXSocketFailedException.h \
 *	  ObjFW/OFBindUNIXSocketFailedException.h
 *
 * @brief An exception indicating that binding a UNIX socket failed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFBindUNIXSocketFailedException: OFBindSocketFailedException
{
	OFString *_Nullable _path;
}

/**
 * @brief The path on which binding failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief Creates a new, autoreleased bind UNIX socket failed exception.
 *
 * @param path The path on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind UNIX socket failed exception
 */
+ (instancetype)exceptionWithPath: (nullable OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind UNIX socket failed exception.
 *
 * @param path The path on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind UNIX socket failed exception
 */
- (instancetype)initWithPath: (nullable OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
