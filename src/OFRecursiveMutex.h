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
#import "OFLocking.h"
#import "OFPlainMutex.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFRecursiveMutex OFRecursiveMutex.h ObjFW/ObjFW.h
 *
 * @brief A class for creating mutual exclusions which can be entered
 *	  recursively.
 *
 * If the mutex is deallocated while being held, it throws an
 * @ref OFStillLockedException. While this might break ARC's assumption that no
 * object ever throws in dealloc, it is considered a fatal programmer error
 * that should terminate the application.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFRecursiveMutex: OFObject <OFLocking>
{
	OFPlainRecursiveMutex _rmutex;
	bool _initialized;
	OFString *_Nullable _name;
	OF_RESERVE_IVARS(OFRecursiveMutex, 4)
}

/**
 * @brief Creates a new recursive mutex.
 *
 * @return A new autoreleased recursive mutex.
 */
+ (instancetype)mutex;
@end

OF_ASSUME_NONNULL_END
