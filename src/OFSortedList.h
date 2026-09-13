/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFList.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFSortedList OFSortedList.h ObjFW/ObjFW.h
 *
 * @brief A class which provides easy to use sorted double-linked lists.
 *
 * @warning Because the list is sorted, all methods inserting an object at a
 *	    specific place are unavailable, even though they exist in OFList!
 */
@interface OFSortedList OF_GENERIC(ObjectType): OFList OF_GENERIC(ObjectType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
{
	OF_RESERVE_IVARS(OFSortedList, 4)
}

- (OFListItem)appendObject: (ObjectType)object OF_UNAVAILABLE;
- (OFListItem)prependObject: (ObjectType)object OF_UNAVAILABLE;
- (OFListItem)insertObject: (ObjectType)object
	    beforeListItem: (OFListItem)listItem OF_UNAVAILABLE;
- (OFListItem)insertObject: (ObjectType)object
	     afterListItem: (OFListItem)listItem OF_UNAVAILABLE;

/**
 * @brief Inserts the object to the list while keeping the list sorted.
 *
 * @param object The object to insert
 * @return The list object for the object just added
 */
- (OFListItem)insertObject: (ObjectType <OFComparing>)object;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
