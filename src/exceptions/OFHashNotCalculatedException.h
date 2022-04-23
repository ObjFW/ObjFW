/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

/**
 * @class OFHashNotCalculatedException OFHashNotCalculatedException.h \
 *	  ObjFW/OFHashNotCalculatedException.h
 *
 * @brief An exception indicating that the hash has not been calculated yet.
 */
@interface OFHashNotCalculatedException: OFException
{
	id _object;
}

/**
 * @brief The hash which has not been calculated yet.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased hash not calculated exception.
 *
 * @param object The hash which has not been calculated yet
 * @return A new, autoreleased hash not calculated exception
 */
+ (instancetype)exceptionWithObject: (id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated hash not calculated exception.
 *
 * @param object The hash which has not been calculated yet
 * @return An initialized hash not calculated exception
 */
- (instancetype)initWithObject: (id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
