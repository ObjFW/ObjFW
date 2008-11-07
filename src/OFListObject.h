/*
 * Copyright (c) 2008
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
 * The OFListObject class is a class for objects to be stored in an OFObject.
 */
@interface OFListObject: OFObject
{
	void	     *data;
	OFListObject *next;
	OFListObject *prev;
}

/**
 * \param The data the OFListObject should contain
 * \return A new OFListObject.
 */
+ newWithData: (void*)ptr;

/**
 * Initializes an already allocated OFListObjeect.
 *
 * \param The data the OFListObject should contain
 * \return An initialized OFListObject.
 */
- initWithData: (void*)ptr;

/**
 * Free the OFListObject and the data it contains.
 */
- freeIncludingData;

/**
 * \return The data included in the OFListObject
 */
- (void*)data;

/**
 * \return The next OFListObject in the OFList
 */
- (OFListObject*)next;

/**
 * \return The previous OFListObject in the OFList
 */
- (OFListObject*)prev;

/**
 * Sets the next OFListObject in the OFList.
 *
 * \param obj An OFListObject
 */
- setNext: (OFListObject*)obj;

/**
 * Sets the previous OFListObject in the OFList.
 *
 * \param obj An OFListObject
 */
- setPrev: (OFListObject*)obj;
@end
