/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
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
- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithData: (struct of_dictionary_bucket*)data_
	  size: (size_t)size_
{
	size_t i;

	self = [super init];

	size = size_;
	data = [self allocMemoryForNItems: size
				 withSize: sizeof(struct of_dictionary_bucket)];

	for (i = 0; i < size; i++) {
		if (data_[i].key != nil) {
			data[i].key = [data_[i].key copy];
			data[i].object = [data_[i].object retain];
		} else
			data[i].key = nil;
	}

	return self;
}

- (void)dealloc
{
	size_t i;

	for (i = 0; i < size; i++) {
		if (data[i].key != nil) {
			[data[i].key release];
			[data[i].object release];
		}
	}

	[super dealloc];
}

- (of_iterator_pair_t)nextKeyObjectPair
{
	of_iterator_pair_t next;

	for (; pos < size && data[pos].key == nil; pos++);

	if (pos < size) {
		next.key = data[pos].key;
		next.object = data[pos].object;
		pos++;
	} else {
		next.key = nil;
		next.object = nil;
	}

	return next;
}

- reset
{
	pos = 0;

	return self;
}
@end

@implementation OFDictionary (OFIterator)
- (OFIterator*)iterator
{
	return [[[OFIterator alloc] initWithData: data
					    size: size] autorelease];
}
@end
