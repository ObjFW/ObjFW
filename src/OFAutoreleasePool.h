/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFArray.h"
#import "OFList.h"

/**
 * The OFAutoreleasePool class provides a class that keeps track of objects
 * that will be released when the autorelease pool is released.
 * Every thread has its own stack of autorelease pools.
 */
@interface OFAutoreleasePool: OFObject
{
	OFArray		 *objects;
	of_list_object_t *listobj;
}

/**
 * Adds an object to the autorelease pool at the top of the thread-specific
 * stack.
 *
 * \param obj The object to add to the autorelease pool
 */
+ (void)addObjectToTopmostPool: (OFObject*)obj;

/**
 * Adds an object to the specific autorelease pool.
 *
 * \param obj The object to add to the autorelease pool
 */
- addObject: (OFObject*)obj;

/**
 * Releases all objects in the autorelease pool.
 */
- releaseObjects;
@end
