/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

#import "macros.h"
#import "autorelease.h"
#import "block.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

/*!
 * @brief A result of a comparison.
 */
typedef enum {
	/*! The left object is smaller than the right */
	OF_ORDERED_ASCENDING = -1,
	/*! Both objects are equal */
	OF_ORDERED_SAME = 0,
	/*! The left object is bigger than the right */
	OF_ORDERED_DESCENDING = 1
} of_comparison_result_t;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A comparator to compare two objects.
 *
 * @param left The left object
 * @param right The right object
 * @return The order of the objects
 */
typedef of_comparison_result_t (^of_comparator_t)(id _Nonnull left,
    id _Nonnull right);
#endif

/*!
 * @brief An enum for storing endianess.
 */
typedef enum {
	/*! Most significant byte first (big endian) */
	OF_BYTE_ORDER_BIG_ENDIAN,
	/*! Least significant byte first (little endian) */
	OF_BYTE_ORDER_LITTLE_ENDIAN
} of_byte_order_t;

/*!
 * @struct of_range_t OFObject.h ObjFW/OFObject.h
 *
 * @brief A range.
 */
typedef struct {
	/*! The start of the range */
	size_t location;
	/*! The length of the range */
	size_t length;
} of_range_t;

/*!
 * @brief Creates a new of_range_t.
 *
 * @param start The starting index of the range
 * @param length The length of the range
 * @return An of_range with the specified start and length
 */
static OF_INLINE of_range_t OF_CONST_FUNC
of_range(size_t start, size_t length)
{
	of_range_t range = { start, length };

	return range;
}

/*!
 * @brief A time interval in seconds.
 */
typedef double of_time_interval_t;

/*!
 * @struct of_point_t OFObject.h ObjFW/OFObject.h
 *
 * @brief A point.
 */
typedef struct {
	/*! The x coordinate of the point */
	float x;
	/*! The y coordinate of the point */
	float y;
} of_point_t;

/*!
 * @brief Creates a new of_point_t.
 *
 * @param x The x coordinate of the point
 * @param y The x coordinate of the point
 * @return An of_point_t with the specified coordinates
 */
static OF_INLINE of_point_t OF_CONST_FUNC
of_point(float x, float y)
{
	of_point_t point = { x, y };

	return point;
}

/*!
 * @struct of_dimension_t OFObject.h ObjFW/OFObject.h
 *
 * @brief A dimension.
 */
typedef struct {
	/*! The width of the dimension */
	float width;
	/*! The height of the dimension */
	float height;
} of_dimension_t;

/*!
 * @brief Creates a new of_dimension_t.
 *
 * @param width The width of the dimension
 * @param height The height of the dimension
 * @return An of_dimension_t with the specified width and height
 */
static OF_INLINE of_dimension_t OF_CONST_FUNC
of_dimension(float width, float height)
{
	of_dimension_t dimension = { width, height };

	return dimension;
}

/*!
 * @struct of_rectangle_t OFObject.h ObjFW/OFObject.h
 *
 * @brief A rectangle.
 */
typedef struct {
	/*! The point from where the rectangle originates */
	of_point_t origin;
	/*! The size of the rectangle */
	of_dimension_t size;
} of_rectangle_t;

/*!
 * @brief Creates a new of_rectangle_t.
 *
 * @param x The x coordinate of the top left corner of the rectangle
 * @param y The y coordinate of the top left corner of the rectangle
 * @param width The width of the rectangle
 * @param height The height of the rectangle
 * @return An of_rectangle_t with the specified origin and size
 */
static OF_INLINE of_rectangle_t OF_CONST_FUNC
of_rectangle(float x, float y, float width, float height)
{
	of_rectangle_t rectangle = {
		of_point(x, y),
		of_dimension(width, height)
	};

	return rectangle;
}

@class OFMethodSignature;
@class OFString;
@class OFThread;

/*!
 * @protocol OFObject OFObject.h ObjFW/OFObject.h
 *
 * @brief The protocol which all root classes implement.
 */
@protocol OFObject
/*!
 * @brief The class of the object.
 */
@property (readonly, nonatomic) Class class;

/*!
 * @brief The superclass of the object.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) Class superclass;

/*!
 * @brief A 32 bit hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * @warning If you reimplement this, you also need to reimplement @ref isEqual:
 *	    to behave in a way compatible to your reimplementation of this
 *	    method!
 */
@property (readonly, nonatomic) uint32_t hash;

/*!
 * @brief The retain count.
 */
@property (readonly, nonatomic) unsigned int retainCount;

/*!
 * @brief Whether the object is a proxy object.
 */
@property (readonly, nonatomic) bool isProxy;

/*!
 * @brief Whether the object allows weak references.
 */
@property (readonly, nonatomic) bool allowsWeakReference;

/*!
 * @brief Returns a boolean whether the object of the specified kind.
 *
 * @param class_ The class whose kind is checked
 * @return A boolean whether the object is of the specified kind
 */
- (bool)isKindOfClass: (Class)class_;

/*!
 * @brief Returns a boolean whether the object is a member of the specified
 *	  class.
 *
 * @param class_ The class for which the receiver is checked
 * @return A boolean whether the object is a member of the specified class
 */
- (bool)isMemberOfClass: (Class)class_;

/*!
 * @brief Returns a boolean whether the object responds to the specified
 *	  selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether the objects responds to the specified selector
 */
- (bool)respondsToSelector: (SEL)selector;

/*!
 * @brief Checks whether the object conforms to the specified protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the object conforms to the specified protocol
 */
- (bool)conformsToProtocol: (Protocol *)protocol;

/*!
 * @brief Returns the implementation for the specified selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation for the specified selector
 */
- (nullable IMP)methodForSelector: (SEL)selector;

/*!
 * @brief Performs the specified selector.
 *
 * @param selector The selector to perform
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector;

/*!
 * @brief Performs the specified selector with the specified object.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object;

/*!
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2;

/*!
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2
		    withObject: (nullable id)object3;

/*!
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2
		    withObject: (nullable id)object3
		    withObject: (nullable id)object4;

/*!
 * @brief Checks two objects for equality.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * @warning If you reimplement this, you also need to reimplement @ref hash to
 *	    return the same hash for objects which are equal!
 *
 * @param object The object which should be tested for equality
 * @return A boolean whether the object is equal to the specified object
 */
- (bool)isEqual: (nullable id)object;

/*!
 * @brief Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (instancetype)retain;

/*!
 * @brief Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/*!
 * @brief Adds the object to the topmost OFAutoreleasePool of the thread's
 *	  autorelease pool stack.
 *
 * @return The object
 */
- (instancetype)autorelease;

/*!
 * @brief Returns the receiver.
 *
 * @return The receiver
 */
- (instancetype)self;

/*!
 * @brief Retain a weak reference to this object.
 *
 * @return Whether a weak reference to this object has been retained
 */
- (bool)retainWeakReference;
@end

/*!
 * @class OFObject OFObject.h ObjFW/OFObject.h
 *
 * @brief The root class for all other classes inside ObjFW.
 */
OF_ROOT_CLASS
@interface OFObject <OFObject>
{
@private
#ifndef __clang_analyzer__
	Class _isa;
#else
	Class _isa __attribute__((__unused__));
#endif
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) Class class;
@property (class, readonly, nonatomic) OFString *className;
@property (class, readonly, nullable, nonatomic) Class superclass;
@property (class, readonly, nonatomic) OFString *description;
#endif

/*!
 * @brief The name of the object's class.
 */
@property (readonly, nonatomic) OFString *className;

/*!
 * @brief A description for the object.
 *
 * This is used when the object is used in a format string and for debugging
 * purposes.
 */
@property (readonly, nonatomic) OFString *description;

/*!
 * @brief A method which is called once when the class is loaded into the
 *	  runtime.
 *
 * Derived classes can override this to execute their own code when the class
 * is loaded.
 */
+ (void)load;

/*!
 * @brief A method which is called when the class is unloaded from the runtime.
 *
 * Derived classes can override this to execute their own code when the class
 * is unloaded.
 *
 * @warning This is not supported by the Apple runtime and currently only
 *	    called by the ObjFW runtime when objc_unregister_class() or
 *	    objc_exit() has been called!
 *	    In the future, this might also be called by the ObjFW runtime when
 *	    the class is part of a plugin that has been unloaded.
 */
+ (void)unload;

/*!
 * @brief A method which is called the moment before the first call to the class
 *	  is being made.
 *
 * Derived classes can override this to execute their own code on
 * initialization. They should make sure to not execute any code if self is not
 * the class itself, as it might happen that the method was called for a
 * subclass which did not override this method.
 */
+ (void)initialize;

/*!
 * @brief Allocates memory for an instance of the class and sets up the memory
 *	  pool for the object.
 *
 * This method will never return `nil`, instead, it will throw an
 * @ref OFAllocFailedException.
 *
 * @return The allocated object
 */
+ (instancetype)alloc;

/*!
 * @brief Allocates memory for a new instance and calls @ref init on it.
 * @return An allocated and initialized object
 */
+ (instancetype)new;

/*!
 * @brief Returns the class.
 *
 * @return The class
 */
+ (Class)class;

/*!
 * @brief Returns the name of the class as a string.
 *
 * @return The name of the class as a string
 */
+ (OFString *)className;

/*!
 * @brief Returns a boolean whether the class is a subclass of the specified
 *	  class.
 *
 * @param class_ The class which is checked for being a superclass
 * @return A boolean whether the class is a subclass of the specified class
 */
+ (bool)isSubclassOfClass: (Class)class_;

/*!
 * @brief Returns the superclass of the class.
 *
 * @return The superclass of the class
 */
+ (nullable Class)superclass;

/*!
 * @brief Checks whether instances of the class respond to a given selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (bool)instancesRespondToSelector: (SEL)selector;

/*!
 * @brief Checks whether the class conforms to a given protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the class conforms to the specified protocol
 */
+ (bool)conformsToProtocol: (Protocol *)protocol;

/*!
 * @brief Returns the implementation of the instance method for the specified
 *	  selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation of the instance method for the specified selector
 *	   or `nil` if it isn't implemented
 */
+ (nullable IMP)instanceMethodForSelector: (SEL)selector;

/*!
 * @brief Returns the method signature of the instance method for the specified
 *	  selector.
 *
 * @param selector The selector for which the method signature should be
 *		   returned
 * @return The method signature of the instance method for the specified
 *	   selector
 */
+ (nullable OFMethodSignature *)
    instanceMethodSignatureForSelector: (SEL)selector;

/*!
 * @brief Returns a description for the class, which is usually the class name.
 *
 * This is mostly for debugging purposes.
 *
 * @return A description for the class, which is usually the class name
 */
+ (OFString *)description;

/*!
 * @brief Replaces a class method with a class method from another class.
 *
 * @param selector The selector of the class method to replace
 * @param class_ The class from which the new class method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceClassMethod: (SEL)selector
	       withMethodFromClass: (Class)class_;

/*!
 * @brief Replaces an instance method with an instance method from another
 *	  class.
 *
 * @param selector The selector of the instance method to replace
 * @param class_ The class from which the new instance method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceInstanceMethod: (SEL)selector
		  withMethodFromClass: (Class)class_;

/*!
 * @brief Adds all methods from the specified class to the class that is the
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
 * @param class_ The class from which the instance methods should be inherited
 */
+ (void)inheritMethodsFromClass: (Class)class_;

/*!
 * @brief Try to resolve the specified class method.
 *
 * This method is called if a class method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (BOOL)resolveClassMethod: (SEL)selector;

/*!
 * @brief Try to resolve the specified instance method.
 *
 * This method is called if an instance method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (BOOL)resolveInstanceMethod: (SEL)selector;

/*!
 * @brief Returns the class.
 *
 * This method exists so that classes can be used in collections requiring
 * conformance to the OFCopying protocol.
 *
 * @return The class of the object
 */
+ (id)copy;

/*!
 * @brief Initializes an already allocated object.
 *
 * Derived classes may override this, but need to do
 * @code
 *   self = [super init]
 * @endcode
 * before they do any initialization themselves. @ref init may never return
 * `nil`, instead an exception (for example @ref
 * OFInitializationFailedException) should be thrown.
 *
 * @return An initialized object
 */
- (instancetype)init;

/*!
 * @brief Returns the method signature for the specified selector.
 *
 * @param selector The selector for which the method signature should be
 *		   returned
 * @return The method signature for the specified selector
 */
- (nullable OFMethodSignature *)methodSignatureForSelector: (SEL)selector;

/*!
 * @brief Allocates memory and stores it in the object's memory pool.
 *
 * It will be freed automatically when the object is deallocated.
 *
 * @param size The size of the memory to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size is 0.
 */
- (nullable void *)allocMemoryWithSize: (size_t)size OF_WARN_UNUSED_RESULT;

/*!
 * @brief Allocates memory for the specified number of items and stores it in
 *	  the object's memory pool.
 *
 * It will be freed automatically when the object is deallocated.
 *
 * @param size The size of each item to allocate
 * @param count The number of items to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size or count is 0.
 */
- (nullable void *)allocMemoryWithSize: (size_t)size
				 count: (size_t)count OF_WARN_UNUSED_RESULT;

/*!
 * @brief Resizes memory in the object's memory pool to the specified size.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size is 0, this is equivalent to freeing memory.
 *
 * @param pointer A pointer to the already allocated memory
 * @param size The new size for the memory chunk
 * @return A pointer to the resized memory chunk
 */
- (nullable void *)resizeMemory: (nullable void *)pointer
			   size: (size_t)size OF_WARN_UNUSED_RESULT;

/*!
 * @brief Resizes memory in the object's memory pool to the specific number of
 *	  items of the specified size.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size or number of items is 0, this is equivalent to freeing memory.
 *
 * @param pointer A pointer to the already allocated memory
 * @param size The size of each item to resize to
 * @param count The number of items to resize to
 * @return A pointer to the resized memory chunk
 */
- (nullable void *)resizeMemory: (nullable void *)pointer
			   size: (size_t)size
			  count: (size_t)count OF_WARN_UNUSED_RESULT;

/*!
 * @brief Frees allocated memory and removes it from the object's memory pool.
 *
 * Does nothing if the pointer is NULL.
 *
 * @param pointer A pointer to the allocated memory
 */
- (void)freeMemory: (nullable void *)pointer;

/*!
 * @brief Deallocates the object.
 *
 * It is automatically called when the retain count reaches zero.
 *
 * This also frees all memory in its memory pool.
 */
- (void)dealloc;

/*!
 * @brief Performs the specified selector after the specified delay.
 *
 * @param selector The selector to perform
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector with the specified object after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	     afterDelay: (of_time_interval_t)delay;

#ifdef OF_HAVE_THREADS
/*!
 * @brief Performs the specified selector on the specified thread.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	  waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified object.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object
	  waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	  waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	  waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	  waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the main thread.
 *
 * @param selector The selector to perform
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
		      waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the main thread with the specified
 *	  object.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object
		      waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
		      waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
			 withObject: (nullable id)object3
		      waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
			 withObject: (nullable id)object3
			 withObject: (nullable id)object4
		      waitUntilDone: (bool)waitUntilDone;

/*!
 * @brief Performs the specified selector on the specified thread after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified object after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     afterDelay: (of_time_interval_t)delay;

/*!
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	     afterDelay: (of_time_interval_t)delay;
#endif

/*!
 * @brief This method is called when @ref resolveClassMethod: or
 *	  @ref resolveInstanceMethod: returned false. It should return a target
 *	  to which the message should be forwarded.
 *
 * @note When the message should not be forwarded, you should not return `nil`,
 *	 but instead return the result of `[super
 *	 forwardingTargetForSelector: selector]`.
 *
 * @return The target to forward the message to
 */
- (nullable id)forwardingTargetForSelector: (SEL)selector;

/*!
 * @brief Handles messages which are not understood by the receiver.
 *
 * @warning If you override this method, you must make sure that it never
 *	    returns!
 *
 * @param selector The selector not understood by the receiver
 */
- (void)doesNotRecognizeSelector: (SEL)selector OF_NO_RETURN;
@end

/*!
 * @protocol OFCopying OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for the creation of copies.
 */
@protocol OFCopying
/*!
 * @brief Copies the object.
 *
 * For classes which can be immutable or mutable, this returns an immutable
 * copy. If only a mutable version of the class exists, it creates a mutable
 * copy.
 *
 * @return A copy of the object
 */
- (id)copy;
@end

/*!
 * @protocol OFMutableCopying OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying
/*!
 * @brief Creates a mutable copy of the object.
 *
 * @return A mutable copy of the object
 */
- (id)mutableCopy;
@end

/*!
 * @protocol OFComparing OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for comparing objects.
 *
 * This protocol is implemented by objects that can be compared.
 */
@protocol OFComparing
/*!
 * @brief Compares the object with another object.
 *
 * @param object An object to compare the object to
 * @return The result of the comparison
 */
- (of_comparison_result_t)compare: (id <OFComparing>)object;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern id of_alloc_object(Class class_, size_t extraSize,
    size_t extraAlignment, void *_Nullable *_Nullable extra);
extern void OF_NO_RETURN_FUNC of_method_not_found(id self, SEL _cmd);
extern uint32_t of_hash_seed;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFObject+KeyValueCoding.h"
#import "OFObject+Serialization.h"
