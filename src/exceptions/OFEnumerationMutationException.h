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

#import "OFException.h"

/*!
 * @brief An exception indicating that a mutation was detected during
 *        enumeration.
 */
@interface OFEnumerationMutationException: OFException
{
	id object;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) id object;
#endif

/*!
 * @brief Creates a new, autoreleased enumeration mutation exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param object The object which was mutated during enumeration
 * @return A new, autoreleased enumeration mutation exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    object: (id)object;

/*!
 * @brief Initializes an already allocated enumeration mutation exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param object The object which was mutated during enumeration
 * @return An initialized enumeration mutation exception
 */
- initWithClass: (Class)class_
	 object: (id)object;

/*!
 * @brief Returns the object which was mutated during enumeration.
 *
 * @return The object which was mutated during enumeration
 */
- (id)object;
@end
