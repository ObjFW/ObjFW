/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFArray.h"
#import "OFList.h"

/**
 * The OFAutoreleasePool class is a class that keeps track of objects that will
 * be released when the autorelease pool is released.
 *
 * Every thread has its own stack of autorelease pools.
 */
@interface OFAutoreleasePool: OFObject
{
	OFArray		  *objects;
	OFAutoreleasePool *next, *prev;
}

/**
 * Adds an object to the autorelease pool at the top of the thread-specific
 * stack.
 *
 * \param obj The object to add to the autorelease pool
 */
+ (void)addObjectToTopmostPool: (OFObject*)obj;

+ (void)releaseAll;

/**
 * Adds an object to the specific autorelease pool.
 *
 * \param obj The object to add to the autorelease pool
 */
- addObject: (OFObject*)obj;

/**
 * Releases all objects in the autorelease pool.
 *
 * If a garbage collector is added in the future, it will tell the GC that now
 * is a good time to clean up, as this is often used after a lot of objects
 * have been added to the pool that should be released before the next iteration
 * of a loop, which adds objects again. Thus, it is usually a clean up call.
 */
- releaseObjects;

/**
 * Releases all objects in the autorelease pool and deallocates the pool.
 */
- (void)release;

/**
 * Calling drain is equivalent to calling release.
 *
 * If a garbage collector is added in the future, it will tell the GC that now
 * is a good time to clean up.
 */
- (void)drain;
@end
