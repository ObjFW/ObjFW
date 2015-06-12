/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
#import "OFCollection.h"
#import "OFEnumerator.h"
#import "OFSerialization.h"

typedef struct of_list_object_t of_list_object_t;
/*!
 * @struct of_list_object_t OFList.h ObjFW/OFList.h
 *
 * @brief A list object.
 *
 * A struct that contains a pointer to the next list object, the previous list
 * object and the object.
 */
struct of_list_object_t {
	/// A pointer to the next list object in the list
	of_list_object_t *next;
	/// A pointer to the previous list object in the list
	of_list_object_t *previous;
	/// The object for the list object
	__unsafe_unretained id object;
};

/*!
 * @class OFList OFList.h ObjFW/OFList.h
 *
 * @brief A class which provides easy to use double-linked lists.
 */
#ifdef OF_HAVE_GENERICS
@interface OFList <ObjectType>:
#else
# ifndef DOXYGEN
#  define ObjectType id
# endif
@interface OFList:
#endif
    OFObject <OFCopying, OFCollection, OFSerialization>
{
	of_list_object_t *_firstListObject;
	of_list_object_t *_lastListObject;
	size_t		 _count;
	unsigned long	 _mutations;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) of_list_object_t *firstListObject;
@property (readonly) of_list_object_t *lastListObject;
#endif

/*!
 * @brief Creates a new OFList.
 *
 * @return A new autoreleased OFList
 */
+ (instancetype)list;

/*!
 * @brief Returns the first list object of the list.
 *
 * @return The first list object of the list
 */
- (of_list_object_t*)firstListObject;

/*!
 * @brief Returns the last list object of the list.
 *
 * @return The last list object of the list
 */
- (of_list_object_t*)lastListObject;

/*!
 * @brief Appends an object to the list.
 *
 * @param object The object to append
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)appendObject: (ObjectType)object;

/*!
 * @brief Prepends an object to the list.
 *
 * @param object The object to prepend
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)prependObject: (ObjectType)object;

/*!
 * @brief Inserts an object before another list object.
 *
 * @param object The object to insert
 * @param listObject The of_list_object_t of the object before which it should
 *	  be inserted
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insertObject: (ObjectType)object
		 beforeListObject: (of_list_object_t*)listObject;

/*!
 * @brief Inserts an object after another list object.
 *
 * @param object The object to insert
 * @param listObject The of_list_object_t of the object after which it should be
 *	  inserted
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insertObject: (ObjectType)object
		  afterListObject: (of_list_object_t*)listObject;

/*!
 * @brief Removes the object with the specified list object from the list.
 *
 * @param listObject The list object returned by append / prepend
 */
- (void)removeListObject: (of_list_object_t*)listObject;

/*!
 * @brief Checks whether the list contains an object equal to the specified
 *	  object.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/*!
 * @brief Checks whether the list contains an object with the specified address.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains an object with the specified
 *	   address
 */
- (bool)containsObjectIdenticalTo: (ObjectType)object;

/*!
 * @brief Returns an OFEnumerator to enumerate through all objects of the list.
 *
 * @returns An OFEnumerator to enumerate through all objects of the list
 */
- (OFEnumerator OF_GENERIC(ObjectType)*)objectEnumerator;

/*!
 * @brief Returns the first object of the list or nil.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 *
 * @return The first object of the list or nil
 */
- (ObjectType)firstObject;

/*!
 * @brief Returns the last object of the list or nil.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 *
 * @return The last object of the list or nil
 */
- (ObjectType)lastObject;

/*!
 * @brief Removes all objects from the list.
 */
- (void)removeAllObjects;
@end
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif

@interface OFListEnumerator: OFEnumerator
{
	OFList		 *_list;
	of_list_object_t *_current;
	unsigned long	 _mutations;
	unsigned long	 *_mutationsPtr;
}

-     initWithList: (OFList*)list
  mutationsPointer: (unsigned long*)mutationsPtr;
@end
