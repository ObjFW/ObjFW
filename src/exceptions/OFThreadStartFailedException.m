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

#import "OFThreadStartFailedException.h"
#import "OFString.h"
#import "OFThread.h"

@implementation OFThreadStartFailedException
+ (instancetype)exceptionWithClass: (Class)class
			    thread: (OFThread*)thread
{
	return [[[self alloc] initWithClass: class
				     thread: thread] autorelease];
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
	 thread: (OFThread*)thread
{
	self = [super initWithClass: class];

	_thread = [thread retain];

	return self;
}

- (void)dealloc
{
	[_thread release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Starting a thread of class %@ failed!", _inClass];
}

- (OFThread*)thread
{
	OF_GETTER(_thread, NO)
}
@end
