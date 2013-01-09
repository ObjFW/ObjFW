/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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
 * @brief A class which provides easy to use double-linked lists.
 */
@interface OFList: OFObject <OFCopying, OFCollection, OFSerialization>
{
	of_list_object_t *firstListObject;
	of_list_object_t *lastListObject;
	size_t		 count;
	unsigned long	 mutations;
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
 * @brief Retrusn the last list object of the list.
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
- (of_list_object_t*)appendObject: (id)object;

/*!
 * @brief Prepends an object to the list.
 *
 * @param object The object to prepend
 * @return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)prependObject: (id)object;

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
- (of_list_object_t*)insertObject: (id)object
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
- (of_list_object_t*)insertObject: (id)object
		  afterListObject: (of_list_object_t*)listObject;

/*!
 * @brief Removes the object with the specified list object from the list.
 *
 * @param listObject The list object returned by append / prepend
 */
- (void)removeListObject: (of_list_object_t*)listObject;

/*!
 * @brief Checks whether the list contains an object with the specified address.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains an object with the specified
 *	   address.
 */
- (BOOL)containsObjectIdenticalTo: (id)object;

/*!
 * @brief Returns the first object of the list or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * @return The first object of the list or nil
 */
- (id)firstObject;

/*!
 * @brief Returns the last object of the list or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * @return The last object of the list or nil
 */
- (id)lastObject;

/*!
 * @brief Removes all objects from the list.
 */
- (void)removeAllObjects;
@end

@interface OFListEnumerator: OFEnumerator
{
	OFList		 *list;
	of_list_object_t *current;
	unsigned long	 mutations;
	unsigned long	 *mutationsPtr;
}

-     initWithList: (OFList*)list
  mutationsPointer: (unsigned long*)mutationsPtr;
@end
