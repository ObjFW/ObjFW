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

#include <errno.h>

#import "OFMutex.h"
#import "OFString.h"

#import "OFInitializationFailedException.h"
#import "OFLockFailedException.h"
#import "OFStillLockedException.h"
#import "OFUnlockFailedException.h"

@implementation OFMutex
@synthesize name = _name;

+ (instancetype)mutex
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	if (OFPlainMutexNew(&_mutex) != 0) {
		Class c = self.class;
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	_initialized = true;

	return self;
}

- (void)dealloc
{
	if (_initialized) {
		int error = OFPlainMutexFree(&_mutex);

		if (error != 0) {
			OFEnsure(error == EBUSY);

			@throw [OFStillLockedException exceptionWithLock: self];
		}
	}

	[_name release];

	[super dealloc];
}

- (void)lock
{
	int error = OFPlainMutexLock(&_mutex);

	if (error != 0)
		@throw [OFLockFailedException exceptionWithLock: self
							  errNo: error];
}

- (bool)tryLock
{
	int error = OFPlainMutexTryLock(&_mutex);

	if (error != 0) {
		if (error == EBUSY)
			return false;
		else
			@throw [OFLockFailedException exceptionWithLock: self
								  errNo: error];
	}

	return true;
}

- (void)unlock
{
	int error = OFPlainMutexUnlock(&_mutex);

	if (error != 0)
		@throw [OFUnlockFailedException exceptionWithLock: self
							    errNo: error];
}

- (OFString *)description
{
	if (_name == nil)
		return super.description;

	return [OFString stringWithFormat: @"<%@: %@>", self.className, _name];
}
@end
