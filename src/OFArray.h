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
	char   *data;
	size_t itemsize;
	size_t items;
}

+ newWithItemSize: (size_t)is;
- initWithItemSize: (size_t)is;
- (size_t)items;
- (void*)data;
- (void*)item: (size_t)item;
- (void*)last;
- add: (void*)item;
- addNItems: (size_t)nitems
 fromCArray: (void*)carray;
- removeNItems: (size_t)nitems;
@end

@interface OFBigArray: OFArray
{
	size_t size;
}

- initWithSize: (size_t)is;
- addNItems: (size_t)nitems
 fromCArray: (void*)carray;
- removeNItems: (size_t)nitems;
@end
