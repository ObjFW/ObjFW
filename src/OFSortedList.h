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

#import "OFList.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSortedList OFSortedList.h ObjFW/OFSortedList.h
 *
 * @brief A class which provides easy to use sorted double-linked lists.
 *
 * @warning Because the list is sorted, all methods inserting an object at a
 *	    specific place are unavailable, even though they exist in OFList!
 */
#ifdef OF_HAVE_GENERICS
@interface OFSortedList <ObjectType>: OFList <ObjectType>
#else
# ifndef DOXYGEN
#  define ObjectType id
# endif
@interface OFSortedList: OFList
#endif
/*!
 * @brief Inserts the object to the list while keeping the list sorted.
 *
 * @param object The object to insert
 * @return The list object for the object just added
 */
- (of_list_object_t*)insertObject: (ObjectType <OFComparing>)object;
@end
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif

OF_ASSUME_NONNULL_END
