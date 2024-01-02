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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFNotOpenException OFNotOpenException.h ObjFW/OFNotOpenException.h
 *
 * @brief An exception indicating an object is not open, connected or bound.
 */
@interface OFNotOpenException: OFException
{
	id _object;
	OF_RESERVE_IVARS(OFNotOpenException, 4)
}

/**
 * @brief The object which is not open, connected or bound.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased not open exception.
 *
 * @param object The object which is not open, connected or bound
 * @return A new, autoreleased not open exception
 */
+ (instancetype)exceptionWithObject: (id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated not open exception.
 *
 * @param object The object which is not open, connected or bound
 * @return An initialized not open exception
 */
- (instancetype)initWithObject: (id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
