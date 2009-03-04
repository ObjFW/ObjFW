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

#import <objc/Object.h>

#include <stdint.h>

/**
 * The OFObject class is the base class for all other classes inside ObjFW.
 */
@interface OFObject: Object
{
	void   **__memchunks;
	size_t __memchunks_size;
	size_t __retain_count;
}

/**
 * Initialize the already allocated object.
 * Also sets up the memory pool for the object.
 *
 * \return An initialized object
 */
- init;

/**
 * Increases the retain count.
 */
- retain;

/**
 * Decreases the retain cound and frees the object if it reaches 0.
 */
- (void)release;

/**
 * Adds the object to the autorelease pool that is on top of the thread's stack.
 */
- autorelease;

/**
 * \return The retain count
 */
- (size_t)retainCount;

/**
 * Frees the object and also frees all memory allocated via its memory pool.
 */
- free;

/**
 * Compare two objects.
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \param obj The object which is tested for equality
 * \return A boolean whether the object is equal to the other object
 */
- (BOOL)isEqual: (id)obj;

/**
 * Calculate a hash for the object.
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \return A 24 bit hash for the object
 */
- (uint32_t)hash;

/**
 * Adds a pointer to the memory pool.
 * This is useful to add memory allocated by functions such as asprintf to the
 * pool so it gets freed automatically when the object is freed.
 *
 * \param ptr A pointer to add to the memory pool
 */
- addToMemoryPool: (void*)ptr;

/**
 * Allocate memory and store it in the objects memory pool so it can be free'd
 * automatically when the object is free'd.
 *
 * \param size The size of the memory to allocate
 * \return A pointer to the allocated memory
 */
- (void*)getMemWithSize: (size_t)size;

/**
 * Allocate memory for a specified number of items and store it in the objects
 * memory pool so it can be free'd automatically when the object is free'd.
 *
 * \param nitems The number of items to allocate
 * \param size The size of each item to allocate
 * \return A pointer to the allocated memory
 */
- (void*)getMemForNItems: (size_t)nitems
		  ofSize: (size_t)size;

/**
 * Resize memory in the memory pool to a specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param size The new size for the memory chunk
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size;

/**
 * Resize memory in the memory pool to a specific number of items of a
 * specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param nitems The number of items to resize to
 * \param size The size of each item to resize to
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMem: (void*)ptr
	  toNItems: (size_t)nitems
	    ofSize: (size_t)size;

/**
 * Frees allocated memory and removes it from the memory pool.
 *
 * \param ptr A pointer to the allocated memory
 */
- freeMem: (void*)ptr;
@end
