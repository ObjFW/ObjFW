/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @class OFAllocFailedException OFAllocFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating an object could not be allocated.
 *
 * This exception is preallocated, as when there's no memory, no exception can
 * be allocated of course. That's why you shouldn't and even can't deallocate
 * it.
 *
 * This is the only exception which is not an OFException as it's special. It
 * does not know for which class allocation failed and it should not be handled
 * like other exceptions, as the exception handling code is not allowed to
 * allocate *any* memory.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFAllocFailedException: OFObject
+ (instancetype)exception OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns a description of the exception.
 *
 * @return A description of the exception
 */
- (OFString *)description;
@end

OF_ASSUME_NONNULL_END
