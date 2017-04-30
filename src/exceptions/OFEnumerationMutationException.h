/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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
 * @class OFEnumerationMutationException \
 *	  OFEnumerationMutationException.h \
 *	  ObjFW/OFEnumerationMutationException.h
 *
 * @brief An exception indicating that a mutation was detected during
 *        enumeration.
 */
@interface OFEnumerationMutationException: OFException
{
	id _object;
}

/*!
 * The object which was mutated during enumeration.
 */
@property (readonly, nonatomic) id object;

/*!
 * @brief Creates a new, autoreleased enumeration mutation exception.
 *
 * @param object The object which was mutated during enumeration
 * @return A new, autoreleased enumeration mutation exception
 */
+ (instancetype)exceptionWithObject: (id)object;

/*!
 * @brief Initializes an already allocated enumeration mutation exception.
 *
 * @param object The object which was mutated during enumeration
 * @return An initialized enumeration mutation exception
 */
- initWithObject: (id)object;
@end
