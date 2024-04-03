/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFThreadStillRunningException.h"
#import "OFString.h"
#import "OFThread.h"

@implementation OFThreadStillRunningException
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
	if (_thread)
		return [OFString stringWithFormat:
		    @"Deallocation of a thread of type %@ was tried, even "
		    @"though it was still running!",
		    _thread.class];
	else
		return @"Deallocation of a thread was tried, even though it "
		    @"was still running!";
}
@end
