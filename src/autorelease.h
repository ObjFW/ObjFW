/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#ifdef __cplusplus
extern "C" {
#endif
/*! @file */

/*!
 * @brief Creates a new autorelease pool.
 *
 * @return An identifier for the created autorelease pool
 */
extern void* objc_autoreleasePoolPush();

/*!
 * @brief Drains an autorelease pool.
 *
 * @param pool An identifier for the pool to drain
 */
extern void objc_autoreleasePoolPop(void *pool);

/*!
 * @brief Autoreleases an object.
 *
 * @param object The object to autorelease
 * @return The autoreleased object
 */
extern id _objc_rootAutorelease(id object);
#ifdef __cplusplus
}
#endif
