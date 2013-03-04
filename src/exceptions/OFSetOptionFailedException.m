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

#import "OFSetOptionFailedException.h"
#import "OFString.h"
#import "OFStream.h"

#import "common.h"

@implementation OFSetOptionFailedException
+ (instancetype)exceptionWithClass: (Class)class
			    stream: (OFStream*)stream
{
	return [[[self alloc] initWithClass: class
				     stream: stream] autorelease];
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
	 stream: (OFStream*)stream
{
	self = [super initWithClass: class];

	_stream = [stream retain];

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Setting an option in class %@ failed!", _inClass];
}

- (OFStream*)stream
{
	OF_GETTER(_stream, false)
}
@end
