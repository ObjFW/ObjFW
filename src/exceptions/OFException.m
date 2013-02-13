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

#import "OFException.h"
#import "OFString.h"

@implementation OFException
+ (instancetype)exceptionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- init
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
{
	self = [super init];

	_inClass = class;

	return self;
}

- (Class)inClass
{
	return _inClass;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"An exception of class %@ occurred in class %@!",
	    object_getClass(self), _inClass];
}
@end
