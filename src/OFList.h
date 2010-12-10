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
#import "OFCollection.h"
#import "OFEnumerator.h"

typedef struct of_list_object_t of_list_object_t;
/**
 * \brief A list object.
 *
 * A struct that contains a pointer to the next list object, the previous list
 * object and the object.
 */
struct of_list_object_t {
	/// A pointer to the next list object in the list
	of_list_object_t *next;
	/// A pointer to the previous list object in the list
	of_list_object_t *prev;
	/// The object for the list object
	id		 object;
};

/**
 * \brief A class which provides easy to use double-linked lists.
 */
@interface OFList: OFObject <OFCopying, OFCollection, OFFastEnumeration>
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

/**
 * \return A new autoreleased OFList
 */
+ list;

/**
 * \return The first list object in the list
 */
- (of_list_object_t*)firstListObject;

/**
 * \return The last list object in the list
 */
- (of_list_object_t*)lastListObject;

/**
 * Appends an object to the list.
 *
 * \param obj The object to append
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)appendObject: (id)obj;

/**
 * Prepends an object to the list.
 *
 * \param obj The object to prepend
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)prependObject: (id)obj;

/**
 * Inserts an object before another object.
 * \param obj The object to insert
 * \param listobj The of_list_object_t of the object before which it should be
 *	  inserted
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insertObject: (id)obj
		 beforeListObject: (of_list_object_t*)listobj;

/**
 * Inserts an object after another object.
 * \param obj The object to insert
 * \param listobj The of_list_object_t of the object after which it should be
 *	  inserted
 * \return An of_list_object_t, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its of_list_object_t.
 */
- (of_list_object_t*)insertObject: (id)obj
		  afterListObject: (of_list_object_t*)listobj;

/**
 * Removes the object with the specified list object from the list.
 *
 * \param listobj The list object returned by append / prepend
 */
- (void)removeListObject: (of_list_object_t*)listobj;
@end

@interface OFListEnumerator: OFEnumerator
{
	of_list_object_t *first;
	of_list_object_t *current;
	unsigned long	 mutations;
	unsigned long	 *mutationsPtr;
}

- initWithFirstListObject: (of_list_object_t*)first
	 mutationsPointer: (unsigned long*)mutations_ptr;
@end
