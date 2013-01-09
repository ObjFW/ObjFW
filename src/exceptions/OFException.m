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
+ (instancetype)exceptionWithClass: (Class)class_
{
	return [[[self alloc] initWithClass: class_] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

- initWithClass: (Class)class_
{
	self = [super init];

	inClass = class_;

	return self;
}

- (void)dealloc
{
	[description release];

	[super dealloc];
}

- (Class)inClass
{
	return inClass;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"An exception of class %@ occurred in class %@!",
	    object_getClass(self), inClass];

	return description;
}
@end
