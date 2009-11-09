/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFArray.h"

/**
 * The OFMutableArray class provides a class for storing, adding and removing
 * objects in an array.
 */
@interface OFMutableArray: OFArray {}
/**
 * Adds an object to the OFDataArray.
 *
 * \param obj An object to add
 */
- addObject: (OFObject*)obj;

/**
 * Removes the specified amount of objects from the end of the OFDataArray.
 *
 * \param nobjects The number of objects to remove
 */
- removeNObjects: (size_t)nobjects;
@end
