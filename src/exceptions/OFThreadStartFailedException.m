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

#import "OFThreadStartFailedException.h"
#import "OFString.h"
#import "OFThread.h"

#import "OFNotImplementedException.h"

@implementation OFThreadStartFailedException
+ (instancetype)exceptionWithClass: (Class)class_
			    thread: (OFThread*)thread
{
	return [[[self alloc] initWithClass: class_
				     thread: thread] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
	 thread: (OFThread*)thread_
{
	self = [super initWithClass: class_];

	thread = [thread_ retain];

	return self;
}

- (void)dealloc
{
	[thread release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Starting a thread of class %@ failed!", inClass];

	return description;
}

- (OFThread*)thread
{
	OF_GETTER(thread, NO)
}
@end
