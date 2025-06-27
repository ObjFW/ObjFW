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

#import "OFObject.h"
#import "OFCollection.h"
#import "OFEnumerator.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

/*
 * Make clang's -Wdocumentation shut up about about using @struct on something
 * it thinks is not a struct. Doxygen requires it this way.
 */
#ifdef __clang__
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wdocumentation"
#endif
/**
 * @struct OFListItem OFList.h ObjFW/ObjFW.h
 *
 * @brief A list item.
 *
 * See @ref OFListItemNext, @ref OFListItemPrevious and @ref OFListItemObject.
 */
typedef struct _OFListItem *OFListItem;
#ifdef __clang__
# pragma clang diagnostic pop
#endif

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Returns the next list item of the list item.
 *
 * @param listItem The list item for which the next list item should be returned
 * @return The next list item of the list item
 */
extern OFListItem _Nullable OFListItemNext(OFListItem _Nonnull listItem);

/*!
 * @brief Returns the previous list item of the list item.
 *
 * @param listItem The list item for which the previous list item should be
 *		   returned
 * @return The previous list item of the list item
 */
extern OFListItem _Nullable OFListItemPrevious(OFListItem _Nonnull listItem);

/*!
 * @brief Returns the object of the list item.
 *
 * @warning The returned object is not retained and autoreleased - this is the
 *	    caller's responsibility!
 *
 * @param listItem The list item for which the object should be returned
 * @return The object of the list item
 */
extern id _Nonnull OFListItemObject(OFListItem _Nonnull listItem);
#ifdef __cplusplus
}
#endif

/**
 * @class OFList OFList.h ObjFW/ObjFW.h
 *
 * @brief A class which provides easy to use double-linked lists.
 */
@interface OFList OF_GENERIC(ObjectType): OFObject <OFCopying, OFCollection>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
{
	OFListItem _Nullable _firstListItem;
	OFListItem _Nullable _lastListItem;
	size_t _count;
	unsigned long _mutations;
	OF_RESERVE_IVARS(OFList, 4)
}

/**
 * @brief The first list object of the list.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFListItem firstListItem;

/**
 * @brief The first object of the list or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType firstObject;

/**
 * @brief The last list object of the list.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFListItem lastListItem;

/**
 * @brief The last object of the list or `nil`.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType lastObject;

/**
 * @brief Creates a new OFList.
 *
 * @return A new autoreleased OFList
 */
+ (instancetype)list;

/**
 * @brief Appends an object to the list.
 *
 * @param object The object to append
 * @return An OFListItem, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its OFListItem.
 */
- (OFListItem)appendObject: (ObjectType)object;

/**
 * @brief Prepends an object to the list.
 *
 * @param object The object to prepend
 * @return An OFListItem, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its OFListItem.
 */
- (OFListItem)prependObject: (ObjectType)object;

/**
 * @brief Inserts an object before another list object.
 *
 * @param object The object to insert
 * @param listItem The OFListItem of the object before which it should be
 *		   inserted
 * @return An OFListItem, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its OFListItem.
 */
- (OFListItem)insertObject: (ObjectType)object
	    beforeListItem: (OFListItem)listItem;

/**
 * @brief Inserts an object after another list object.
 *
 * @param object The object to insert
 * @param listItem The OFListItem of the object after which it should be
 *	  inserted
 * @return An OFListItem, needed to identify the object inside the list.
 *	   For example, if you want to remove an object from the list, you need
 *	   its OFListItem.
 */
- (OFListItem)insertObject: (ObjectType)object
	     afterListItem: (OFListItem)listItem;

/**
 * @brief Removes the object with the specified list object from the list.
 *
 * @param listItem The list object returned by append / prepend
 */
- (void)removeListItem: (OFListItem)listItem;

/**
 * @brief Checks whether the list contains an object equal to the specified
 *	  object.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/**
 * @brief Checks whether the list contains an object with the specified address.
 *
 * @param object The object which is checked for being in the list
 * @return A boolean whether the list contains an object with the specified
 *	   address
 */
- (bool)containsObjectIdenticalTo: (ObjectType)object;

/**
 * @brief Removes all objects from the list.
 */
- (void)removeAllObjects;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
