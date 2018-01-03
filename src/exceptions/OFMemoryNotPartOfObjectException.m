/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

@implementation OFMemoryNotPartOfObjectException
@synthesize pointer = _pointer, object = _object;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPointer: (void *)pointer
			      object: (id)object
{
	return [[[self alloc] initWithPointer: pointer
				       object: object] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPointer: (void *)pointer
			 object: (id)object
{
	self = [super init];

	_pointer = pointer;
	_object = [object retain];

	return self;
}

- (void)dealloc
{
	[_object release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Deallocation or reallocation of memory not allocated as part of "
	    @"object of type %@ was attempted! It is also possible that there "
	    @"was an attempt to free the same memory twice.",
	    [_object class]];
}
@end
