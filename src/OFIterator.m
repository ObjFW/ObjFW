/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFIterator.h"
#import "OFDictionary.h"
#import "OFExceptions.h"

/* Reference for static linking */
int _OFIterator_reference;

@implementation OFIterator
- initWithData: (OFList**)data_
       andSize: (size_t)size_
{
	self = [super init];

	data = data_;
	size = size_;

	last = NULL;

	return self;
}

- (id)nextObject
{
	if (last == NULL) {
		for (; pos < size && data[pos] == nil; pos++);
		if (pos == size)
			return nil;

		return (last = [data[pos++] first])->object;
	}

	if ((last = last->next) != NULL)
		return last->object;

	return [self nextObject];
}

- reset
{
	pos = 0;
	last = NULL;

	return self;
}
@end

@implementation OFDictionary (OFIterator)
- (OFIterator*)iterator
{
	return [[[OFIterator alloc] initWithData: data
					 andSize: size] autorelease];
}
@end
