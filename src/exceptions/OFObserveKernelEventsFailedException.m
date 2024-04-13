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

#import "OFObserveKernelEventsFailedException.h"
#import "OFString.h"
#import "OFKernelEventObserver.h"

@implementation OFObserveKernelEventsFailedException
@synthesize observer = _observer, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithObserver: (OFKernelEventObserver *)observer
				errNo: (int)errNo
{
	return [[[self alloc] initWithObserver: observer
					 errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObserver: (OFKernelEventObserver *)observer
			   errNo: (int)errNo
{
	self = [super init];

	@try {
		_observer = [observer retain];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_observer release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"An observer of class %@ failed to observe: %@",
	    _observer.class, OFStrError(_errNo)];
}
@end
