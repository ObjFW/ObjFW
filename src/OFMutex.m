/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
