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
 * @class OFAlreadyOpenException \
 *	  OFAlreadyOpenException.h ObjFW/OFAlreadyOpenException.h
 *
 * @brief An exception indicating that an object is already open and thus
 *	  cannot be opened again.
 */
@interface OFAlreadyOpenException: OFException
{
	id _object;
	OF_RESERVE_IVARS(OFAlreadyOpenException, 4)
}

/**
 * @brief The object which is already open.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased already open exception.
 *
 * @param object The object which is already open
 * @return A new, autoreleased already open exception
 */
+ (instancetype)exceptionWithObject: (id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated already open exception.
 *
 * @param object The object which is already open
 * @return An initialized already open exception
 */
- (instancetype)initWithObject: (id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
