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
+ (instancetype)exceptionWithHash: (id <OFHash>)hash
{
	return [[[self alloc] initWithHash: hash] autorelease];
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

- initWithHash: (id <OFHash>)hashObject
{
	self = [super init];

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
	    @"The hash of type %@ has already been calculated and thus no new "
	    @"data can be added!", [_hashObject class]];
}

- (id <OFHash>)hashObject
{
	OF_GETTER(_hashObject, true)
}
@end
