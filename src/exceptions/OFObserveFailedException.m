/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFObserveFailedException.h"
#import "OFString.h"
#import "OFKernelEventObserver.h"

@implementation OFObserveFailedException
@synthesize observer = _observer, errNo = _errNo;

+ (instancetype)exceptionWithObserver: (OFKernelEventObserver *)observer
				errNo: (int)errNo
{
	return [[[self alloc] initWithObserver: observer
					 errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithObserver: (OFKernelEventObserver *)observer
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
	    [_observer className], of_strerror(_errNo)];
}
@end
