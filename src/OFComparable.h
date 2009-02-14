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

/**
 * The OFComparable protocol provides functions to compare two objects.
 */
@protocol OFComparable
/**
 * \param obj The object which is tested for equality
 * \return A boolean whether the object is equal to the other object
 */
- (BOOL)isEqual: (id)obj;

/**
 * Compares the object to another object.
 *
 * \param obj An object to compare with
 * \return An integer which is the result of the comparison, see for example
 *	   strcmp
 */
- (int)compare: (id)obj;
@end
