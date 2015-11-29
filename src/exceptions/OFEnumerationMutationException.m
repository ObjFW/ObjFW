/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFEnumerationMutationException.h"
#import "OFString.h"

@implementation OFEnumerationMutationException
@synthesize object = _object;

+ (instancetype)exceptionWithObject: (id)object
{
	return [[[self alloc] initWithObject: object] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithObject: (id)object
{
	self = [super init];

	_object = [object retain];

	return self;
}

- (void)dealloc
{
	[_object release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Object of class %@ was mutated during enumeration!",
	    [_object class]];
}
@end
