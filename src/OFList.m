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

- (void)add: (OFListObject*)ptr
{
	if (!first || !last) {
		first = last = ptr;
		return;
	}

	[ptr setPrev: last];
	[last setNext: ptr];

	last = ptr;
}

- (void)addNew: (void*)ptr
{
	return [self add: [OFListObject newWithData: ptr]];
}
@end
