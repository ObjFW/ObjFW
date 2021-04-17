/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#ifndef OBJFW_OF_OBJECT_H
#define OBJFW_OF_OBJECT_H

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

#include "macros.h"
#include "once.h"

/*
 * Some versions of MinGW require <winsock2.h> to be included before
 * <windows.h>. Do this here to make sure this is always done in the correct
 * order, even if another header includes just <windows.h>.
 */
#ifdef __MINGW32__
# include <_mingw.h>
# ifdef __MINGW64_VERSION_MAJOR
#  include <winsock2.h>
#  include <windows.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

/**
 * @brief A result of a comparison.
 */
typedef enum OFComparisonResult {
	/** The left object is smaller than the right */
	OFOrderedAscending = -1,
	/** Both objects are equal */
	OFOrderedSame = 0,
	/** The left object is bigger than the right */
	OFOrderedDescending = 1
} OFComparisonResult;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A comparator to compare two objects.
 *
 * @param left The left object
 * @param right The right object
 * @return The order of the objects
 */
typedef OFComparisonResult (^OFComparator)(id _Nonnull left, id _Nonnull right);
#endif

/**
 * @brief An enum for storing endianess.
 */
typedef enum OFByteOrder {
	/** Most significant byte first (big endian) */
	OFByteOrderBigEndian,
	/** Least significant byte first (little endian) */
	OFByteOrderLittleEndian,
	/** Native byte order of the system */
#ifdef OF_BIG_ENDIAN
	OFByteOrderNative = OFByteOrderBigEndian
#else
	OFByteOrderNative = OFByteOrderLittleEndian
#endif
} OFByteOrder;

/**
 * @struct OFRange OFObject.h ObjFW/OFObject.h
 *
 * @brief A range.
 */
struct OF_BOXABLE OFRange {
	/** The start of the range */
	size_t location;
	/** The length of the range */
	size_t length;
};
typedef struct OFRange OFRange;

/**
 * @brief Creates a new OFRange.
 *
 * @param start The starting index of the range
 * @param length The length of the range
 * @return An OFRangeith the specified start and length
 */
static OF_INLINE OFRange OF_CONST_FUNC
OFRangeMake(size_t start, size_t length)
{
	OFRange range = { start, length };

	return range;
}

/**
 * @brief Returns whether the two ranges are equal.
 *
 * @param range1 The first range for the comparison
 * @param range2 The second range for the comparison
 * @return Whether the two ranges are equal
 */
static OF_INLINE bool
OFRangeEqual(OFRange range1, OFRange range2)
{
	if (range1.location != range2.location)
		return false;

	if (range1.length != range2.length)
		return false;

	return true;
}

/**
 * @brief A time interval in seconds.
 */
typedef double OFTimeInterval;

/**
 * @struct OFPoint OFObject.h ObjFW/OFObject.h
 *
 * @brief A point.
 */
struct OF_BOXABLE OFPoint {
	/** The x coordinate of the point */
	float x;
	/** The y coordinate of the point */
	float y;
};
typedef struct OFPoint OFPoint;

/**
 * @brief Creates a new OFPoint.
 *
 * @param x The x coordinate of the point
 * @param y The x coordinate of the point
 * @return An OFPoint with the specified coordinates
 */
static OF_INLINE OFPoint OF_CONST_FUNC
OFPointMake(float x, float y)
{
	OFPoint point = { x, y };

	return point;
}

/**
 * @brief Returns whether the two points are equal.
 *
 * @param point1 The first point for the comparison
 * @param point2 The second point for the comparison
 * @return Whether the two points are equal
 */
static OF_INLINE bool
OFPointEqual(OFPoint point1, OFPoint point2)
{
	if (point1.x != point2.x)
		return false;

	if (point1.y != point2.y)
		return false;

	return true;
}

/**
 * @struct OFSize OFObject.h ObjFW/OFObject.h
 *
 * @brief A size.
 */
struct OF_BOXABLE OFSize {
	/** The width of the size */
	float width;
	/** The height of the size */
	float height;
};
typedef struct OFSize OFSize;

/**
 * @brief Creates a new OFSize.
 *
 * @param width The width of the size
 * @param height The height of the size
 * @return An OFSize with the specified width and height
 */
static OF_INLINE OFSize OF_CONST_FUNC
OFSizeMake(float width, float height)
{
	OFSize size = { width, height };

	return size;
}

/**
 * @brief Returns whether the two sizes are equal.
 *
 * @param size1 The first size for the comparison
 * @param size2 The second size for the comparison
 * @return Whether the two sizes are equal
 */
static OF_INLINE bool
OFSizeEqual(OFSize size1, OFSize size2)
{
	if (size1.width != size2.width)
		return false;

	if (size1.height != size2.height)
		return false;

	return true;
}

/**
 * @struct OFRect OFObject.h ObjFW/OFObject.h
 *
 * @brief A rectangle.
 */
struct OF_BOXABLE OFRect {
	/** The point from where the rectangle originates */
	OFPoint origin;
	/** The size of the rectangle */
	OFSize size;
};
typedef struct OFRect OFRect;

/**
 * @brief Creates a new OFRect.
 *
 * @param x The x coordinate of the top left corner of the rectangle
 * @param y The y coordinate of the top left corner of the rectangle
 * @param width The width of the rectangle
 * @param height The height of the rectangle
 * @return An OFRect with the specified origin and size
 */
static OF_INLINE OFRect OF_CONST_FUNC
OFRectMake(float x, float y, float width, float height)
{
	OFRect rect = {
		OFPointMake(x, y),
		OFSizeMake(width, height)
	};

	return rect;
}

/**
 * @brief Returns whether the two rectangles are equal.
 *
 * @param rect1 The first rectangle for the comparison
 * @param rect2 The second rectangle for the comparison
 * @return Whether the two rectangles are equal
 */
static OF_INLINE bool
OFRectEqual(OFRect rect1, OFRect rect2)
{
	if (!OFPointEqual(rect1.origin, rect2.origin))
		return false;

	if (!OFSizeEqual(rect1.size, rect2.size))
		return false;

	return true;
}

static const size_t OFNotFound = SIZE_MAX;

#ifdef __OBJC__
@class OFMethodSignature;
@class OFString;
@class OFThread;

/**
 * @protocol OFObject OFObject.h ObjFW/OFObject.h
 *
 * @brief The protocol which all root classes implement.
 */
@protocol OFObject
/**
 * @brief Returns the class of the object.
 *
 * @return The class of the object
 */
- (Class)class;

/**
 * @brief Returns the superclass of the object.
 *
 * @return The superclass of the object
 */
- (nullable Class)superclass;

/**
 * @brief Returns a 32 bit hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * @warning If you reimplement this, you also need to reimplement @ref isEqual:
 *	    to behave in a way compatible to your reimplementation of this
 *	    method!
 *
 * @return A 32 bit hash for the object
 */
- (unsigned long)hash;

/**
 * @brief Returns the retain count.
 *
 * @return The retain count
 */
- (unsigned int)retainCount;

/**
 * @brief Returns whether the object is a proxy object.
 *
 * @return Whether the object is a proxy object
 */
- (bool)isProxy;

/**
 * @brief Returns whether the object allows weak references.
 *
 * @return Whether the object allows weak references
 */
- (bool)allowsWeakReference;

/**
 * @brief Returns a boolean whether the object of the specified kind.
 *
 * @param class_ The class whose kind is checked
 * @return A boolean whether the object is of the specified kind
 */
- (bool)isKindOfClass: (Class)class_;

/**
 * @brief Returns a boolean whether the object is a member of the specified
 *	  class.
 *
 * @param class_ The class for which the receiver is checked
 * @return A boolean whether the object is a member of the specified class
 */
- (bool)isMemberOfClass: (Class)class_;

/**
 * @brief Returns a boolean whether the object responds to the specified
 *	  selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether the objects responds to the specified selector
 */
- (bool)respondsToSelector: (SEL)selector;

/**
 * @brief Checks whether the object conforms to the specified protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the object conforms to the specified protocol
 */
- (bool)conformsToProtocol: (Protocol *)protocol;

/**
 * @brief Returns the implementation for the specified selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation for the specified selector
 */
- (nullable IMP)methodForSelector: (SEL)selector;

/**
 * @brief Performs the specified selector.
 *
 * @param selector The selector to perform
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector;

/**
 * @brief Performs the specified selector with the specified object.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector withObject: (nullable id)object;

/**
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

/**
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

/**
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

/**
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

/**
 * @brief Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (instancetype)retain;

/**
 * @brief Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/**
 * @brief Adds the object to the topmost autorelease pool of the thread's
 *	  autorelease pool stack.
 *
 * @return The object
 */
- (instancetype)autorelease;

/**
 * @brief Returns the receiver.
 *
 * @return The receiver
 */
- (instancetype)self;

/**
 * @brief Retain a weak reference to this object.
 *
 * @return Whether a weak reference to this object has been retained
 */
- (bool)retainWeakReference;
@end
#endif

/**
 * @class OFObject OFObject.h ObjFW/OFObject.h
 *
 * @brief The root class for all other classes inside ObjFW.
 */
#ifdef __OBJC__
OF_ROOT_CLASS
@interface OFObject <OFObject>
{
@private
# ifndef __clang_analyzer__
	Class _isa;
# else
	Class _isa __attribute__((__unused__));
# endif
}

# ifdef OF_HAVE_CLASS_PROPERTIES
#  ifndef __cplusplus
@property (class, readonly, nonatomic) Class class;
#  else
@property (class, readonly, nonatomic, getter=class) Class class_;
#  endif
@property (class, readonly, nonatomic) OFString *className;
@property (class, readonly, nullable, nonatomic) Class superclass;
@property (class, readonly, nonatomic) OFString *description;
# endif

# ifndef __cplusplus
@property (readonly, nonatomic) Class class;
# else
@property (readonly, nonatomic, getter=class) Class class_;
#endif
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) Class superclass;
@property (readonly, nonatomic) unsigned long hash;
@property (readonly, nonatomic) unsigned int retainCount;
@property (readonly, nonatomic) bool isProxy;
@property (readonly, nonatomic) bool allowsWeakReference;

/**
 * @brief The name of the object's class.
 */
@property (readonly, nonatomic) OFString *className;

/**
 * @brief A description for the object.
 *
 * This is used when the object is used in a format string and for debugging
 * purposes.
 */
@property (readonly, nonatomic) OFString *description;

/**
 * @brief A method which is called once when the class is loaded into the
 *	  runtime.
 *
 * Derived classes can override this to execute their own code when the class
 * is loaded.
 */
+ (void)load;

/**
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

/**
 * @brief A method which is called the moment before the first call to the class
 *	  is being made.
 *
 * Derived classes can override this to execute their own code on
 * initialization. They should make sure to not execute any code if self is not
 * the class itself, as it might happen that the method was called for a
 * subclass which did not override this method.
 */
+ (void)initialize;

/**
 * @brief Allocates memory for an instance of the class and sets up the memory
 *	  pool for the object.
 *
 * This method will never return `nil`, instead, it will throw an
 * @ref OFAllocFailedException.
 *
 * @return The allocated object
 */
+ (instancetype)alloc;

/**
 * @brief Calls @ref alloc on `self` and then `init` on the returned object.
 *
 * @return An allocated and initialized object
 */
+ (instancetype)new;

/**
 * @brief Returns the class.
 *
 * @return The class
 */
+ (Class)class;

/**
 * @brief Returns the name of the class as a string.
 *
 * @return The name of the class as a string
 */
+ (OFString *)className;

/**
 * @brief Returns a boolean whether the class is a subclass of the specified
 *	  class.
 *
 * @param class_ The class which is checked for being a superclass
 * @return A boolean whether the class is a subclass of the specified class
 */
+ (bool)isSubclassOfClass: (Class)class_;

/**
 * @brief Returns the superclass of the class.
 *
 * @return The superclass of the class
 */
+ (nullable Class)superclass;

/**
 * @brief Checks whether instances of the class respond to a given selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (bool)instancesRespondToSelector: (SEL)selector;

/**
 * @brief Checks whether the class conforms to a given protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the class conforms to the specified protocol
 */
+ (bool)conformsToProtocol: (Protocol *)protocol;

/**
 * @brief Returns the implementation of the instance method for the specified
 *	  selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation of the instance method for the specified selector
 *	   or `nil` if it isn't implemented
 */
+ (nullable IMP)instanceMethodForSelector: (SEL)selector;

/**
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

/**
 * @brief Returns a description for the class, which is usually the class name.
 *
 * This is mostly for debugging purposes.
 *
 * @return A description for the class, which is usually the class name
 */
+ (OFString *)description;

/**
 * @brief Replaces a class method with a class method from another class.
 *
 * @param selector The selector of the class method to replace
 * @param class_ The class from which the new class method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceClassMethod: (SEL)selector
	       withMethodFromClass: (Class)class_;

/**
 * @brief Replaces an instance method with an instance method from another
 *	  class.
 *
 * @param selector The selector of the instance method to replace
 * @param class_ The class from which the new instance method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceInstanceMethod: (SEL)selector
		  withMethodFromClass: (Class)class_;

/**
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

/**
 * @brief Try to resolve the specified class method.
 *
 * This method is called if a class method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (bool)resolveClassMethod: (SEL)selector;

/**
 * @brief Try to resolve the specified instance method.
 *
 * This method is called if an instance method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (bool)resolveInstanceMethod: (SEL)selector;

/**
 * @brief Returns the class.
 *
 * This method exists so that classes can be used in collections requiring
 * conformance to the OFCopying protocol.
 *
 * @return The class of the object
 */
+ (id)copy;

/**
 * @brief Initializes an already allocated object.
 *
 * Derived classes may override this, but need to use the following pattern:
 * @code
 * self = [super init];
 *
 * @try {
 *         // Custom initialization code goes here.
 * } @catch (id e) {
 *         [self release];
 *         @throw e;
 * }
 *
 * return self;
 * @endcode
 *
 * With ARC enabled, the following pattern needs to be used instead:
 * @code
 * self = [super init];
 *
 * // Custom initialization code goes here.
 *
 * return self;
 * @endcode
 *
 * @ref init may never return `nil`, instead an exception (for example
 * @ref OFInitializationFailedException) should be thrown.
 *
 * @return An initialized object
 */
- (instancetype)init;

/**
 * @brief Returns the method signature for the specified selector.
 *
 * @param selector The selector for which the method signature should be
 *		   returned
 * @return The method signature for the specified selector
 */
- (nullable OFMethodSignature *)methodSignatureForSelector: (SEL)selector;

/**
 * @brief Deallocates the object.
 *
 * It is automatically called when the retain count reaches zero.
 *
 * This also frees all memory in its memory pool.
 */
- (void)dealloc;

/**
 * @brief Performs the specified selector after the specified delay.
 *
 * @param selector The selector to perform
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

# ifdef OF_HAVE_THREADS
/**
 * @brief Performs the specified selector on the specified thread.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	  waitUntilDone: (bool)waitUntilDone;

/**
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

/**
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

/**
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

/**
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

/**
 * @brief Performs the specified selector on the main thread.
 *
 * @param selector The selector to perform
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
		      waitUntilDone: (bool)waitUntilDone;

/**
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

/**
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

/**
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

/**
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

/**
 * @brief Performs the specified selector on the specified thread after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;

/**
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
	     afterDelay: (OFTimeInterval)delay;
# endif

/**
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

/**
 * @brief Handles messages which are not understood by the receiver.
 *
 * @warning If you override this method, you must make sure that it never
 *	    returns!
 *
 * @param selector The selector not understood by the receiver
 */
- (void)doesNotRecognizeSelector: (SEL)selector OF_NO_RETURN;
@end
#else
typedef void OFObject;
#endif

#ifdef __OBJC__
/**
 * @protocol OFCopying OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for the creation of copies.
 */
@protocol OFCopying
/**
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

/**
 * @protocol OFMutableCopying OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying
/**
 * @brief Creates a mutable copy of the object.
 *
 * @return A mutable copy of the object
 */
- (id)mutableCopy;
@end

/**
 * @protocol OFComparing OFObject.h ObjFW/OFObject.h
 *
 * @brief A protocol for comparing objects.
 *
 * This protocol is implemented by objects that can be compared. Its only method, @ref compare:, should be overridden with a stronger type.
 */
@protocol OFComparing
/**
 * @brief Compares the object to another object.
 *
 * @param object An object to compare the object to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (id <OFComparing>)object;
@end
#endif

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Allocates memory for the specified number of items of the specified
 *	  size.
 *
 * To free the allocated memory, use `free()`.
 *
 * Throws @ref OFOutOfMemoryException if allocating failed and
 * @ref OFOutOfRangeException if the requested size exceeds the address space.
 *
 * @param count The number of items to allocate
 * @param size The size of each item to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size or count is 0.
 */
extern void *_Nullable of_alloc(size_t count, size_t size)
    OF_WARN_UNUSED_RESULT;

/**
 * @brief Allocates memory for the specified number of items of the specified
 *	  size and initializes it with zeros.
 *
 * To free the allocated memory, use `free()`.
 *
 * Throws @ref OFOutOfMemoryException if allocating failed and
 * @ref OFOutOfRangeException if the requested size exceeds the address space.
 *
 * @param size The size of each item to allocate
 * @param count The number of items to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size or count is 0.
 */
extern void *_Nullable of_alloc_zeroed(size_t count, size_t size)
    OF_WARN_UNUSED_RESULT;

/**
 * @brief Resizes memory to the specified number of items of the specified size.
 *
 * To free the allocated memory, use `free()`.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size or number of items is 0, this is equivalent to freeing memory.
 *
 * Throws @ref OFOutOfMemoryException if allocating failed and
 * @ref OFOutOfRangeException if the requested size exceeds the address space.
 *
 * @param pointer A pointer to the already allocated memory
 * @param size The size of each item to resize to
 * @param count The number of items to resize to
 * @return A pointer to the resized memory chunk
 */
extern void *_Nullable of_realloc(void *_Nullable pointer, size_t count,
    size_t size) OF_WARN_UNUSED_RESULT;

#ifdef OF_APPLE_RUNTIME
extern void *_Null_unspecified objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *_Null_unspecified pool);
# ifndef __OBJC2__
extern id _Nullable objc_constructInstance(Class _Nullable class_,
    void *_Nullable bytes);
extern void *_Nullable objc_destructInstance(id _Nullable object);
# endif
#endif
extern id of_alloc_object(Class class_, size_t extraSize,
    size_t extraAlignment, void *_Nullable *_Nullable extra);
extern void OF_NO_RETURN_FUNC of_method_not_found(id self, SEL _cmd);
extern uint32_t of_hash_seed;
/* These do *NOT* provide cryptographically secure randomness! */
extern uint16_t of_random16(void);
extern uint32_t of_random32(void);
extern uint64_t of_random64(void);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#include "OFBlock.h"

#ifdef __OBJC__
# import "OFObject+KeyValueCoding.h"
# import "OFObject+Serialization.h"
#endif

#endif
