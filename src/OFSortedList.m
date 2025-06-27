/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OFSortedList.h"

@implementation OFSortedList
- (OFListItem)appendObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem)prependObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem)insertObject: (id)object beforeListItem: (OFListItem)listItem
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem)insertObject: (id)object afterListItem: (OFListItem)listItem
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFListItem)insertObject: (id <OFComparing>)object
{
	OFListItem iter;

	for (iter = _lastListItem; iter != NULL;
	    iter = OFListItemPrevious(iter)) {
		if ([object compare: OFListItemObject(iter)] !=
		    OFOrderedAscending)
			return [super insertObject: object afterListItem: iter];
	}

	return [super prependObject: object];
}
@end
