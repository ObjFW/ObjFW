/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFSortedList.h"

#import "OFNotImplementedException.h"

@implementation OFSortedList
- (of_list_object_t*)appendObject: (id)object
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (of_list_object_t*)prependObject: (id)object
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (of_list_object_t*)insertObject: (id)object
		 beforeListObject: (of_list_object_t*)listObject
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (of_list_object_t*)insertObject: (id)object
		  afterListObject: (of_list_object_t*)listObject
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (of_list_object_t*)addObject: (id <OFComparing>)object
{
	of_list_object_t *iter;

	for (iter = lastListObject; iter != NULL; iter = iter->previous) {
		if ([object compare: iter->object] == OF_ORDERED_DESCENDING)
			return [super insertObject: object
				   afterListObject: iter];
	}

	return [super prependObject: object];
}
@end
