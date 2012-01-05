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

#import "OFHashAlreadyCalculatedException.h"
#import "OFString.h"
#import "OFHash.h"

#import "OFNotImplementedException.h"

@implementation OFHashAlreadyCalculatedException
+ exceptionWithClass: (Class)class_
		hash: (OFHash*)hash
{
	return [[[self alloc] initWithClass: class_
				       hash: hash] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	   hash: (OFHash*)hash
{
	self = [super initWithClass: class_];

	hashObject = [hash retain];

	return self;
}

- (void)dealloc
{
	[hashObject release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The hash has already been calculated in class %@ and thus no new "
	    @"data can be added", inClass];

	return description;
}

- (OFHash*)hashObject
{
	return hashObject;
}
@end
