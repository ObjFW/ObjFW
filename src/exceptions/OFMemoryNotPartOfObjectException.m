/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include "config.h"

#include <stdlib.h>

#import "OFMemoryNotPartOfObjectException.h"
#import "OFString.h"

@implementation OFMemoryNotPartOfObjectException
+ (instancetype)exceptionWithClass: (Class)class
			   pointer: (void*)pointer
{
	return [[[self alloc] initWithClass: class
				    pointer: pointer] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
	pointer: (void*)pointer
{
	self = [super initWithClass: class];

	_pointer = pointer;

	return self;
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Memory at %p was not allocated as part of object of class %@, "
	    @"thus the memory allocation was not changed! It is also possible "
	    @"that there was an attempt to free the same memory twice.",
	    _pointer, _inClass];

	return _description;
}

- (void*)pointer
{
	return _pointer;
}
@end
