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

#import "config.h"

#import <stdlib.h>

#import "OFListObject.h"

@implementation OFListObject
+ newWithData: (void*)ptr
{
	return [[self alloc] initWithData: ptr];
}

- initWithData: (void*)ptr
{
	if ((self = [super init])) {
		next = nil;
		prev = nil;
		data = ptr;
	}
	return self;
}

- freeIncludingData
{
	if (data != NULL)
		free(data);
	return [super free];
}

- (void*)data
{
	return data;
}

- (OFListObject*)next
{
	return next;
}

- (OFListObject*)prev
{
	return prev;
}

- setNext: (OFListObject*)obj
{
	next = obj;
	return self;
}

- setPrev: (OFListObject*)obj
{
	prev = obj;
	return self;
}
@end
