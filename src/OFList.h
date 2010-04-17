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

#import "OFObject.h"

/**
 * \brief A list object.
 *
 * A struct that contains a pointer to the next list object, the previous list
 * object and the object.
 */
typedef struct __of_list_object {
	/// A pointer to the next list object in the list
	struct __of_list_object *next;
	/// A pointer to the previous list object in the list
	struct __of_list_object *prev;
	/// The object for the list object
	id			object;
} of_list_object_t;

/**
 * \brief A class which provides easy to use double-linked lists.
 */
@interface OFList: OFObject <OFCopying>
{
	of_list_object_t *first;
	of_list_object_t *last;
	size_t		 count;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) of_list_object_t *first;
@property (readonly) of_list_object_t *last;
@property (readonly) size_t count;
#endif

/**
 * \return A new autoreleased OFList
 */
+ list;

/**
 * \return The first list object in the list
 */
- (of_list_object_t*)first;

/**
 * \return The last list object in the list
 */
- (of_list_object_t*)last;

/**
 * Appends an object to the list.
 *
 * \param obj The object to append
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)append: (OFObject*)obj;

/**
 * Prepends an object to the list.
 *
 * \param obj The object to prepend
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)prepend: (OFObject*)obj;

/**
 * Inserts an object before another object.
 * \param obj The object to insert
 * \param listobj The of_list_object_t of the object before which it should be
 *	  inserted
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insert: (OFObject*)obj
		     before: (of_list_object_t*)listobj;

/**
 * Inserts an object after another object.
 * \param obj The object to insert
 * \param listobj The of_list_object_t of the object after which it should be
 *	  inserted
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insert: (OFObject*)obj
		      after: (of_list_object_t*)listobj;

/**
 * Removes the object with the specified list object from the list.
 *
 * \param listobj The list object returned by append / prepend
 */
- (void)remove: (of_list_object_t*)listobj;

/**
 * \return The number of items in the list.
 */
- (size_t)count;
@end
