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

#import "OFObject.h"
#import "OFLocking.h"
#import "OFPlainMutex.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFRecursiveMutex OFRecursiveMutex.h ObjFW/OFRecursiveMutex.h
 *
 * @brief A class for creating mutual exclusions which can be entered
 *	  recursively.
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
