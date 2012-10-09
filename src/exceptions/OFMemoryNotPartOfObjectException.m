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

#include "config.h"

#import "OFMemoryNotPartOfObjectException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

@implementation OFMemoryNotPartOfObjectException
+ (instancetype)exceptionWithClass: (Class)class_
			   pointer: (void*)ptr
{
	return [[[self alloc] initWithClass: class_
				    pointer: ptr] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	pointer: (void*)ptr
{
	self = [super initWithClass: class_];

	pointer = ptr;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Memory at %p was not allocated as part of object of class %@, "
	    @"thus the memory allocation was not changed! It is also possible "
	    @"that there was an attempt to free the same memory twice.",
	    pointer, inClass];

	return description;
}

- (void*)pointer
{
	return pointer;
}
@end
