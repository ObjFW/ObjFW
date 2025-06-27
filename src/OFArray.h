/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdarg.h>

#import "OFObject.h"
#import "OFCollection.h"
#import "OFEnumerator.h"
#import "OFJSONRepresentation.h"
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFString;

/**
 * @brief Options for joining the objects of an array.
 *
 * This is a bit mask.
 */
typedef enum {
	/** Skip empty components */
	OFArraySkipEmptyComponents = 1
} OFArrayJoinOptions;

/**
 * @brief Options for sorting an array.
 *
 * This is a bit mask.
 */
typedef enum {
	/** Sort the array descending */
	OFArraySortDescending = 1
} OFArraySortOptions;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block for enumerating an OFArray.
 *
 * @param object The current object
 * @param index The index of the current object
 * @param stop A pointer to a variable that can be set to true to stop the
 *	       enumeration
 */
typedef void (^OFArrayEnumerationBlock)(id object, size_t index, bool *stop);

/**
 * @brief A block for filtering an OFArray.
 *
 * @param object The object to inspect
 * @param index The index of the object to inspect
 * @return Whether the object should be in the filtered array
 */
typedef bool (^OFArrayFilterBlock)(id object, size_t index);

/**
 * @brief A block for mapping objects to objects in an OFArray.
 *
 * @param object The object to map
 * @param index The index of the object to map
 * @return The object to map to
 */
typedef id _Nonnull (^OFArrayMapBlock)(id object, size_t index);

/**
 * @brief A block for folding an OFArray.
 *
 * @param left The object to which the object has been folded so far
 * @param right The object that should be added to the left object
 * @return The left and right side folded into one object
 */
typedef id _Nullable (^OFArrayFoldBlock)(id _Nullable left, id right);
#endif

/**
 * @class OFArray OFArray.h ObjFW/ObjFW.h
 *
 * @brief An abstract class for storing objects in an array.
 *
 * @note Subclasses must implement @ref count and @ref objectAtIndex:.
 */
@interface OFArray OF_GENERIC(ObjectType): OFObject <OFCopying,
    OFMutableCopying, OFCollection, OFJSONRepresentation,
    OFMessagePackRepresentation>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/**
 * @brief The objects of the array as a C array.
 *
 * The result is valid until the autorelease pool is released. If you want to
 * use the result outside the scope of the current autorelease pool, you have to
 * copy it.
 */
@property (readonly, nonatomic)
    ObjectType const __unsafe_unretained _Nonnull *_Nonnull objects;

/**
 * @brief The first object of the array or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType firstObject;

/**
 * @brief The last object of the array or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType lastObject;

/**
 * @brief The array sorted in ascending order.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(ObjectType) *sortedArray;

/**
 * @brief The array with the order reversed.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(ObjectType) *reversedArray;

/**
 * @brief Creates a new OFArray.
 *
 * @return A new autoreleased OFArray
 */
+ (instancetype)array;

/**
 * @brief Creates a new OFArray with the specified object.
 *
 * @param object An object
 * @return A new autoreleased OFArray
 */
+ (instancetype)arrayWithObject: (ObjectType)object;

/**
 * @brief Creates a new OFArray with the specified objects, terminated by `nil`.
 *
 * @param firstObject The first object in the array
 * @return A new autoreleased OFArray
 */
+ (instancetype)arrayWithObjects: (ObjectType)firstObject, ... OF_SENTINEL;

/**
 * @brief Creates a new OFArray with the objects from the specified array.
 *
 * @param array An array
 * @return A new autoreleased OFArray
 */
+ (instancetype)arrayWithArray: (OFArray OF_GENERIC(ObjectType) *)array;

/**
 * @brief Creates a new OFArray with the objects from the specified C array of
 *	  the specified length.
 *
 * @param objects A C array of objects
 * @param count The length of the C array
 * @return A new autoreleased OFArray
 */
+ (instancetype)arrayWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
			   count: (size_t)count;

/**
 * @brief Initializes an OFArray with no objects.
 *
 * @return An initialized OFArray
 */
- (instancetype)init OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an OFArray with the specified object.
 *
 * @param object An object
 * @return An initialized OFArray
 */
- (instancetype)initWithObject: (ObjectType)object;

/**
 * @brief Initializes an OFArray with the specified objects.
 *
 * @param firstObject The first object
 * @return An initialized OFArray
 */
- (instancetype)initWithObjects: (ObjectType)firstObject, ... OF_SENTINEL;

/**
 * @brief Initializes an OFArray with the specified object and a va_list.
 *
 * @param firstObject The first object
 * @param arguments A va_list
 * @return An initialized OFArray
 */
- (instancetype)initWithObject: (ObjectType)firstObject
		     arguments: (va_list)arguments;

/**
 * @brief Initializes an OFArray with the objects from the specified array.
 *
 * @param array An array
 * @return An initialized OFArray
 */
- (instancetype)initWithArray: (OFArray OF_GENERIC(ObjectType) *)array;

/**
 * @brief Initializes an OFArray with the objects from the specified C array of
 *	  the specified length.
 *
 * @param objects A C array of objects
 * @param count The length of the C array
 * @return An initialized OFArray
 */
- (instancetype)initWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
			  count: (size_t)count OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns an OFEnumerator to enumerate through all objects of the array.
 *
 * @return An OFEnumerator to enumerate through all objects of the array
 */
- (OFEnumerator OF_GENERIC(ObjectType) *)objectEnumerator;

/**
 * @brief Returns the object at the specified index in the array.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 *
 * @param index The index of the object to return
 * @return The object at the specified index in the array
 */
- (ObjectType)objectAtIndex: (size_t)index;
- (ObjectType)objectAtIndexedSubscript: (size_t)index;

/**
 * @brief Returns the value for the specified key
 *
 * A new array with the value for the specified key for each object is
 * returned.
 *
 * The special key `@count` can be used to retrieve the count as an OFNumber.
 *
 * @note Any nil values are replaced with @ref OFNull!
 *
 * @param key The key of the value to return
 * @return The value for the specified key
 */
- (nullable id)valueForKey: (OFString *)key;

/**
 * @brief Set the value for the specified key
 *
 * @ref setValue:forKey: is called for each object in the array.
 *
 * @note A @ref OFNull value is translated to nil!
 *
 * @param value The value for the specified key
 * @param key The key of the value to set
 */
- (void)setValue: (nullable id)value forKey: (OFString *)key;

/**
 * @brief Copies the objects at the specified range to the specified buffer.
 *
 * @param buffer The buffer to copy the objects to
 * @param range The range to copy
 */
- (void)getObjects: (ObjectType __unsafe_unretained _Nonnull *_Nonnull)buffer
	   inRange: (OFRange)range;

/**
 * @brief Returns the index of the first object that is equivalent to the
 *	  specified object or `OFNotFound` if it was not found.
 *
 * @param object The object whose index is returned
 * @return The index of the first object equivalent to the specified object
 *	   or `OFNotFound` if it was not found
 */
- (size_t)indexOfObject: (ObjectType)object;

/**
 * @brief Returns the index of the first object that has the same address as the
 *	  specified object or `OFNotFound` if it was not found.
 *
 * @param object The object whose index is returned
 * @return The index of the first object that has the same address as
 *	   the specified object or `OFNotFound` if it was not found
 */
- (size_t)indexOfObjectIdenticalTo: (ObjectType)object;

/**
 * @brief Checks whether the array contains an object equal to the specified
 *	  object.
 *
 * @param object The object which is checked for being in the array
 * @return A boolean whether the array contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/**
 * @brief Checks whether the array contains an object with the specified
 *	  address.
 *
 * @param object The object which is checked for being in the array
 * @return A boolean whether the array contains an object with the specified
 *	   address
 */
- (bool)containsObjectIdenticalTo: (ObjectType)object;

/**
 * @brief Returns the objects in the specified range as a new OFArray.
 *
 * @param range The range for the subarray
 * @return The subarray as a new autoreleased OFArray
 */
- (OFArray OF_GENERIC(ObjectType) *)objectsInRange: (OFRange)range;

/**
 * @brief Creates a string by joining all objects of the array.
 *
 * @param separator The string with which the objects should be joined
 * @return A string containing all objects joined by the separator
 */
- (OFString *)componentsJoinedByString: (OFString *)separator;

/**
 * @brief Creates a string by joining all objects of the array.
 *
 * @param separator The string with which the objects should be joined
 * @param options Options according to which the objects should be joined
 * @return A string containing all objects joined by the separator
 */
- (OFString *)componentsJoinedByString: (OFString *)separator
			       options: (OFArrayJoinOptions)options;

/**
 * @brief Creates a string by calling the selector on all objects of the array
 *	  and joining the strings returned by calling the selector.
 *
 * @param separator The string with which the objects should be joined
 * @param selector The selector to perform on the objects
 * @return A string containing all objects joined by the separator
 */
- (OFString *)componentsJoinedByString: (OFString *)separator
			 usingSelector: (SEL)selector;

/**
 * @brief Creates a string by calling the selector on all objects of the array
 *	  and joining the strings returned by calling the selector.
 *
 * @param separator The string with which the objects should be joined
 * @param selector The selector to perform on the objects
 * @param options Options according to which the objects should be joined
 * @return A string containing all objects joined by the separator
 */
- (OFString *)componentsJoinedByString: (OFString *)separator
			 usingSelector: (SEL)selector
			       options: (OFArrayJoinOptions)options;

/**
 * @brief Performs the specified selector on all objects in the array.
 *
 * @deprecated Use fast enumeration instead.
 *
 * @param selector The selector to perform on all objects in the array
 */
- (void)makeObjectsPerformSelector: (SEL)selector
    OF_DEPRECATED(ObjFW, 1, 4, "Use fast enumeration instead");

/**
 * @brief Performs the specified selector on all objects in the array with the
 *	  specified object.
 *
 * @deprecated Use fast enumeration instead.
 *
 * @param selector The selector to perform on all objects in the array
 * @param object The object to perform the selector with on all objects in the
 *	      array
 */
- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (nullable id)object
    OF_DEPRECATED(ObjFW, 1, 4, "Use fast enumeration instead");

/**
 * @brief Returns a copy of the array sorted using the specified selector and
 *	  options.
 *
 * @param selector The selector to use to sort the array. It's signature
 *		   should be the same as that of -[compare:].
 * @param options The options to use when sorting the array
 * @return A sorted copy of the array
 */
- (OFArray OF_GENERIC(ObjectType) *)
    sortedArrayUsingSelector: (SEL)selector
		     options: (OFArraySortOptions)options;

/**
 * @brief Returns a copy of the array sorted using the specified function and
 *	  options.
 *
 * @param compare The function to use to sort the array
 * @param context Context passed to the function to compare
 * @param options The options to use when sorting the array
 * @return A sorted copy of the array
 */
- (OFArray OF_GENERIC(ObjectType) *)
    sortedArrayUsingFunction: (OFCompareFunction)compare
		     context: (nullable void *)context
		     options: (OFArraySortOptions)options;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Returns a copy of the array sorted using the specified selector and
 *	  options.
 *
 * @param comparator The comparator to use to sort the array
 * @param options The options to use when sorting the array
 * @return A sorted copy of the array
 */
- (OFArray OF_GENERIC(ObjectType) *)
    sortedArrayUsingComparator: (OFComparator)comparator
		       options: (OFArraySortOptions)options;
#endif

/**
 * @brief Creates a new array with the specified object added.
 *
 * @param object The object to add
 * @return A new array with the specified object added
 */
- (OFArray OF_GENERIC(ObjectType) *)arrayByAddingObject: (ObjectType)object;

/**
 * @brief Creates a new array with the objects from the specified array added.
 *
 * @param array The array with objects to add
 * @return A new array with the objects from the specified array added
 */
- (OFArray OF_GENERIC(ObjectType) *)arrayByAddingObjectsFromArray:
    (OFArray OF_GENERIC(ObjectType) *)array;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Executes a block for each object.
 *
 * @param block The block to execute for each object
 */
- (void)enumerateObjectsUsingBlock: (OFArrayEnumerationBlock)block;

/**
 * @brief Creates a new array, mapping each object using the specified block.
 *
 * @param block A block which maps an object for each object
 * @return A new, autoreleased OFArray
 */
- (OFArray *)mappedArrayUsingBlock: (OFArrayMapBlock)block;

/**
 * @brief Creates a new array, only containing the objects for which the block
 *	  returns true.
 *
 * @param block A block which determines if the object should be in the new
 *		array
 * @return A new, autoreleased OFArray
 */
- (OFArray OF_GENERIC(ObjectType) *)filteredArrayUsingBlock:
    (OFArrayFilterBlock)block;

/**
 * @brief Folds the array to a single object using the specified block.
 *
 * If the array is empty, it will return `nil`.
 *
 * If there is only one object in the array, that object will be returned and
 * the block will not be invoked.
 *
 * If there are at least two objects, the block is invoked for each object
 * except the first, where left is always to what the array has already been
 * folded and right what should be added to left.
 *
 * @param block A block which folds two objects into one, which is called for
 *		all objects except the first
 * @return The array folded to a single object
 */
- (nullable id)foldUsingBlock: (OFArrayFoldBlock)block;
#endif
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableArray.h"

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for array literals to work */
@compatibility_alias NSArray OFArray;
#endif
