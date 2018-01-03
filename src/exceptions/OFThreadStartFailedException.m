/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

@implementation OFThreadStartFailedException
@synthesize thread = _thread;

+ (instancetype)exceptionWithThread: (OFThread *)thread
{
	return [[[self alloc] initWithThread: thread] autorelease];
}

- (instancetype)init
{
	return [self initWithThread: nil];
}

- (instancetype)initWithThread: (OFThread *)thread
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

- (OFString *)description
{
	if (_thread != nil)
		return [OFString stringWithFormat:
		    @"Starting a thread of type %@ failed!", [_thread class]];
	else
		return @"Starting a thread failed!";
}
@end
