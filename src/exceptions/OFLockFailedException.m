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

#import "OFLockFailedException.h"
#import "OFString.h"

@implementation OFLockFailedException
@synthesize lock = _lock;

+ (instancetype)exceptionWithLock: (id <OFLocking>)lock
{
	return [[[self alloc] initWithLock: lock] autorelease];
}

- initWithLock: (id <OFLocking>)lock
{
	self = [super init];

	_lock = [lock retain];

	return self;
}

- (void)dealloc
{
	[_lock release];

	[super dealloc];
}

- (OFString *)description
{
	if (_lock != nil)
		return [OFString stringWithFormat:
		    @"A lock of type %@ could not be locked!", [_lock class]];
	else
		return @"A lock could not be locked!";
}
@end
