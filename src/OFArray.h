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

#import <stddef.h>

#import "OFObject.h"

@interface OFArray: OFObject
{
	void   *data;
	size_t itemsize;
	size_t size;
}

- initWithItemSize: (size_t)is;
- (size_t)size;
- (void*)item: (size_t)item;
- (void*)last;
- add: (void*)item;
- addNItems: (size_t)nitems
    fromCArray: (void*)carray;
- removeLastNItems: (size_t)nitems;
@end
