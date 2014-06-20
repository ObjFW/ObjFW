/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFThreadStillRunningException.h"
#import "OFString.h"
#import "OFThread.h"

@implementation OFThreadStillRunningException
+ (instancetype)exceptionWithThread: (OFThread*)thread
{
	return [[[self alloc] initWithThread: thread] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithThread: (OFThread*)thread
{
	self = [super init];

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
	    @"Deallocation of a thread of type %@ was tried, even though it "
	    @"was still running!", [_thread class]];
}

- (OFThread*)thread
{
	OF_GETTER(_thread, true)
}
@end
