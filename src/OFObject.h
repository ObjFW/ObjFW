/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "objfw-defs.h"

#include <stddef.h>
#include <stdint.h>

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
#endif

/**
 * \brief A result of a comparison.
 */
typedef enum __of_comparison_result {
	/// The left object is smaller than the right
	OF_ORDERED_ASCENDING = -1,
	/// Both objects are equal
	OF_ORDERED_SAME = 0,
	/// The left object is bigger than the right
	OF_ORDERED_DESCENDING = 1
} of_comparison_result_t;

/**
 * \brief A range.
 */
typedef struct __of_range {
	size_t start;
	size_t length;
} of_range_t;

/**
 * \brief The root class for all other classes inside ObjFW.
 */
@interface OFObject
{
	/// The class of the object
	Class isa;
}

/**
 * This code is executed once when the class is loaded into the runtime.
 *
 * Derived classes can overide this to execute their own code when the class is
 * loaded.
 */
+ (void)load;

/**
 * This code is executed once when a method of the class is called for the first
 * time.
 *
 * Derived classes can override this to execute their own code on
 * initialization.
 */
+ (void)initialize;

/**
 * Allocates memory for an instance of the class and sets up the memory pool for
 * the object.
 *
 * alloc will never return nil, instead, it will throw an
 * OFAllocFailedException.
 *
 * \return The allocated object.
 */
+ alloc;

/**
 * \return The class
 */
+ (Class)class;

/**
 * \return The name of the class as a C string
 */
+ (const char*)className;

/**
 * \param class_ The class which is checked for being a superclass
 * \return A boolean whether the class class is a subclass of the specified
 *	   class
 */
+ (BOOL)isSubclassOfClass: (Class)class_;

/**
 * \return The superclass of the class
 */
+ (Class)superclass;

/**
 * Checks whether instances of the class respond to a given selector.
 *
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (BOOL)instancesRespondToSelector: (SEL)selector;

/**
 * Checks whether the class conforms to a given protocol.
 *
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the class conforms to the specified protocol
 */
+ (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \param selector The selector for which the method should be returned
 * \return The implementation of the instance method for the specified selector
 *	   or nil if it isn't implemented
 */
+ (IMP)instanceMethodForSelector: (SEL)selector;

/**
 * Replaces a class method implementation with another implementation.
 *
 * \param newimp The new implementation for the class method
 * \param selector The selector of the class method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newimp
	  forClassMethod: (SEL)selector;

/**
 * Replaces a class method with a class method from another class.
 *
 * \param selector The selector of the class method to replace
 * \param class_ The class from which the new class method should be taken
 * \return The old implementation
 */
+  (IMP)replaceClassMethod: (SEL)selector
  withClassMethodFromClass: (Class)class_;

/**
 * Replaces an instance method implementation with another implementation.
 *
 * \param newimp The new implementation for the instance method
 * \param selector The selector of the instance method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newimp
       forInstanceMethod: (SEL)selector;

/**
 * Replaces an instance method with an instance method from another class.
 *
 * \param selector The selector of the instance method to replace
 * \param class_ The class from which the new instance method should be taken
 * \return The old implementation
 */
+  (IMP)replaceInstanceMethod: (SEL)selector
  withInstanceMethodFromClass: (Class)class_;

/**
 * Initializes an already allocated object.
 *
 * Derived classes may override this, but need to do self = [super init] before
 * they do any initialization themselves. init may never return nil, instead
 * an exception (for example OFInitializationFailed) should be thrown.
 *
 * \return An initialized object
 */
- init;

/**
 * \return The class of the object
 */
- (Class)class;

/**
 * \return The name of the object's class as a C string
 */
- (const char*)className;

/**
 * \param class_ The class whose kind is checked
 * \return A boolean whether the object is of the specified kind
 */
- (BOOL)isKindOfClass: (Class)class_;

/**
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether the objects responds to the specified selector
 */
- (BOOL)respondsToSelector: (SEL)selector;

/**
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the objects conforms to the specified protocol
 */
- (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \param selector The selector for which the method should be returned
 *
 * \return The implementation for the specified selector
 */
- (IMP)methodForSelector: (SEL)selector;

/**
 * Checks two objects for equality.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \param obj The object which should be tested for equality
 * \return A boolean whether the object is equal to the specified object
 */
- (BOOL)isEqual: (OFObject*)obj;

/**
 * Calculates a hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \return A 32 bit hash for the object
 */
- (uint32_t)hash;

/**
 * Adds a pointer to the object's memory pool.
 *
 * This is useful to add memory allocated by functions such as asprintf to the
 * pool so it gets free'd automatically when the object is deallocated.
 *
 * \param ptr A pointer to add to the memory pool
 */
- addMemoryToPool: (void*)ptr;

/**
 * Allocates memory and stores it in the object's memory pool so it can be
 * free'd automatically when the object is deallocated.
 *
 * \param size The size of the memory to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryWithSize: (size_t)size;

/**
 * Allocates memory for the specified number of items and stores it in the
 * object's memory pool so it can be free'd automatically when the object is
 * deallocated.
 *
 * \param nitems The number of items to allocate
 * \param size The size of each item to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryForNItems: (size_t)nitems
		     withSize: (size_t)size;

/**
 * Resizes memory in the object's memory pool to the specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param size The new size for the memory chunk
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size;

/**
 * Resizes memory in the object's memory pool to the specific number of items of
 * the specified size.
 *
 * \param ptr A pointer to the already allocated memory
 * \param nitems The number of items to resize to
 * \param size The size of each item to resize to
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nitems
	     withSize: (size_t)size;

/**
 * Frees allocated memory and removes it from the object's memory pool.
 * Does nothing if ptr is NULL.
 *
 * \param ptr A pointer to the allocated memory
 */
- freeMemory: (void*)ptr;

/**
 * Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- retain;

/**
 * \return The retain count
 */
- (size_t)retainCount;

/**
 * Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/**
 * Adds the object to the topmost OFAutoreleasePool of the thread's release pool
 * stack.
 */
- autorelease;

/**
 * Deallocates the object and also frees all memory in its memory pool.
 *
 * It is also called when the retain count reaches zero.
 */
- (void)dealloc;
@end

/**
 * \brief A protocol for the creation of copies.
 */
@protocol OFCopying
/**
 * \return A copy of the object
 */
- (id)copy;
@end

/**
 * \brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying
/**
 * \return A copy of the object
 */
- (id)mutableCopy;
@end

extern size_t of_pagesize;
