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

#include <stddef.h>
#include <stdint.h>

#import <objc/objc.h>
#ifndef __objc_INCLUDE_GNU
#import <objc/message.h>
#endif

/**
 * The OFObject class is the base class for all other classes inside ObjFW.
 */
@interface OFObject
{
	Class  isa;
}

/**
 * This code is executed once when a method of the class is called for the first
 * time.
 * Derived classes can override this to execute their own code on
 * initialization.
 */
+ (void)initialize;

/**
 * Allocates memory for an instance of the class.
 *
 * alloc will never return nil, instead, it will throw an 
 * OFAllocFailedException.
 *
 * \return The allocated object.
 */
+ alloc;

/**
 * \return The class pointer
 */
+ (Class)class;

/**
 * \return The name of the class as a C string
 */
+ (const char*)name;

/**
 * Replace a method with a method from another class.
 *
 * \param selector The selector of the method to replace
 * \param class The class from which the new method should be taken
 * \return The old implementation
 */
+ (IMP)replaceMethod: (SEL)selector
 withMethodFromClass: (Class)class;

/**
 * Initialize the already allocated object.
 * Also sets up the memory pool for the object.
 *
 * Derived classes may override this, but need to do self = [super init] before
 * they do any initialization themselves. init may never return nil, instead
 * an exception (for example OFInitializationFailed) should be thrown.
 *
 * \return An initialized object
 */
- init;

/**
 * \return A pointer to the class of the instance
 */
- (Class)class;

/**
 * \return The name of the instance's class as a C string
 */
- (const char*)name;

/**
 * \param class The class whose kind is checked
 *
 * \return A boolean whether the object is of the specified kind
 */
- (BOOL)isKindOf: (Class)class;

/**
 * \param selector The selector which should be checked
 *
 * \return A boolean whether the objects responds to the specified selector
 */
- (BOOL)respondsTo: (SEL)selector;

/**
 * \param selector The selector for which the method should be returned
 *
 * \return The implementation for the specified selector
 */
- (IMP)methodFor: (SEL)selector;

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
 * \return A 32 bit hash for the object
 */
- (uint32_t)hash;

/**
 * Adds a pointer to the memory pool.
 *
 * This is useful to add memory allocated by functions such as asprintf to the
 * pool so it gets free'd automatically when the object is deallocated.
 *
 * \param ptr A pointer to add to the memory pool
 */
- addToMemoryPool: (void*)ptr;

/**
 * Allocate memory and store it in the objects memory pool so it can be free'd
 * automatically when the object is deallocated.
 *
 * \param size The size of the memory to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocWithSize: (size_t)size;

/**
 * Allocate memory for a specified number of items and store it in the objects
 * memory pool so it can be free'd automatically when the object is deallocated.
 *
 * \param nitems The number of items to allocate
 * \param size The size of each item to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocNItems: (size_t)nitems
	    withSize: (size_t)size;

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
	  withSize: (size_t)size;

/**
 * Frees allocated memory and removes it from the memory pool.
 *
 * \param ptr A pointer to the allocated memory
 */
- freeMem: (void*)ptr;

/**
 * Increases the retain count.
 */
- retain;

/**
 * Adds the object to the autorelease pool that is on top of the thread's stack.
 */
- autorelease;

/**
 * \return The retain count
 */
- (size_t)retainCount;

/**
 * Decreases the retain cound and deallocates the object if it reaches 0.
 */
- (void)release;

/**
 * Deallocates the object and also frees all memory allocated via its memory
 * pool.
 */
- (void)dealloc;
@end
