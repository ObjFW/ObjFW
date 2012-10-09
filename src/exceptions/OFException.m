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

#import "OFException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

@implementation OFException
+ (instancetype)exceptionWithClass: (Class)class_
{
	return [[[self alloc] initWithClass: class_] autorelease];
}

- init
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
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
