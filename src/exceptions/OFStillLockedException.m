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

#import "OFStillLockedException.h"
#import "OFString.h"

#import "macros.h"

@implementation OFStillLockedException
+ (instancetype)exceptionWithClass: (Class)class
			      lock: (id <OFLocking>)lock
{
	return [[[self alloc] initWithClass: class
				       lock: lock] autorelease];
}

- initWithClass: (Class)class
	   lock: (id <OFLocking>)lock
{
	self = [super initWithClass: class];

	_lock = [lock retain];

	return self;
}

- (void)dealloc
{
	[_lock release];

	[super dealloc];
}

- (OFString*)description
{
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Deallocation of a lock of type %@ was tried in class %@, even "
	    @"though it was still locked!", [_lock class], _inClass];

	return _description;
}

- (id <OFLocking>)lock
{
	OF_GETTER(_lock, NO)
}
@end
