/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFNotImplementedException OFNotImplementedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a method or part of it is not
 *        implemented.
 */
@interface OFNotImplementedException: OFException
{
	SEL _selector;
	id _Nullable _object;
	OF_RESERVE_IVARS(OFNotImplementedException, 4)
}

/**
 * @brief The selector which is not or not fully implemented.
 */
@property (readonly, nonatomic) SEL selector;

/**
 * @brief The object which does not (fully) implement the selector.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased not implemented exception.
 *
 * @param selector The selector which is not or not fully implemented
 * @param object The object which does not (fully) implement the selector
 * @return A new, autoreleased not implemented exception
 */
+ (instancetype)exceptionWithSelector: (SEL)selector
			       object: (nullable id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated not implemented exception.
 *
 * @param selector The selector which is not or not fully implemented
 * @param object The object which does not (fully) implement the selector
 * @return An initialized not implemented exception
 */
- (instancetype)initWithSelector: (SEL)selector
			  object: (nullable id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
