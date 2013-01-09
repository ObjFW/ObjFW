/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

/*!
 * @brief A pool that keeps track of objects to release.
 *
 * The OFAutoreleasePool class is a class that keeps track of objects that will
 * be released when the autorelease pool is released.
 *
 * Every thread has its own stack of autorelease pools.
 */
@interface OFAutoreleasePool: OFObject
{
	void *pool;
	BOOL ignoreRelease;
}

/*!
 * @brief Adds an object to the autorelease pool at the top of the
 *	  thread-specific autorelease pool stack.
 *
 * @param object The object to add to the autorelease pool
 * @return The object
 */
+ (id)addObject: (id)object;

/*!
 * @brief Releases all objects in the autorelease pool.
 *
 * This does not free the memory allocated to store pointers to the objects in
 * the pool, so reusing the pool does not allocate any memory until the previous
 * number of objects is exceeded. It behaves this way to optimize loops that
 * always work with the same or similar number of objects and call relaseObjects
 * at the end of the loop, which is propably the most common case for
 * releaseObjects.
 *
 * If a garbage collector is added in the future, it will tell the GC that now
 * is a good time to clean up, as this is often used after a lot of objects
 * have been added to the pool that should be released before the next iteration
 * of a loop, which adds objects again. Thus, it is usually a clean up call.
 */
- (void)releaseObjects;

/*!
 * @brief Releases all objects in the autorelease pool and deallocates the pool.
 */
- (void)release;

/*!
 * @brief Releases all objects in the autorelease pool and deallocates the pool.
 */
- (void)drain;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern id of_autorelease(id);
#ifdef __cplusplus
}
#endif
