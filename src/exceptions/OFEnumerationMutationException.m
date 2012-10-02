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

#import "OFEnumerationMutationException.h"
#import "OFString.h"

#import "OFNotImplementedException.h"

@implementation OFEnumerationMutationException
+ exceptionWithClass: (Class)class_
	      object: (id)object
{
	return [[[self alloc] initWithClass: class_
				     object: object] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	 object: (id)object_
{
	self = [super initWithClass: class_];

	object = [object_ retain];

	return self;
}

- (void)dealloc
{
	[object release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Object of class %@ was mutated during enumeration!", inClass];

	return description;
}

- (id)object
{
	OF_GETTER(object, NO)
}
@end
