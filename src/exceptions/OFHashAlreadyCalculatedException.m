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

#import "OFHashAlreadyCalculatedException.h"
#import "OFString.h"

#import "common.h"

@implementation OFHashAlreadyCalculatedException
+ (instancetype)exceptionWithClass: (Class)class
			      hash: (id <OFHash>)hash
{
	return [[[self alloc] initWithClass: class
				       hash: hash] autorelease];
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
	   hash: (id <OFHash>)hashObject
{
	self = [super initWithClass: class];

	_hashObject = [hashObject retain];

	return self;
}

- (void)dealloc
{
	[_hashObject release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"The hash has already been calculated in class %@ and thus no new "
	    @"data can be added", _inClass];
}

- (id <OFHash>)hashObject
{
	OF_GETTER(_hashObject, NO)
}
@end
