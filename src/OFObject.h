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

#import "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
#endif

#define OF_RETAIN_COUNT_MAX UINT_MAX
#define OF_INVALID_INDEX SIZE_MAX

/**
 * \brief A result of a comparison.
 */
typedef enum of_comparison_result_t {
	/// The left object is smaller than the right
	OF_ORDERED_ASCENDING = -1,
	/// Both objects are equal
	OF_ORDERED_SAME = 0,
	/// The left object is bigger than the right
	OF_ORDERED_DESCENDING = 1
} of_comparison_result_t;

/**
 * \brief An enum for storing endianess.
 */
typedef enum of_endianess_t {
	OF_ENDIANESS_BIG_ENDIAN,
	OF_ENDIANESS_LITTLE_ENDIAN
} of_endianess_t;

/**
 * \brief A range.
 */
typedef struct of_range_t {
	/// The start of the range
	size_t start;
	/// The length of the range
	size_t length;
} of_range_t;

/**
 * \brief A point.
 */
typedef struct of_point_t {
	float x;
	float y;
} of_point_t;

/**
 * \brief A dimension.
 */
typedef struct of_dimension_t {
	float width;
	float height;
} of_dimension_t;

/**
 * \brief A rectangle.
 */
typedef struct of_rectangle_t
{
	of_point_t origin;
	of_dimension_t size;
} of_rectangle_t;

@class OFString;

/**
 * \brief The protocol which all root classes implement.
 */
@protocol OFObject
/**
 * \brief Returns the class of the object.
 *
 * \return The class of the object
 */
- (Class)class;

/**
 * \brief Returns a boolean whether the object of the specified kind.
 *
 * \param class_ The class whose kind is checked
 * \return A boolean whether the object is of the specified kind
 */
- (BOOL)isKindOfClass: (Class)class_;

/**
 * \brief Returns a boolean whether the object is a member of the specified
 *	  class.
 *
 * \param class_ The class for which the receiver is checked
 * \return A boolean whether the object is a member of the specified class
 */
- (BOOL)isMemberOfClass: (Class)class_;

/**
 * \brief Returns a boolean whether the object responds to the specified
 *	  selector.
 *
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether the objects responds to the specified selector
 */
- (BOOL)respondsToSelector: (SEL)selector;

/**
 * \brief Checks whether the object conforms to the specified protocol.
 *
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the object conforms to the specified protocol
 */
- (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \brief Returns the implementation for the specified selector.
 *
 * \param selector The selector for which the method should be returned
 * \return The implementation for the specified selector
 */
- (IMP)methodForSelector: (SEL)selector;

/**
 * \brief Returns the type encoding for the specified selector.
 *
 * \param selector The selector for which the type encoding should be returned
 * \return The type encoding for the specified selector
 */
- (const char*)typeEncodingForSelector: (SEL)selector;

/**
 * \brief Performs the specified selector.
 *
 * \param selector The selector to perform
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector;

/**
 * \brief Performs the specified selector with the specified object.
 *
 * \param selector The selector to perform
 * \param object The object that is passed to the method specified by the
 *		 selector
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector
	   withObject: (id)object;

/**
 * \brief Performs the specified selector with the specified objects.
 *
 * \param selector The selector to perform
 * \param object The first object that is passed to the method specified by the
 *		 selector
 * \param otherObject The second object that is passed to the method specified
 *		      by the selector
 * \return The object returned by the method specified by the selector
 */
- (id)performSelector: (SEL)selector
	   withObject: (id)object
	   withObject: (id)otherObject;

/**
 * \brief Checks two objects for equality.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \param object The object which should be tested for equality
 * \return A boolean whether the object is equal to the specified object
 */
- (BOOL)isEqual: (id)object;

/**
 * \brief Calculates a hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * \return A 32 bit hash for the object
 */
- (uint32_t)hash;

/**
 * \brief Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- retain;

/**
 * \brief Returns the retain count.
 *
 * \return The retain count
 */
- (unsigned int)retainCount;

/**
 * \brief Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/**
 * \brief Adds the object to the topmost OFAutoreleasePool of the thread's
 *	  autorelease pool stack.
 *
 * \return The object
 */
- autorelease;

/**
 * \brief Returns the receiver.
 *
 * \return The receiver
 */
- self;

/**
 * \brief Returns whether the object is a proxy object.
 *
 * \return A boolean whether the object is a proxy object
 */
- (BOOL)isProxy;
@end

/**
 * \brief The root class for all other classes inside ObjFW.
 */
@interface OFObject <OFObject>
{
@public
	/// The class of the object
	Class isa;
}

/**
 * \brief A method which is called once when the class is loaded into the
 *	  runtime.
 *
 * Derived classes can overide this to execute their own code when the class is
 * loaded.
 */
+ (void)load;

/**
 * \brief A method which is called the moment before the first call to the class
 *	  is being made.
 *
 * Derived classes can override this to execute their own code on
 * initialization. They should make sure to not execute any code if self is not
 * the class itself, as it might happen that the method was called for a
 * subclass which did not override this method.
 */
+ (void)initialize;

/**
 * \brief Allocates memory for an instance of the class and sets up the memory
 *	  pool for the object.
 *
 * This method will never return nil, instead, it will throw an
 * OFAllocFailedException.
 *
 * \return The allocated object
 */
+ alloc;

/**
 * \brief Allocates memory for a new instance and calls -[init] on it.
 * \return An allocated and initialized object
 */
+ new;

/**
 * \brief Returns the class.
 *
 * \return The class
 */
+ (Class)class;

/**
 * \brief Returns the name of the class as a string.
 *
 * \return The name of the class as a string
 */
+ (OFString*)className;

/**
 * \brief Returns a boolean whether the class is a subclass of the specified
 *	  class.
 *
 * \param class_ The class which is checked for being a superclass
 * \return A boolean whether the class is a subclass of the specified class
 */
+ (BOOL)isSubclassOfClass: (Class)class_;

/**
 * \brief Returns the superclass of the class.
 *
 * \return The superclass of the class
 */
+ (Class)superclass;

/**
 * \brief Checks whether instances of the class respond to a given selector.
 *
 * \param selector The selector which should be checked for respondance
 * \return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (BOOL)instancesRespondToSelector: (SEL)selector;

/**
 * \brief Checks whether the class conforms to a given protocol.
 *
 * \param protocol The protocol which should be checked for conformance
 * \return A boolean whether the class conforms to the specified protocol
 */
+ (BOOL)conformsToProtocol: (Protocol*)protocol;

/**
 * \brief Returns the implementation of the instance method for the specified
 *	  selector.
 *
 * \param selector The selector for which the method should be returned
 * \return The implementation of the instance method for the specified selector
 *	   or nil if it isn't implemented
 */
+ (IMP)instanceMethodForSelector: (SEL)selector;

/**
 * \brief Returns the type encoding of the instance method for the specified
 *	  selector.
 *
 * \param selector The selector for which the type encoding should be returned
 * \return The type encoding of the instance method for the specified selector
 */
+ (const char*)typeEncodingForInstanceSelector: (SEL)selector;

/**
 * \brief Returns a description for the class, which is usually the class name.
 *
 * This is mostly for debugging purposes.
 *
 * \return A description for the class, which is usually the class name
 */
+ (OFString*)description;

/**
 * \brief Replaces a class method implementation with another implementation.
 *
 * \param newImp The new implementation for the class method
 * \param selector The selector of the class method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newImp
	  forClassMethod: (SEL)selector;

/**
 * \brief Replaces a class method with a class method from another class.
 *
 * \param selector The selector of the class method to replace
 * \param class_ The class from which the new class method should be taken
 * \return The old implementation
 */
+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class_;

/**
 * \brief Replaces an instance method implementation with another
 *	  implementation.
 *
 * \param newImp The new implementation for the instance method
 * \param selector The selector of the instance method to replace
 * \return The old implementation
 */
+ (IMP)setImplementation: (IMP)newImp
       forInstanceMethod: (SEL)selector;

/**
 * \brief Replaces an instance method with an instance method from another
 *	  class.
 *
 * \param selector The selector of the instance method to replace
 * \param class_ The class from which the new instance method should be taken
 * \return The old implementation
 */
+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class_;

/**
 * \brief Adds a class method to the class.
 *
 * If the method already exists, nothing is done and NO is returned. If you want
 * to change the implementation of a method, use
 * setImplementation:forClassMethod:.
 *
 * \param selector The selector for the new method
 * \param typeEncoding The type encoding for the new method
 * \param implementation The implementation for the new method
 * \return Whether the method has been added
 */
+ (BOOL)addClassMethod: (SEL)selector
      withTypeEncoding: (const char*)typeEncoding
	implementation: (IMP)implementation;

/**
 * \brief Adds an instance method to the class.
 *
 * If the method already exists, nothing is done and NO is returned. If you want
 * to change the implementation of a method, use
 * setImplementation:forInstanceMethod:.
 *
 * \param selector The selector for the new method
 * \param typeEncoding The type encoding for the new method
 * \param implementation The implementation for the new method
 * \return Whether the method has been added
 */
+ (BOOL)addInstanceMethod: (SEL)selector
	 withTypeEncoding: (const char*)typeEncoding
	   implementation: (IMP)implementation;

/**
 * \brief Adds all methods from the specified class to the class that is the
 *	  receiver.
 *
 * Methods implemented by the receiving class itself will not be overridden,
 * however methods implemented by its superclass will. Therefore it behaves
 * similar as if the specified class is the superclass of the receiver.
 *
 * All methods from the superclasses of the specified class will also be added.
 *
 * If the specified class is a superclass of the receiving class, nothing is
 * done.
 *
 * The methods which will be added from the specified class are not allowed to
 * use super or access instance variables, instead they have to use accessors.
 *
 * \param class The class from which the instance methods should be inherited
 */
+ (void)inheritMethodsFromClass: (Class)class_;

/**
 * \brief Initializes an already allocated object.
 *
 * Derived classes may override this, but need to do self = [super init] before
 * they do any initialization themselves. init may never return nil, instead
 * an exception (for example OFInitializationFailed) should be thrown.
 *
 * \return An initialized object
 */
- init;

/**
 * \brief Returns the name of the object's class.
 *
 * \return The name of the object's class
 */
- (OFString*)className;

/**
 * \brief Returns a description for the object.
 *
 * This is mostly for debugging purposes.
 *
 * \return A description for the object
 */
- (OFString*)description;

/**
 * \brief Adds a pointer to the object's memory pool.
 *
 * This is useful to add memory allocated by functions such as asprintf to the
 * pool so it gets free'd automatically when the object is deallocated.
 *
 * \param pointer A pointer to add to the memory pool
 */
- (void)addMemoryToPool: (void*)pointer;

/**
 * \brief Allocates memory and stores it in the object's memory pool.
 *
 * It will be free'd automatically when the object is deallocated.
 *
 * \param size The size of the memory to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryWithSize: (size_t)size;

/**
 * \brief Allocates memory for the specified number of items and stores it in
 *	  the object's memory pool.
 *
 * It will be free'd automatically when the object is deallocated.
 *
 * \param nItems The number of items to allocate
 * \param size The size of each item to allocate
 * \return A pointer to the allocated memory
 */
- (void*)allocMemoryForNItems: (size_t)nItems
		       ofSize: (size_t)size;

/**
 * \brief Resizes memory in the object's memory pool to the specified size.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size is 0, this is equivalent to freeing memory.
 *
 * \param pointer A pointer to the already allocated memory
 * \param size The new size for the memory chunk
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)pointer
	       toSize: (size_t)size;

/**
 * \brief Resizes memory in the object's memory pool to the specific number of
 *	  items of the specified size.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size or number of items is 0, this is equivalent to freeing memory.
 *
 * \param pointer A pointer to the already allocated memory
 * \param nItems The number of items to resize to
 * \param size The size of each item to resize to
 * \return A pointer to the resized memory chunk
 */
- (void*)resizeMemory: (void*)pointer
	     toNItems: (size_t)nItems
	       ofSize: (size_t)size;

/**
 * \brief Frees allocated memory and removes it from the object's memory pool.
 *
 * Does nothing if the pointer is NULL.
 *
 * \param pointer A pointer to the allocated memory
 */
- (void)freeMemory: (void*)pointer;

/**
 * \brief Deallocates the object.
 *
 * It is automatically called when the retain count reaches zero.
 *
 * This also frees all memory in its memory pool.
 */
- (void)dealloc;
@end

/**
 * \brief A protocol for the creation of copies.
 */
@protocol OFCopying
/**
 * \brief Copies the object.
 *
 * For classes which can be immutable or mutable, this returns an immutable
 * copy. If only a mutable version of the class exists, it creates a mutable
 * copy.
 *
 * \return A copy of the object
 */
- copy;
@end

/**
 * \brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying
/**
 * \brief Creates a mutable copy of the object.
 *
 * \return A mutable copy of the object
 */
- mutableCopy;
@end

/**
 * \brief A protocol for comparing objects.
 *
 * This protocol is implemented by objects that can be compared.
 */
@protocol OFComparing <OFObject>
/**
 * \brief Compares the object with another object.
 *
 * \param object An object to compare the object to
 * \return The result of the comparison
 */
- (of_comparison_result_t)compare: (id)object;
@end

#import "OFObject+Serialization.h"

#ifdef __cplusplus
extern "C" {
#endif
extern id objc_getProperty(id, SEL, ptrdiff_t, BOOL);
extern void objc_setProperty(id, SEL, ptrdiff_t, id, BOOL, BOOL);
extern size_t of_pagesize;
#ifdef __cplusplus
}
#endif
