/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OFSortedList.h"

@implementation OFSortedList
- (OFListItem *)appendObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem *)prependObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem *)insertObject: (id)object
	      beforeListItem: (OFListItem *)listItem
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem *)insertObject: (id)object
	       afterListItem: (OFListItem *)listItem
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem *)insertObject: (id <OFComparing>)object
{
	OFListItem *iter;

	for (iter = _lastListItem; iter != NULL; iter = iter->previous) {
		if ([object compare: iter->object] != OFOrderedAscending)
			return [super insertObject: object afterListItem: iter];
	}

	return [super prependObject: object];
}
@end
