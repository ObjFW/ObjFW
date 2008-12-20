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
#import "OFListObject.h"

/**
 * The OFList class provides easy to use double-linked lists.
 */
@interface OFList: OFObject
{
	OFListObject *first;
	OFListObject *last;
}

- init;

/**
 * Frees the OFList and all OFListObjects, but not the data they contian.
 */
- free;

/**
 * Frees the list and the data included in all OFListObjects it contains.
 */
- freeIncludingData;

/**
 * \returns The first OFListObject in the OFList
 */
- (OFListObject*)first;

/**
 * \returns The last OFListObject in the OFList
 */
- (OFListObject*)last;

/**
 * Adds a new OFListObject to the OFList.
 *
 * \param obj An OFListObject
 */
- add: (OFListObject*)obj;

/**
 * Creates a new OFListObject and adds it to the OFList.
 *
 * \param obj A data object for the OFListObject which will be added
 */
- addNew: (id)obj;
@end
