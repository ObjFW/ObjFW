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

#import "OFList.h"

@implementation OFList
- init
{
	if ((self = [super init])) {
		first = nil;
		last  = nil;
	}
	return self;
}

- free
{
	OFListObject *iter, *next;

	for (iter = first; iter != nil; iter = next) {
		next = [iter next];
		[iter free];
	}

	return [super free];
}

- freeIncludingData
{
	OFListObject *iter, *next;

	for (iter = first; iter != nil; iter = next) {
		next = [iter next];
		[iter freeIncludingData];
	}

	first = last = nil;
	return [super free];
}

- (OFListObject*)first
{
	return first;
}

- (OFListObject*)last
{
	return last;
}

- add: (OFListObject*)obj
{
	if (!first || !last) {
		first = last = obj;
		return self;
	}

	[obj setPrev: last];
	[last setNext: obj];

	last = obj;

	return self;
}

- addNew: (id)obj
{
	return [self add: [OFListObject newWithData: obj]];
}
@end
