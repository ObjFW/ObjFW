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
#import "OFList.h"

#import "threading.h"

/* Haiku used to define this for some unknown reason which causes trouble */
#ifdef protected
# undef protected
#endif

/*!
 * @brief A class for Thread Local Storage keys.
 */
@interface OFTLSKey: OFObject
{
@public
	of_tlskey_t _key;
@protected
	void (*_destructor)(id);
	of_list_object_t *_listObject;
	BOOL _initialized;
}

/*!
 * @brief Creates a new Thread Local Storage key
 *
 * @return A new, autoreleased Thread Local Storage key
 */
+ (instancetype)TLSKey;

/*!
 * @brief Creates a new Thread Local Storage key with the specified destructor.
 *
 * @param destructor A destructor that is called when the thread is terminated
 * @return A new autoreleased Thread Local Storage key
 */
+ (instancetype)TLSKeyWithDestructor: (void(*)(id))destructor;

+ (void)OF_callAllDestructors;

/*!
 * @brief Initializes an already allocated Thread Local Storage Key with the
 *	  specified destructor.
 *
 * @param destructor A destructor that is called when the thread is terminated
 * @return An initialized Thread Local Storage key
 */
- initWithDestructor: (void(*)(id))destructor;
@end
