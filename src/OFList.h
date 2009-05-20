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

#import "OFObject.h"

typedef struct __of_list_object
{
	id			object;
	struct __of_list_object *next;
	struct __of_list_object *prev;
} of_list_object_t;

/**
 * The OFList class provides easy to use double-linked lists.
 */
@interface OFList: OFObject <OFCopying>
{
	of_list_object_t *first;
	of_list_object_t *last;
	BOOL		 retain_and_release;
}
/**
 * \return A new autoreleased OFList
 */
+ list;

/**
 * Initializes an already allocated OFList that does not retain/releas objects
 * added to it..
 *
 * \return An initialized OFList
 */
- initWithoutRetainAndRelease;

/**
 * \return The first object in the list
 */
- (of_list_object_t*)first;

/**
 * \return The last object in the list
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
- (of_list_object_t*)append: (id)obj;

/**
 * Prepends an object to the list.
 *
 * \param obj The object to prepend
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)prepend: (id)obj;

/**
 * Inserts an object before another object.
 * \param obj The object to insert
 * \param listobj The of_list_object_t of the object before which it should be
 *	  inserted
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insert: (id)obj
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
- (of_list_object_t*)insert: (id)obj
		      after: (of_list_object_t*)listobj;

/**
 * Removes an object from the list.
 *
 * \param listobj The list object returned by append / prepend
 */
- remove: (of_list_object_t*)listobj;

/**
 * Get the number of items in the list. Use with caution, as this means one
 * iteration through the whole list!
 *
 * \return The number of items in the list.
 */
- (size_t)count;
@end
