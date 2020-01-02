/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFThreadStartFailedException.h"
#import "OFString.h"
#import "OFThread.h"

@implementation OFThreadStartFailedException
@synthesize thread = _thread, errNo = _errNo;

+ (instancetype)exceptionWithThread: (OFThread *)thread
			      errNo: (int)errNo
{
	return [[[self alloc] initWithThread: thread
				       errNo: errNo] autorelease];
}

- (instancetype)initWithThread: (OFThread *)thread
			 errNo: (int)errNo
{
	self = [super init];

	_thread = [thread retain];
	_errNo = errNo;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_thread release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Starting a thread of type %@ failed: %s",
	    _thread.class, strerror(_errNo)];
}
@end
