/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFUnlockFailedException.h"
#import "OFString.h"

@implementation OFUnlockFailedException
@synthesize lock = _lock, errNo = _errNo;

+ (instancetype)exceptionWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	return [[[self alloc] initWithLock: lock errNo: errNo] autorelease];
}

- (instancetype)initWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	self = [super init];

	_lock = [lock retain];
	_errNo = errNo;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_lock release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"A lock of type %@ could not be unlocked: %s",
	    [_lock class], strerror(_errNo)];
}
@end
