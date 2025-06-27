/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFLockFailedException.h"
#import "OFString.h"

@implementation OFLockFailedException
@synthesize lock = _lock, errNo = _errNo;

+ (instancetype)exceptionWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	return objc_autoreleaseReturnValue([[self alloc] initWithLock: lock
								errNo: errNo]);
}

- (instancetype)initWithLock: (id <OFLocking>)lock errNo: (int)errNo
{
	self = [super init];

	_lock = objc_retain(lock);
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	objc_release(_lock);

	[super dealloc];
}

- (OFString *)description
{
	if (_lock != nil)
		return [OFString stringWithFormat:
		    @"A lock of type %@ could not be locked: %s",
		    [_lock class], strerror(_errNo)];
	else
		return @"A lock could not be locked!";
}
@end
