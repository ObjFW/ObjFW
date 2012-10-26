/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "threading.h"

/**
 * \brief A class for creating mutual exclusions.
 */
@interface OFMutex: OFObject
{
	of_mutex_t mutex;
	BOOL initialized;
}

/**
 * \brief Creates a new mutex.
 *
 * \return A new autoreleased mutex.
 */
+ (instancetype)mutex;

- OF_initWithoutCreatingMutex;

/**
 * \brief Locks the mutex.
 */
- (void)lock;

/**
 * \brief Tries to lock the mutex.
 *
 * \return A boolean whether the mutex could be acquired
 */
- (BOOL)tryLock;

/**
 * \brief Unlocks the mutex.
 */
- (void)unlock;
@end
